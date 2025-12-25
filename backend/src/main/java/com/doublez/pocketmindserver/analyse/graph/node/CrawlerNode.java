package com.doublez.pocketmindserver.analyse.graph.node;

import com.alibaba.cloud.ai.graph.OverAllState;
import com.alibaba.cloud.ai.graph.action.NodeAction;
import com.alibaba.cloud.ai.toolcalling.jinacrawler.JinaCrawlerService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.Map;

/**
 * Web Crawler Node
 */
public class CrawlerNode implements NodeAction {

    private static final Logger logger = LoggerFactory.getLogger(CrawlerNode.class);

    private final JinaCrawlerService jinaCrawlerService;

    public CrawlerNode(JinaCrawlerService jinaCrawlerService) {
        this.jinaCrawlerService = jinaCrawlerService;
    }

    @Override
    public Map<String, Object> apply(OverAllState state) throws Exception {
        String url = state.value("url", "");
        logger.info("Starting to crawl webpage: {}", url);

        try {
            JinaCrawlerService.Request request = new JinaCrawlerService.Request(url);
            JinaCrawlerService.Response response = jinaCrawlerService.apply(request);

            String content = response.content();
            logger.info("Crawling succeeded, content length: {} characters", content.length());

            Map<String, Object> result = new HashMap<>();
            result.put("crawled_content", content);
            result.put("crawl_success", true);
            return result;
        } catch (Exception e) {
            logger.error("Webpage crawling failed", e);
            Map<String, Object> result = new HashMap<>();
            result.put("crawled_content", "Crawling failed: " + e.getMessage());
            result.put("crawl_success", false);
            return result;
        }
    }
}
