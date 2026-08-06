-- 为 sys_dict_data 表添加 remark 字段
ALTER TABLE sys_dict_data ADD COLUMN IF NOT EXISTS remark VARCHAR(255);
