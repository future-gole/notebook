package com.doublez.pocketmindserver.shared.infra.mybatis;

import com.baomidou.mybatisplus.autoconfigure.ConfigurationCustomizer;
import com.doublez.pocketmindserver.shared.infra.mybatis.UuidTypeHandler;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.UUID;

@Configuration
public class MybatisPlusConfig {

    @Bean
    public ConfigurationCustomizer configurationCustomizer() {
        return configuration -> {
            // Register UUID Type Handler for PostgreSQL
            configuration.getTypeHandlerRegistry().register(UUID.class, UuidTypeHandler.class);
        };
    }
}
