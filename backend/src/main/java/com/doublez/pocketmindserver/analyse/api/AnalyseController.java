package com.doublez.pocketmindserver.analyse.api;

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
import com.doublez.pocketmindserver.analyse.api.dto.AnalyseRequest;
import com.doublez.pocketmindserver.analyse.api.dto.AnalyseResponse;
import com.doublez.pocketmindserver.analyse.infra.email.EmailService;
import lombok.extern.slf4j.Slf4j;
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
 * Analyse REST API Controller - 网页分析智能体接口
 * 功能: 接收用户查询和网页URL,执行 rewrite_query -> crawler -> summarizer 工作流
 */
@Slf4j
@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/analyse")
public class AnalyseController {

    private static final Logger logger = LoggerFactory.getLogger(AnalyseController.class);

    private final CompiledGraph compiledGraph;
    private final EmailService emailService;

    /**
     * 构造函数: 编译 Graph 并配置 MemorySaver
     */
    @Autowired
    public AnalyseController(@Qualifier("analyseGraph") StateGraph stateGraph, EmailService emailService) throws GraphStateException {
        this.emailService = emailService;
        SaverConfig saverConfig = SaverConfig.builder()
                .register(SaverEnum.MEMORY.getValue(), new MemorySaver())
                .build();
        this.compiledGraph = stateGraph.compile(CompileConfig.builder().saverConfig(saverConfig).build());
        logger.info("AnalyseController initialized successfully");
    }

    /**
     * 分析网页接口
     */
    @PostMapping("/analyze")
    public AnalyseResponse analyze(@RequestBody AnalyseRequest request)
            throws GraphRunnerException, GraphStateException {
        logger.info("Received analyze request - userQuery: {}, url: {}", request.userQuery(), request.url());

        // 生成唯一线程ID
        String threadId = "analyse_" + UUID.randomUUID();
        RunnableConfig runnableConfig = RunnableConfig.builder().threadId(threadId).build();

        // 构建输入状态
        Map<String, Object> input = new HashMap<>();
        input.put("user_query", request.userQuery());
        input.put("url", request.url());

        NodeOutput lastOutput = compiledGraph.fluxStream(input, runnableConfig)
                .doOnNext(nodeOutput -> logger.debug("Node {} completed", nodeOutput.node()))
                .blockLast();

        if (lastOutput == null) {
            throw new GraphRunnerException("Graph execution failed: no output received");
        }

        String rewrittenQuery = lastOutput.state().value("rewritten_query", "");
        String summary = lastOutput.state().value("summary", "");
        Boolean crawlSuccess = lastOutput.state().value("crawl_success", false);

        if (request.userEmail() != null && !request.userEmail().isBlank()) {
            emailService.sendAnalyseResult(request.userEmail(), threadId, request.url(), crawlSuccess, summary);
        }

        return new AnalyseResponse(threadId, request.url(), crawlSuccess, rewrittenQuery, summary);
    }
}
