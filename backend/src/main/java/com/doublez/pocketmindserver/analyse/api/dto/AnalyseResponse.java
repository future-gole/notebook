package com.doublez.pocketmindserver.analyse.api.dto;

public record AnalyseResponse(
        String threadId,
        String url,
        boolean crawlSuccess,
        String rewrittenQuery,
        String summary
) {
}
