package com.xiao.sys.config;

import org.apache.ibatis.session.SqlSession;
import org.apache.ibatis.session.SqlSessionFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import jakarta.annotation.Resource;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

/**
 * 数据库 schema 初始化器 - 在菜单初始化之前执行
 */
@Component
@Order(1)
public class DatabaseSchemaInitializer implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(DatabaseSchemaInitializer.class);

    @Resource
    private SqlSessionFactory sqlSessionFactory;

    @Override
    public void run(String... args) {
        try (SqlSession sqlSession = sqlSessionFactory.openSession()) {
            // 为 sys_dict_data 表添加 remark 字段
            addRemarkFieldToDictData(sqlSession);
            sqlSession.commit();
        } catch (Exception e) {
            log.warn("数据库 schema 初始化失败: {}", e.getMessage());
        }
    }

    private void addRemarkFieldToDictData(SqlSession sqlSession) {
        try {
            // 先检查字段是否已存在
            String checkSql = "SELECT column_name FROM information_schema.columns WHERE table_name = 'sys_dict_data' AND column_name = 'remark'";
            PreparedStatement checkStmt = sqlSession.getConnection().prepareStatement(checkSql);
            ResultSet rs = checkStmt.executeQuery();
            
            if (!rs.next()) {
                // 字段不存在，添加 remark 字段
                String alterSql = "ALTER TABLE sys_dict_data ADD COLUMN remark VARCHAR(255)";
                PreparedStatement alterStmt = sqlSession.getConnection().prepareStatement(alterSql);
                alterStmt.execute();
                log.info("已为 sys_dict_data 表添加 remark 字段");
            } else {
                log.info("sys_dict_data 表的 remark 字段已存在，跳过添加");
            }
        } catch (Exception e) {
            log.warn("添加 remark 字段失败（可能已存在）: {}", e.getMessage());
        }
    }
}
