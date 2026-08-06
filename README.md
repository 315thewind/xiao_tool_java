# 组织权限管理与个人工具系统

## 项目简介

这是一个前后端分离项目，基于 `Java + Vue` 技术栈构建：

- `backend-java`：Spring Boot 3 后端，负责系统管理、记账、统计、待办、备忘录、数据库查询、导入导出等能力
- `frontend`：Vue 3 + Vite + Element Plus 前端
- `sql`：PostgreSQL / MySQL / SQLite 初始化脚本
- `nginx`：反向代理示例配置

## 当前技术栈

| 层级 | 技术 | 默认端口 |
| --- | --- | --- |
| 前端 | Vue 3、Vite、Pinia、Vue Router、Element Plus | `2221` |
| 后端 | Spring Boot 3、Spring Security、MyBatis-Plus | `2222` |
| 数据库 | PostgreSQL（默认）、MySQL、SQLite | `5432` / 自定义 |

## 主要功能

### 系统管理

- 登录、退出、当前用户信息
- 组织管理
- 用户管理
- 岗位管理
- 角色管理
- 菜单管理
- 数据权限管理
- 数据字典管理
  - 字典类型管理（增删改查）
  - 字典数据管理（增删改查）
  - Excel 导入导出
  - 模板下载

### 日常工具

- 记账管理
  - 分页查询、新增、编辑、删除、清空
  - Excel / CSV 导入
  - Excel 导出
  - 导入模板下载
- 统计报表
- 待办事项
  - 分页查询、新增、编辑、删除
  - 完成状态切换
  - Excel 导入导出
- 备忘录
  - 列表查询、新增、编辑、删除
  - 标签与类型管理
  - Excel 导入导出
- 数据库查询
  - 连接配置管理（支持 PostgreSQL、MySQL、SQLite）
  - 测试连接
  - 查表列表
  - 查表结构
  - 预览表数据
  - 执行 SQL

## 目录结构

```text
my_project/
├─ backend-java/
│  ├─ src/main/java/com/xiao/sys/
│  │  ├─ config/          # 配置类（含菜单初始化器）
│  │  ├─ controller/      # 控制器
│  │  ├─ dto/            # 数据传输对象
│  │  ├─ entity/         # 实体类
│  │  ├─ mapper/         # 数据访问层
│  │  ├─ security/       # 安全认证
│  │  └─ service/        # 业务逻辑层
│  └─ src/main/resources/
│     ├─ db/migration/    # 数据库迁移脚本
│     └─ application.yml  # 应用配置
├─ frontend/
│  ├─ src/
│  │  ├─ api/            # API 接口
│  │  ├─ views/          # 页面组件
│  │  ├─ store/          # Pinia 状态管理
│  │  └─ router/         # 路由配置
│  └─ vite.config.js      # Vite 配置
├─ sql/                   # 数据库初始化脚本
├─ nginx/                 # 反向代理配置
├─ start.bat             # Windows 一键启动脚本
└─ README.md
```

## 快速启动

### 方式一：一键启动（推荐）

Windows系统直接双击 `start.bat` 文件即可自动启动前后端。

或者在命令行执行：

```bash
# 在项目根目录执行
start.bat
```

启动后会自动打开两个命令行窗口，分别启动：
- 后端服务（端口 2222）
- 前端服务（端口 2221）

浏览器会自动打开前端页面 `http://localhost:2221`

### 方式二：手动启动

#### 1. 准备数据库

默认使用 PostgreSQL，数据库名为 `org_sys`。

```sql
CREATE DATABASE org_sys WITH ENCODING 'UTF8';
```

执行初始化脚本：

```bash
psql -d org_sys -U postgres -f sql/init_postgres.sql
```

如果你的数据库是旧版本结构，建议再补执行一次字段修复脚本：

```bash
psql -d org_sys -U postgres -f backend-java/src/main/resources/db/migration/V2__add_dict_and_fields.sql
```

#### 2. 检查后端配置

配置文件：`backend-java/src/main/resources/application.yml`

当前默认值：

- 端口：`2222`
- 数据库：`jdbc:postgresql://127.0.0.1:5432/org_sys`
- 用户名：`postgres`
- 密码：`123456`

#### 3. 菜单自动初始化

项目内置 `MenuInitializer` 菜单初始化器，启动时会自动：

- 检查并创建「数据字典」菜单（系统管理下，排序第6）
- 检查并创建「数据库查询」菜单（日常工具下，排序第3）
- 自动清理重复菜单
- 自动为超级管理员分配菜单权限

无需手动插入菜单数据，启动后端即可自动完成。

#### 4. 启动后端

```bash
cd backend-java
mvnw.cmd spring-boot:run
```

如果你本机没有 Maven 全局命令，直接使用 `mvnw.cmd` 即可。
首次运行如果缺少依赖，会自动下载。

#### 5. 启动前端

```bash
cd frontend
npm install
npm run dev
```

默认访问地址：

