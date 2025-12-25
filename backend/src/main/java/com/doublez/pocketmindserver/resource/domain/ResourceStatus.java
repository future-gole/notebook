package com.doublez.pocketmindserver.resource.domain;

public enum ResourceStatus {
    PENDING,
    CRAWLED,
    EMBEDDING,
    EMBEDDED,
    ANALYZING,
    ANALYZED,
    FAILED
}
