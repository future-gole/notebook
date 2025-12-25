package com.doublez.pocketmindserver.analyse.graph.config;

import com.alibaba.cloud.ai.graph.KeyStrategy;
import com.alibaba.cloud.ai.graph.KeyStrategyFactory;
import com.alibaba.cloud.ai.graph.StateGraph;
import com.alibaba.cloud.ai.graph.exception.GraphStateException;
import com.alibaba.cloud.ai.graph.state.strategy.ReplaceStrategy;
import com.alibaba.cloud.ai.toolcalling.jinacrawler.JinaCrawlerService;
import com.doublez.pocketmindserver.analyse.graph.node.CrawlerNode;
import com.doublez.pocketmindserver.analyse.graph.node.RewriteQueryNode;
import com.doublez.pocketmindserver.analyse.graph.node.SummarizerNode;
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
 * Analyse Graph Configuration
 */
@Configuration
public class AnalyseGraphConfiguration {

    private static final Logger logger = LoggerFactory.getLogger(AnalyseGraphConfiguration.class);

    @Autowired
    private ChatClient rewriteQueryAgent;

    @Autowired
    private ChatClient summarizerAgent;

    @Autowired(required = false)
    private JinaCrawlerService jinaCrawlerService;

    @Bean
    public StateGraph analyseGraph() throws GraphStateException {
        logger.info("Initializing Analyse Graph...");

        KeyStrategyFactory keyStrategyFactory = () -> {
            HashMap<String, KeyStrategy> strategies = new HashMap<>();
            strategies.put("rewritten_query", new ReplaceStrategy());
            strategies.put("crawled_content", new ReplaceStrategy());
            strategies.put("crawl_success", new ReplaceStrategy());
            strategies.put("summary", new ReplaceStrategy());
            return strategies;
        };

        StateGraph graph = new StateGraph("analyse_graph", keyStrategyFactory);

        graph.addNode("rewrite_query", node_async(new RewriteQueryNode(rewriteQueryAgent)));

        if (jinaCrawlerService != null) {
            graph.addNode("crawler", node_async(new CrawlerNode(jinaCrawlerService)));
        } else {
            logger.warn("JinaCrawlerService is not available, skipping crawler node");
        }

        graph.addNode("summarizer", node_async(new SummarizerNode(summarizerAgent)));

        graph.addEdge(START, "rewrite_query");

        if (jinaCrawlerService != null) {
            graph.addEdge("rewrite_query", "crawler");
            graph.addEdge("crawler", "summarizer");
        } else {
            graph.addEdge("rewrite_query", "summarizer");
        }

        graph.addEdge("summarizer", END);

        logger.info("Analyse Graph initialized successfully");
        return graph;
    }
}