- 前端：[http://localhost:2221](http://localhost:2221)
- 后端：[http://localhost:2222](http://localhost:2222)

## 默认账号

初始化脚本内默认账号为：

- 用户名：`admin`
- 密码：`admin123`

如果登录失败，请以数据库实际初始化结果为准。

## 下载与导出说明

记账导出文件、模板下载文件不会落到仓库目录中，而是由浏览器直接下载到：

- 浏览器默认下载目录
- 或用户手动选择的保存位置

这属于当前产品设计，不是后端把文件保存到项目目录。

## 最近修复内容

### 2026-07-04

1. **修复菜单位置问题**
   - 将「数据库查询」从系统管理移动到日常工具目录下
   - 添加菜单自动初始化器，启动时自动创建所需菜单

2. **修复数据字典问题**
   - 修复编辑字典类型时必填字段验证问题
   - 修复新增字典时 timestamp 类型字段不匹配问题
   - 将时间字段类型从 String 改为 LocalDateTime
   - 优化数据字典页面样式，添加渐变色卡片头

3. **修复数据库查询功能**
   - 修复 Vue 模板语法错误（${} 改为字符串拼接）
   - 修复空值合并运算符兼容性问题
   - 支持在系统管理和日常工具目录下正确显示

4. **端口配置调整**
   - 前端端口：5173 → 2221
   - 后端端口：8081 → 2222

5. **新增一键启动脚本**
   - 添加 Windows 批处理脚本 `start.bat`
   - 支持一键同时启动前后端服务

6. **修复记账管理字段映射**
   - 纠正前端表单与后端实体的字段映射错误
   - 修复 Excel 导入导出时字段不匹配问题

## 功能验证清单

新环境部署后，建议按以下顺序验证功能：

1. ✅ 登录 / 退出
2. ✅ 系统管理 - 组织管理
3. ✅ 系统管理 - 用户管理
4. ✅ 系统管理 - 角色管理
5. ✅ 系统管理 - 菜单管理
6. ✅ 系统管理 - 数据字典（类型 + 数据）
7. ✅ 日常工具 - 待办事项（含导入导出）
8. ✅ 日常工具 - 备忘录（含导入导出）
9. ✅ 日常工具 - 数据库查询（连接 + SQL执行）
10. ✅ 财务管理 - 记账管理（含导入导出）
11. ✅ 统计报表

## 常见问题

### Q: 启动后菜单列表没有数据字典或数据库查询？

A: 这是正常现象，首次启动后端会自动创建菜单。刷新页面重新登录即可看到。

### Q: 前端启动报错端口被占用？

A: 可以修改 `frontend/vite.config.js` 中的端口配置。

### Q: 后端启动报错端口被占用？

A: 可以修改 `backend-java/src/main/resources/application.yml` 中的端口配置。

### Q: npm install 太慢？

A: 可以配置淘宝镜像：

```bash
npm config set registry https://registry.npmmirror.com/
```

## 已知问题修复（2026-08-06）

### 1. 待办/备忘录等页面「刷新变成 404」

- **根因**：`frontend/src/router/index.js` 的动态路由守卫里使用了 `next({ ...to, replace: true })`。
  `to` 是带 `matched` 数组的已解析路由对象，展开后把空 `matched` 一并传给 `next()`，
  Vue Router 4 据此认为该 location 已解析、跳过重新匹配，直接落到 catch-all → 404。
  首次 SPA 跳转时 `registeredRouteNames` 已存在而走 `next()` 放行，所以「能打开、一刷新就 404」。
- **修复**：改为 `next({ path: to.path, query: to.query, hash: to.hash, replace: true })`，
  并给兜底路由固定 `name: 'CatchAll404'` 防止重复注册。
- **访问模式说明**：本项目前端使用 `createWebHashHistory()`（hash 模式，`start.bat` → `npm run dev` :2221），
  刷新时浏览器只请求 `/`，不存在服务器侧 404。若改用 `npm run build` 并以 history 模式部署，
  需由静态服务器（nginx 等）配置 SPA fallback（所有路径回退到 `index.html`）。

### 2. 组织新增/编辑报「column does not exist」

- **根因**：Java 实体 `SysOrg` 含 `leader / phone / remark` 字段，但 `sql/init_postgres.sql` 的
  `sys_org` 建表语句缺少这三列；项目未启用 Flyway，迁移脚本不会自动执行，全新初始化库即缺列。
- **修复**：已在 `sql/init_postgres.sql` 的 `sys_org` 表中补齐 `leader / phone / remark` 三列。
- **注意**：若数据库是升级（非全新 init），请手动补列：
  ```sql
  ALTER TABLE sys_org ADD COLUMN IF NOT EXISTS leader VARCHAR(100);
  ALTER TABLE sys_org ADD COLUMN IF NOT EXISTS phone VARCHAR(50);
  ALTER TABLE sys_org ADD COLUMN IF NOT EXISTS remark TEXT;
  ```

### 3. 清理孤儿接口

- 删除了未被前端调用的 `DbQueryController`（`/api/app/db/query`）及其 `DbQueryService` /
  `DbQueryServiceImpl`。前端数据库查询功能实际使用 `DbConnectionController`（`/api/app/db-connections/*`）。

### 架构说明（重要）

- 当前为 **单一 Java 后端**（Spring Boot，端口 2222）+ PostgreSQL（端口 5432，见 `docker-compose.yml`）
  + Vue 3 前端（端口 2221）。
- 早期版本曾存在独立的 `backend-python`（FastAPI）用于待办/备忘录/记账，已于重构中删除并合并进 Java 后端，
  相关旧文档 `FIXES_SUMMARY.md` 已移除，以本 README 为准。
