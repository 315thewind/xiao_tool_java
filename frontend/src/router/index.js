import { createRouter, createWebHashHistory } from 'vue-router'

// Layout 用动态 import，避免与 layout 模块形成循环依赖
const Layout = () => import('@/layout/index.vue')

// 静态路由：登录页、404、首页
export const constantRoutes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/login/index.vue'),
    hidden: true,
    meta: { title: '登录' }
  },
  {
    path: '/404',
    name: 'NotFound',
    component: () => import('@/views/error/404.vue'),
    hidden: true,
    meta: { title: '404' }
  }
]

// 含布局的静态路由（首页等）
export const layoutRoutes = [
  {
    path: '/',
    component: Layout,
    redirect: '/dashboard',
    children: [
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: () => import('@/views/dashboard/index.vue'),
        meta: { title: '首页', icon: 'HomeFilled', affix: true }
      }
    ]
  },
  {
    path: '/profile',
    component: Layout,
    hidden: true,
    children: [
      {
        path: '',
        name: 'Profile',
        component: () => import('@/views/profile/index.vue'),
        meta: { title: '个人中心' }
      }
    ]
  }
]

const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    ...constantRoutes,
    ...layoutRoutes
  ],
  scrollBehavior: () => ({ left: 0, top: 0 })
})

// 全局前置守卫：动态路由生成 + 鉴权
const WHITELIST = ['/login', '/404']
const registeredRouteNames = new Set()

router.beforeEach(async (to, from, next) => {
  document.title = (to.meta && to.meta.title ? to.meta.title + ' - ' : '') + '小肖的自用工具'

  const hasToken = !!localStorage.getItem('org_sys_token')

  if (!hasToken) {
    if (WHITELIST.includes(to.path)) {
      next()
    } else {
      next(`/login?redirect=${encodeURIComponent(to.fullPath)}`)
    }
    return
  }

  if (to.path === '/login') {
    next({ path: '/' })
    return
  }

  // 检查是否已有动态路由
  if (registeredRouteNames.size > 0) {
    next()
    return
  }

  // 首次进入：拉取用户信息并生成动态路由
  try {
    const { useUserStore } = await import('@/store/user')
    const { usePermissionStore } = await import('@/store/permission')
    const userStore = useUserStore()
    const permissionStore = usePermissionStore()

    if (!userStore.userInfo || !userStore.userInfo.id) {
      await userStore.fetchUserInfo()
    }

    const menus = userStore.menus && userStore.menus.length ? userStore.menus : []
    const accessRoutes = permissionStore.generateRoutes(menus)

    // 路由已在 permission store 中完成 Layout 包裹，直接注册
    accessRoutes.forEach((route) => {
      if (!route.component) {
        route.component = Layout
      }
      if (!route.name) {
        route.name = `AutoGen-${Math.random().toString(36).slice(2, 9)}`
      }
      router.addRoute(route)
      registeredRouteNames.add(route.name)
    })

    // 添加兜底路由（仅注册一次，用 name 防止重复 addRoute）
    if (!router.hasRoute('CatchAll404')) {
      router.addRoute({ name: 'CatchAll404', path: '/:pathMatch(.*)*', redirect: '/404', hidden: true })
    }

    // 重新导航：必须传“干净的 location”，不能把 to 展开后传入。
    // 原因：to 是已带 matched 数组的 RouteLocationNormalized；
    // 若把 matched 一起交给 next()，Vue Router 4 会认为该 location 已解析，
    // 直接沿用（此时为空的）matched → 命中 catch-all → 刷新即 404。
    // 这正是「能打开、一刷新就 404」的根因。
    next({ path: to.path, query: to.query, hash: to.hash, replace: true })
  } catch (e) {
    console.error('生成动态路由失败:', e)
    const { useUserStore } = await import('@/store/user')
    const { usePermissionStore } = await import('@/store/permission')
    useUserStore().resetState()
    usePermissionStore().resetRoutes()
    resetRouterSync()
    next(`/login?redirect=${encodeURIComponent(to.fullPath)}`)
  }
})

// 同步重置动态路由
function resetRouterSync() {
  registeredRouteNames.forEach((name) => {
    router.removeRoute(name)
  })
  registeredRouteNames.clear()
}

// 重置动态路由（退出登录时调用，Vue Router 4 兼容）
export function resetRouter() {
  resetRouterSync()
}

export default router
