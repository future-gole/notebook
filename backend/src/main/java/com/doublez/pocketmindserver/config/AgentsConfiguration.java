package com.doublez.pocketmindserver.config;

import com.doublez.pocketmindserver.util.ResourceUtil;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

/**
 * Agents 配置类
 *
 * 作用:
 * 1. 接收 Spring AI 自动创建的 ChatClient.Builder
 * 2. 为每个 Agent 定制 System Prompt
 * 3. 注册为独立的 Bean
 */
@Configuration
public class AgentsConfiguration {

    @Value("classpath:prompts/demo/rewrite_query.md")
    private Resource rewriteQueryPrompt;

    @Value("classpath:prompts/demo/summarizer.md")
    private Resource summarizerPrompt;

    /**
     * Query Rewriting Agent
     * @param builder ChatClientBuilder injected by Spring AI (使用默认的 chatClientBuilder)
     * @return ChatClient
     */
    @Bean
    public ChatClient rewriteQueryAgent(@Qualifier("chatClientBuilder") ChatClient.Builder builder) {
        return builder.defaultSystem(ResourceUtil.loadResourceAsString(rewriteQueryPrompt)).build();
    }

    /**
     * Summarization Agent
     * @param builder ChatClientBuilder injected by Spring AI (使用默认的 chatClientBuilder)
     * @return ChatClient
     */
    @Bean
    public ChatClient summarizerAgent(@Qualifier("chatClientBuilder") ChatClient.Builder builder) {
        return builder.defaultSystem(ResourceUtil.loadResourceAsString(summarizerPrompt)).build();
    }

}
