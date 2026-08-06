-- ============================================================
-- 组织权限管理系统 - PostgreSQL 初始化脚本
-- 数据库名: org_sys
-- ============================================================

-- 创建数据库（需手动执行或注释掉在已连接状态下运行）
-- CREATE DATABASE org_sys WITH ENCODING 'UTF8';

-- \c org_sys

-- ============================================================
-- 1. 系统管理表（Java 主后端管理）
-- ============================================================

-- 组织表（树形）
CREATE TABLE IF NOT EXISTS sys_org (
    id          SERIAL PRIMARY KEY,
    parent_id   INTEGER NOT NULL DEFAULT 0,
    org_name    VARCHAR(100) NOT NULL,
    org_code    VARCHAR(50) UNIQUE NOT NULL,
    sort_order  INTEGER NOT NULL DEFAULT 0,
    status      SMALLINT NOT NULL DEFAULT 1,
    leader_id   INTEGER,
    leader      VARCHAR(100),
    phone       VARCHAR(50),
    remark      TEXT,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_sys_org_parent ON sys_org(parent_id);

-- 职位表
CREATE TABLE IF NOT EXISTS sys_position (
    id            SERIAL PRIMARY KEY,
    org_id        INTEGER NOT NULL REFERENCES sys_org(id),
    position_name VARCHAR(100) NOT NULL,
    position_code VARCHAR(50) NOT NULL,
    sort_order    INTEGER NOT NULL DEFAULT 0,
    status        SMALLINT NOT NULL DEFAULT 1,
    description   TEXT,
    created_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_sys_position_org ON sys_position(org_id);

-- 人员表
CREATE TABLE IF NOT EXISTS sys_user (
    id          SERIAL PRIMARY KEY,
    username    VARCHAR(50) UNIQUE NOT NULL,
    password    VARCHAR(100) NOT NULL,
    real_name   VARCHAR(50),
    email       VARCHAR(100),
    phone       VARCHAR(20),
    org_id      INTEGER REFERENCES sys_org(id),
    status      SMALLINT NOT NULL DEFAULT 1,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_sys_user_org ON sys_user(org_id);

-- 用户-职位关联表
CREATE TABLE IF NOT EXISTS sys_user_position (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER NOT NULL REFERENCES sys_user(id) ON DELETE CASCADE,
    position_id INTEGER NOT NULL REFERENCES sys_position(id) ON DELETE CASCADE,
    is_primary  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, position_id)
);

-- 角色表
CREATE TABLE IF NOT EXISTS sys_role (
    id          SERIAL PRIMARY KEY,
    role_name   VARCHAR(50) NOT NULL,
    role_code   VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    status      SMALLINT NOT NULL DEFAULT 1,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 职位-角色关联表
CREATE TABLE IF NOT EXISTS sys_position_role (
    id          SERIAL PRIMARY KEY,
    position_id INTEGER NOT NULL REFERENCES sys_position(id) ON DELETE CASCADE,
    role_id     INTEGER NOT NULL REFERENCES sys_role(id) ON DELETE CASCADE,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(position_id, role_id)
);

-- 菜单/权限表（树形：目录D、菜单M、按钮B）
CREATE TABLE IF NOT EXISTS sys_menu (
    id          SERIAL PRIMARY KEY,
    parent_id   INTEGER NOT NULL DEFAULT 0,
    menu_name   VARCHAR(50) NOT NULL,
    menu_type   CHAR(1) NOT NULL,
    path        VARCHAR(200),
    component   VARCHAR(200),
    permission  VARCHAR(100),
    icon        VARCHAR(50),
    sort_order  INTEGER NOT NULL DEFAULT 0,
    visible     SMALLINT NOT NULL DEFAULT 1,
    status      SMALLINT NOT NULL DEFAULT 1,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_sys_menu_parent ON sys_menu(parent_id);

-- 角色-菜单关联表
CREATE TABLE IF NOT EXISTS sys_role_menu (
    id          SERIAL PRIMARY KEY,
    role_id     INTEGER NOT NULL REFERENCES sys_role(id) ON DELETE CASCADE,
    menu_id     INTEGER NOT NULL REFERENCES sys_menu(id) ON DELETE CASCADE,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(role_id, menu_id)
);

-- 职位数据权限配置表
CREATE TABLE IF NOT EXISTS sys_position_data_scope (
    id          SERIAL PRIMARY KEY,
    position_id INTEGER NOT NULL REFERENCES sys_position(id) ON DELETE CASCADE,
    scope_type  VARCHAR(20) NOT NULL DEFAULT 'self',
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(position_id)
);

-- 数据权限自定义组织范围
CREATE TABLE IF NOT EXISTS sys_data_scope_org (
    id          SERIAL PRIMARY KEY,
    scope_id    INTEGER NOT NULL REFERENCES sys_position_data_scope(id) ON DELETE CASCADE,
    org_id      INTEGER NOT NULL REFERENCES sys_org(id) ON DELETE CASCADE,
    UNIQUE(scope_id, org_id)
);

-- 操作日志表
CREATE TABLE IF NOT EXISTS sys_oper_log (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER,
    username    VARCHAR(50),
    oper_module VARCHAR(50),
    oper_type   VARCHAR(20),
    oper_desc   TEXT,
    oper_ip     VARCHAR(50),
    oper_time   TIMESTAMP NOT NULL DEFAULT NOW(),
    cost_ms     INTEGER
);
CREATE INDEX IF NOT EXISTS idx_sys_oper_log_user ON sys_oper_log(user_id);
CREATE INDEX IF NOT EXISTS idx_sys_oper_log_time ON sys_oper_log(oper_time);

-- ============================================================
-- 2. 业务表（Python 辅服务管理，迁移自现有系统）
-- ============================================================

CREATE TABLE IF NOT EXISTS records (
    id           SERIAL PRIMARY KEY,
    user_id      INTEGER NOT NULL,
    org_id       INTEGER,
    record_date  VARCHAR(20) NOT NULL,
    type         VARCHAR(10) NOT NULL CHECK(type IN ('income','expense')),
    category     VARCHAR(100) NOT NULL,
    sub_category VARCHAR(100) DEFAULT '',
    amount       REAL NOT NULL CHECK(amount >= 0),
    account      VARCHAR(50) DEFAULT '',
    note         TEXT,
    created_at   VARCHAR(30),
    updated_at   VARCHAR(30)
);
CREATE INDEX IF NOT EXISTS idx_records_user ON records(user_id);
CREATE INDEX IF NOT EXISTS idx_records_date ON records(record_date);
CREATE INDEX IF NOT EXISTS idx_records_org ON records(org_id);

CREATE TABLE IF NOT EXISTS todos (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER NOT NULL,
    org_id      INTEGER,
    title       VARCHAR(200) NOT NULL,
    completed   INTEGER NOT NULL DEFAULT 0,
    priority    VARCHAR(20) DEFAULT 'normal',
    due_date    VARCHAR(20),
    remark      TEXT,
    creator     VARCHAR(50) DEFAULT '',
    assignee    VARCHAR(50) DEFAULT '',
    completed_at VARCHAR(30),
    created_at  VARCHAR(30),
    updated_at  VARCHAR(30)
);
CREATE INDEX IF NOT EXISTS idx_todos_user ON todos(user_id);

CREATE TABLE IF NOT EXISTS notes (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER NOT NULL,
    org_id      INTEGER,
    title       VARCHAR(200) NOT NULL,
    content     TEXT,
    note_type   VARCHAR(50) DEFAULT '',
    tags        TEXT,
    created_at  VARCHAR(30),
    updated_at  VARCHAR(30)
);
CREATE INDEX IF NOT EXISTS idx_notes_user ON notes(user_id);

CREATE TABLE IF NOT EXISTS db_connections (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER NOT NULL,
    name        VARCHAR(100) NOT NULL,
    db_type     VARCHAR(20) NOT NULL,
    host        VARCHAR(100),
    port        INTEGER,
    username    VARCHAR(100),
    password    TEXT,
    "database"  VARCHAR(100),
    sqlite_path TEXT,
    created_at  VARCHAR(30),
    updated_at  VARCHAR(30)
);
CREATE INDEX IF NOT EXISTS idx_db_conn_user ON db_connections(user_id);

-- ============================================================
-- 3. 初始化数据
-- ============================================================

-- 默认管理员（密码: admin123 的 bcrypt 哈希）
INSERT INTO sys_user (username, password, real_name, status) VALUES
('admin', '$2b$12$QdePcM9JuwfrlV0nDiq5/e3YyLEiGNnI3qT1Y0BR59wbmPiZaowOa', '系统管理员', 1)
ON CONFLICT (username) DO NOTHING;

-- 根组织
INSERT INTO sys_org (id, parent_id, org_name, org_code, sort_order, status) VALUES
(1, 0, '总公司', 'ROOT', 0, 1),
(2, 1, '研发部', 'RD', 1, 1),
(3, 1, '产品部', 'PM', 2, 1),
(4, 1, '市场部', 'MK', 3, 1),
(5, 1, '财务部', 'FI', 4, 1),
(6, 2, '前端开发组', 'FE', 1, 1),
(7, 2, '后端开发组', 'BE', 2, 1),
(8, 2, '测试组', 'QA', 3, 1)
ON CONFLICT (org_code) DO NOTHING;

-- 默认角色
INSERT INTO sys_role (role_name, role_code, description, status) VALUES
('超级管理员', 'super_admin', '拥有所有权限', 1),
('普通用户', 'common_user', '基础查看权限', 1),
('研发经理', 'rd_mgr_role', '研发经理，可查看本部门及下属数据', 1),
('开发人员', 'dev_role', '开发人员，仅可查看自己的数据', 1),
('产品经理', 'pm_role', '产品经理，可查看全部数据', 1),
('财务人员', 'fi_role', '财务人员，可查看本部门数据', 1)
ON CONFLICT (role_code) DO NOTHING;

-- 默认职位
INSERT INTO sys_position (org_id, position_name, position_code, sort_order, status, description) VALUES
(1, '系统管理员', 'sys_admin', 0, 1, '系统最高权限管理员'),
(2, '研发经理', 'rd_mgr', 1, 1, '研发部门负责人'),
(6, '前端工程师', 'fe_dev', 2, 1, '前端开发工程师'),
(7, '后端工程师', 'be_dev', 3, 1, '后端开发工程师'),
(8, '测试工程师', 'qa_dev', 4, 1, '测试工程师'),
(3, '产品经理', 'product_mgr', 5, 1, '产品经理'),
(5, '财务专员', 'fi_staff', 6, 1, '财务专员'),
(4, '市场专员', 'mk_staff', 7, 1, '市场专员')
ON CONFLICT DO NOTHING;

-- 测试用户（密码: Zhang@123 的 bcrypt 哈希）
INSERT INTO sys_user (username, password, real_name, email, phone, org_id, status) VALUES
('zhangwei', '$2a$10$y7E8o8Yc4h7pV8W8o7V8W8o7V8W8o7V8W8o7V8W8o7V8W8o7V8', '张伟', 'zhangwei@example.com', '13800138001', 2, 1),
('lisi', '$2a$10$y7E8o8Yc4h7pV8W8o7V8W8o7V8W8o7V8W8o7V8W8o7V8W8o7V8', '李思', 'lisi@example.com', '13800138002', 6, 1),
('wangwu', '$2a$10$y7E8o8Yc4h7pV8W8o7V8W8o7V8W8o7V8W8o7V8W8o7V8W8o7V8', '王五', 'wangwu@example.com', '13800138003', 7, 1),
('zhaoliu', '$2a$10$y7E8o8Yc4h7pV8W8o7V8W8o7V8W8o7V8W8o7V8W8o7V8W8o7V8', '赵六', 'zhaoliu@example.com', '13800138004', 8, 1),
('sunqi', '$2a$10$y7E8o8Yc4h7pV8W8o7V8W8o7V8W8o7V8W8o7V8W8o7V8W8o7V8', '孙七', 'sunqi@example.com', '13800138005', 3, 1),
('zhouba', '$2a$10$y7E8o8Yc4h7pV8W8o7V8W8o7V8W8o7V8W8o7V8W8o7V8W8o7V8', '周八', 'zhouba@example.com', '13800138006', 5, 1),
('wujiu', '$2a$10$y7E8o8Yc4h7pV8W8o7V8W8o7V8W8o7V8W8o7V8W8o7V8W8o7V8', '吴九', 'wujiu@example.com', '13800138007', 4, 1)
ON CONFLICT (username) DO NOTHING;

-- 用户-职位关联
INSERT INTO sys_user_position (user_id, position_id, is_primary) VALUES
((SELECT id FROM sys_user WHERE username='admin'), (SELECT id FROM sys_position WHERE position_code='sys_admin'), TRUE),
((SELECT id FROM sys_user WHERE username='zhangwei'), (SELECT id FROM sys_position WHERE position_code='rd_mgr'), TRUE),
((SELECT id FROM sys_user WHERE username='lisi'), (SELECT id FROM sys_position WHERE position_code='fe_dev'), TRUE),
((SELECT id FROM sys_user WHERE username='wangwu'), (SELECT id FROM sys_position WHERE position_code='be_dev'), TRUE),
((SELECT id FROM sys_user WHERE username='zhaoliu'), (SELECT id FROM sys_position WHERE position_code='qa_dev'), TRUE),
((SELECT id FROM sys_user WHERE username='sunqi'), (SELECT id FROM sys_position WHERE position_code='product_mgr'), TRUE),
((SELECT id FROM sys_user WHERE username='zhouba'), (SELECT id FROM sys_position WHERE position_code='fi_staff'), TRUE),
((SELECT id FROM sys_user WHERE username='wujiu'), (SELECT id FROM sys_position WHERE position_code='mk_staff'), TRUE)
ON CONFLICT DO NOTHING;

-- 职位-角色关联
INSERT INTO sys_position_role (position_id, role_id) VALUES
((SELECT id FROM sys_position WHERE position_code='sys_admin'), (SELECT id FROM sys_role WHERE role_code='super_admin')),
((SELECT id FROM sys_position WHERE position_code='rd_mgr'), (SELECT id FROM sys_role WHERE role_code='rd_mgr_role')),
((SELECT id FROM sys_position WHERE position_code='fe_dev'), (SELECT id FROM sys_role WHERE role_code='dev_role')),
((SELECT id FROM sys_position WHERE position_code='be_dev'), (SELECT id FROM sys_role WHERE role_code='dev_role')),
((SELECT id FROM sys_position WHERE position_code='qa_dev'), (SELECT id FROM sys_role WHERE role_code='dev_role')),
((SELECT id FROM sys_position WHERE position_code='product_mgr'), (SELECT id FROM sys_role WHERE role_code='pm_role')),
((SELECT id FROM sys_position WHERE position_code='fi_staff'), (SELECT id FROM sys_role WHERE role_code='fi_role')),
((SELECT id FROM sys_position WHERE position_code='mk_staff'), (SELECT id FROM sys_role WHERE role_code='pm_role'))
ON CONFLICT DO NOTHING;

-- 职位数据权限配置
INSERT INTO sys_position_data_scope (position_id, scope_type) VALUES
((SELECT id FROM sys_position WHERE position_code='sys_admin'), 'all'),
((SELECT id FROM sys_position WHERE position_code='rd_mgr'), 'dept_and_sub'),
((SELECT id FROM sys_position WHERE position_code='fe_dev'), 'self'),
((SELECT id FROM sys_position WHERE position_code='be_dev'), 'self'),
((SELECT id FROM sys_position WHERE position_code='qa_dev'), 'self'),
((SELECT id FROM sys_position WHERE position_code='product_mgr'), 'all'),
((SELECT id FROM sys_position WHERE position_code='fi_staff'), 'dept'),
((SELECT id FROM sys_position WHERE position_code='mk_staff'), 'all')
ON CONFLICT DO NOTHING;

-- 菜单初始数据
INSERT INTO sys_menu (id, parent_id, menu_name, menu_type, path, component, permission, icon, sort_order, visible, status) VALUES
(1,  0, '系统管理', 'D', '/system',    NULL,                    NULL,              'Setting',  90, 1, 1),
(2,  1, '组织管理', 'M', 'org',        'system/org/index',      'system:org:list', 'OfficeBuilding', 1, 1, 1),
(3,  1, '人员管理', 'M', 'user',       'system/user/index',     'system:user:list','User',     2, 1, 1),
(4,  1, '职位管理', 'M', 'position',   'system/position/index', 'system:position:list','Post', 3, 1, 1),
(5,  1, '角色管理', 'M', 'role',       'system/role/index',     'system:role:list','Key',      4, 1, 1),
(6,  1, '菜单管理', 'M', 'menu',       'system/menu/index',     'system:menu:list','Menu',     5, 1, 1),
(10, 0, '财务管理', 'D', '/finance',   NULL,                    NULL,              'Money',    10, 1, 1),
(11, 10, '记账管理', 'M', 'accounting','accounting/index',      'finance:accounting:list','Wallet', 1, 1, 1),
(12, 10, '统计报表', 'M', 'stats',     'stats/index',           'finance:stats:list','TrendCharts', 2, 1, 1),
(20, 0, '日常工具', 'D', '/tools',     NULL,                    NULL,              'Tools',    20, 1, 1),
(21, 20, '待办事项', 'M', 'todo',      'todo/index',            'tools:todo:list', 'Checked',  1, 1, 1),
(22, 20, '备忘录',   'M', 'notes',     'notes/index',           'tools:notes:list','Document', 2, 1, 1),
(23, 20, '数据库查询','M','db-query',  'db-query/index',        'tools:dbquery:list','Connection', 3, 1, 1)
ON CONFLICT DO NOTHING;

-- 按钮权限
INSERT INTO sys_menu (parent_id, menu_name, menu_type, permission, sort_order, status) VALUES
(2, '新增组织', 'B', 'system:org:add', 1, 1),
(2, '编辑组织', 'B', 'system:org:edit', 2, 1),
(2, '删除组织', 'B', 'system:org:del', 3, 1),
(3, '新增人员', 'B', 'system:user:add', 1, 1),
(3, '编辑人员', 'B', 'system:user:edit', 2, 1),
(3, '删除人员', 'B', 'system:user:del', 3, 1),
(3, '重置密码', 'B', 'system:user:reset', 4, 1),
(4, '新增职位', 'B', 'system:position:add', 1, 1),
(4, '编辑职位', 'B', 'system:position:edit', 2, 1),
(4, '删除职位', 'B', 'system:position:del', 3, 1),
(4, '分配权限', 'B', 'system:position:perm', 4, 1),
(5, '新增角色', 'B', 'system:role:add', 1, 1),
(5, '编辑角色', 'B', 'system:role:edit', 2, 1),
(5, '删除角色', 'B', 'system:role:del', 3, 1),
(5, '分配菜单', 'B', 'system:role:perm', 4, 1),
(6, '新增菜单', 'B', 'system:menu:add', 1, 1),
(6, '编辑菜单', 'B', 'system:menu:edit', 2, 1),
(6, '删除菜单', 'B', 'system:menu:del', 3, 1),
(11, '新增记录', 'B', 'finance:accounting:add', 1, 1),
(11, '编辑记录', 'B', 'finance:accounting:edit', 2, 1),
(11, '删除记录', 'B', 'finance:accounting:del', 3, 1),
(11, '导入数据', 'B', 'finance:accounting:import', 4, 1),
(11, '导出数据', 'B', 'finance:accounting:export', 5, 1)
ON CONFLICT DO NOTHING;

-- 超级管理员角色关联所有菜单
INSERT INTO sys_role_menu (role_id, menu_id)
SELECT r.id, m.id FROM sys_role r, sys_menu m WHERE r.role_code = 'super_admin'
ON CONFLICT DO NOTHING;

-- 重置序列
SELECT setval('sys_org_id_seq', (SELECT MAX(id) FROM sys_org));
SELECT setval('sys_menu_id_seq', (SELECT MAX(id) FROM sys_menu));
