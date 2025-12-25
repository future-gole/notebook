package com.doublez.pocketmindserver.analyse.graph.config;

import com.doublez.pocketmindserver.shared.util.ResourceUtil;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;

/**
 * Agents 配置类
 */
@Configuration
public class AgentsConfiguration {

    @Value("classpath:prompts/analyse/rewrite_query.md")
    private Resource rewriteQueryPrompt;

    @Value("classpath:prompts/analyse/summarizer.md")
    private Resource summarizerPrompt;

    @Bean
    public ChatClient rewriteQueryAgent(@Qualifier("chatClientBuilder") ChatClient.Builder builder) {
        return builder.defaultSystem(ResourceUtil.loadResourceAsString(rewriteQueryPrompt)).build();
    }

    @Bean
    public ChatClient summarizerAgent(@Qualifier("chatClientBuilder") ChatClient.Builder builder) {
        return builder.defaultSystem(ResourceUtil.loadResourceAsString(summarizerPrompt)).build();
    }
}
