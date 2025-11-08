package com.doublez.pocketmindserver.controller;

import com.alibaba.cloud.ai.graph.CompileConfig;
import com.alibaba.cloud.ai.graph.CompiledGraph;
import com.alibaba.cloud.ai.graph.NodeOutput;
import com.alibaba.cloud.ai.graph.RunnableConfig;
import com.alibaba.cloud.ai.graph.StateGraph;
import com.alibaba.cloud.ai.graph.checkpoint.config.SaverConfig;
import com.alibaba.cloud.ai.graph.checkpoint.constant.SaverEnum;
import com.alibaba.cloud.ai.graph.checkpoint.savers.MemorySaver;
import com.alibaba.cloud.ai.graph.exception.GraphRunnerException;
import com.alibaba.cloud.ai.graph.exception.GraphStateException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * MyDemo REST API Controller - 网页分析智能体接口
 * 功能: 接收用户查询和网页URL,执行 rewrite_query -> crawler -> summarizer 工作流
 */
@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/mydemo")
public class MyDemoController {

    private static final Logger logger = LoggerFactory.getLogger(MyDemoController.class);

    private final CompiledGraph compiledGraph;

    /**
     * 构造函数: 编译 Graph 并配置 MemorySaver
     */
    @Autowired
    public MyDemoController(@Qualifier("myDemoGraph") StateGraph stateGraph) throws GraphStateException {
        SaverConfig saverConfig = SaverConfig.builder()
                .register(SaverEnum.MEMORY.getValue(), new MemorySaver())
                .build();
        this.compiledGraph = stateGraph.compile(CompileConfig.builder().saverConfig(saverConfig).build());
        logger.info("MyDemoController initialized successfully");
    }

    /**
     * 分析网页接口
     * <p>
     * 接收参数: - userQuery: 用户查询 (例如: "帮我分析这个页面的核心内容") - url: 网页地址 (例如:
     * "https://example.com")
     * </p>
     * <p>
     * 返回参数: - success: 是否成功 - rewrittenQuery: 重写后的查询 - crawledContent: 抓取的网页内容 - summary:
     * 总结结果 - message: 提示信息
     * </p>
     */
    @PostMapping("/analyze")
    public Map<String, Object> analyze(@RequestBody AnalyzeRequest request)
            throws GraphRunnerException, GraphStateException {
        logger.info("Received analyze request - userQuery: {}, url: {}", request.userQuery(), request.url());

        // 生成唯一线程ID (参考 ChatController)
        String threadId = "mydemo_" + UUID.randomUUID().toString();
        RunnableConfig runnableConfig = RunnableConfig.builder().threadId(threadId).build();

        // 构建输入状态 (参考 ChatController 的 initializeObjectMap)
        Map<String, Object> input = new HashMap<>();
        input.put("user_query", request.userQuery());
        input.put("url", request.url());

        // 执行 Graph (使用 fluxStream 并阻塞等待完成)
        logger.debug("Executing graph with input: {}", input);
        NodeOutput lastOutput = compiledGraph.fluxStream(input, runnableConfig)
                .doOnNext(nodeOutput -> logger.debug("Node {} completed", nodeOutput.node()))
                .blockLast(); // 阻塞等待最后一个节点完成
        logger.info("Graph execution completed");

        if (lastOutput == null) {
            throw new GraphRunnerException("Graph execution failed: no output received");
        }

        // 提取结果 (使用 OverAllState)
        String rewrittenQuery = lastOutput.state().value("rewritten_query", "");
        String crawledContent = lastOutput.state().value("crawled_content", "");
        String summary = lastOutput.state().value("summary", "");
        Boolean crawlSuccess = lastOutput.state().value("crawl_success", false);

        // 构建响应
        Map<String, Object> response = new HashMap<>();
        response.put("success", crawlSuccess);
        response.put("rewrittenQuery", rewrittenQuery);
        response.put("crawledContent",
                crawledContent.length() > 500 ? crawledContent.substring(0, 500) + "..." : crawledContent);
        response.put("summary", summary);
        response.put("message", crawlSuccess ? "分析完成" : "网页抓取失败");
        response.put("threadId", threadId);

        logger.info("Response prepared - success: {}, summary length: {}", crawlSuccess, summary.length());
        return response;
    }

    /**
     * 请求参数定义 (使用 Java Record)
     */
    public record AnalyzeRequest(String userQuery, String url) {
    }

}