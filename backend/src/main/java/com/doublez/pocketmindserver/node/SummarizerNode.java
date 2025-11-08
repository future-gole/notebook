package com.doublez.pocketmindserver.node;

import com.alibaba.cloud.ai.graph.OverAllState;
import com.alibaba.cloud.ai.graph.action.NodeAction;
import org.springframework.ai.chat.client.ChatClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.HashMap;
import java.util.Map;

/**
 * Content Summarization Node
 *
 * Function: Use LLM to summarize the crawled content
 *
 */
public class SummarizerNode implements NodeAction {

    private static final Logger logger = LoggerFactory.getLogger(SummarizerNode.class);

    private final ChatClient chatClient;

    public SummarizerNode(ChatClient chatClient) {
        this.chatClient = chatClient;
    }

    @Override
    public Map<String, Object> apply(OverAllState state) throws Exception {
        String content = state.value("crawled_content", "");
        Boolean success = state.value("crawl_success", false);

        if (!success) {
            logger.warn("Skipping summarization because crawling failed");
            Map<String, Object> result = new HashMap<>();
            result.put("summary", "Unable to summarize, webpage crawling failed");
            return result;
        }

        logger.info("Starting content summarization, length: {} characters", content.length());

        try {
            String summaryPrompt = String.format("""
					The following is content crawled from a webpage:

					%s

					Please summarize the core information.
					""", content);

            String summary = chatClient.prompt().user(summaryPrompt).call().content();

            logger.info("Summarization complete, length: {} characters", summary.length());

            Map<String, Object> result = new HashMap<>();
            result.put("summary", summary);
            return result;
        }
        catch (Exception e) {
            logger.error("Summarization failed", e);
            Map<String, Object> result = new HashMap<>();
            result.put("summary", "Summarization failed: " + e.getMessage());
            return result;
        }
    }

}
