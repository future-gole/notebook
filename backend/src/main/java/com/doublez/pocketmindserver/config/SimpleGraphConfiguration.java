package com.doublez.pocketmindserver.config;

import com.alibaba.cloud.ai.graph.KeyStrategy;
import com.alibaba.cloud.ai.graph.KeyStrategyFactory;
import com.alibaba.cloud.ai.graph.StateGraph;
import com.alibaba.cloud.ai.graph.exception.GraphStateException;
import com.alibaba.cloud.ai.graph.state.strategy.ReplaceStrategy;
import com.alibaba.cloud.ai.toolcalling.jinacrawler.JinaCrawlerService;
import com.doublez.pocketmindserver.node.CrawlerNode;
import com.doublez.pocketmindserver.node.RewriteQueryNode;
import com.doublez.pocketmindserver.node.SummarizerNode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.HashMap;

import static com.alibaba.cloud.ai.graph.StateGraph.END;
import static com.alibaba.cloud.ai.graph.StateGraph.START;
import static com.alibaba.cloud.ai.graph.action.AsyncNodeAction.node_async;

/**
 * MyDemo Graph Configuration
 *
 * Define the workflow: RewriteQueryNode → CrawlerNode → SummarizerNode
 */
@Configuration
public class SimpleGraphConfiguration {

    private static final Logger logger = LoggerFactory.getLogger(SimpleGraphConfiguration.class);

    @Autowired
    private ChatClient rewriteQueryAgent;

    @Autowired
    private ChatClient summarizerAgent;

    @Autowired(required = false)
    private JinaCrawlerService jinaCrawlerService;

    @Bean
    public StateGraph myDemoGraph() throws GraphStateException {
        logger.info("Initializing MyDemo Graph...");

        // 1. Define state update strategy
        KeyStrategyFactory keyStrategyFactory = () -> {
            HashMap<String, KeyStrategy> strategies = new HashMap<>();
            strategies.put("rewritten_query", new ReplaceStrategy());
            strategies.put("crawled_content", new ReplaceStrategy());
            strategies.put("crawl_success", new ReplaceStrategy());
            strategies.put("summary", new ReplaceStrategy());
            return strategies;
        };

        // 2. Create StateGraph instance
        StateGraph graph = new StateGraph("mydemo_graph", keyStrategyFactory);

        // 3. Register nodes
        graph.addNode("rewrite_query", node_async(new RewriteQueryNode(rewriteQueryAgent)));

        if (jinaCrawlerService != null) {
            graph.addNode("crawler", node_async(new CrawlerNode(jinaCrawlerService)));
        }
        else {
            logger.warn("JinaCrawlerService is not available, skipping crawler node");
        }

        graph.addNode("summarizer", node_async(new SummarizerNode(summarizerAgent)));

        // 4. Define execution flow
        graph.addEdge(START, "rewrite_query");

        if (jinaCrawlerService != null) {
            graph.addEdge("rewrite_query", "crawler");
            graph.addEdge("crawler", "summarizer");
        }
        else {
            graph.addEdge("rewrite_query", "summarizer");
        }

        graph.addEdge("summarizer", END);

        logger.info("MyDemo Graph initialized successfully");

        return graph;
    }
}
