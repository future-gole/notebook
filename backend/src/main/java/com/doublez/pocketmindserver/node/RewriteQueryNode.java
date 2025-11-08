package com.doublez.pocketmindserver.node;

import com.alibaba.cloud.ai.graph.OverAllState;
import com.alibaba.cloud.ai.graph.action.NodeAction;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.chat.client.ChatClient;

import java.util.HashMap;
import java.util.Map;
/**
 * Query Rewriting Node
 *
 * Function: Optimize user input and generate more precise search keywords
 *
 */
public class RewriteQueryNode implements NodeAction {

    private static final Logger logger = LoggerFactory.getLogger(RewriteQueryNode.class);

    private final ChatClient chatClient;

    public RewriteQueryNode(ChatClient chatClient) {
        this.chatClient = chatClient;
    }

    @Override
    public Map<String, Object> apply(OverAllState state) throws Exception {
        String userQuery = state.value("user_query", "");
        logger.info("Original query: {}", userQuery);

        try {
            String rewrittenQuery = chatClient.prompt().user("User's original query: " + userQuery).call().content();

            logger.info("Rewritten query: {}", rewrittenQuery);

            Map<String, Object> result = new HashMap<>();
            result.put("rewritten_query", rewrittenQuery);
            return result;
        }
        catch (Exception e) {
            logger.error("Query rewriting failed", e);
            Map<String, Object> result = new HashMap<>();
            result.put("rewritten_query", userQuery); // Fallback to original
            return result;
        }
    }

}