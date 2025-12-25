package com.doublez.pocketmindserver.resource.domain;

import lombok.Getter;

import java.util.Objects;
import java.util.UUID;
@Getter
public class Resource {

    private final UUID id;
    private final String userId;
    private final String originalUrl;

    private String title;
    private String contentMarkdown;
    private String aiSummary;

    private ResourceStatus status;

    private Resource(UUID id, String userId, String originalUrl, ResourceStatus status) {
        this.id = Objects.requireNonNull(id, "id");
        this.userId = requireNotBlank(userId, "userId");
        this.originalUrl = requireNotBlank(originalUrl, "originalUrl");
        this.status = Objects.requireNonNull(status, "status");
    }

    public static Resource create(UUID id, String userId, String originalUrl) {
        return new Resource(id, userId, originalUrl, ResourceStatus.PENDING);
    }

    public static Resource rehydrate(
            UUID id,
            String userId,
            String originalUrl,
            String title,
            String contentMarkdown,
            String aiSummary,
            ResourceStatus status
    ) {
        Resource resource = new Resource(id, userId, originalUrl, status);
        resource.title = title;
        resource.contentMarkdown = contentMarkdown;
        resource.aiSummary = aiSummary;
        return resource;
    }

    public void markCrawled(String title, String contentMarkdown) {
        if (this.status == ResourceStatus.FAILED) {
            throw new IllegalStateException("资源已失败，不能标记为抓取成功");
        }
        this.title = title;
        this.contentMarkdown = contentMarkdown;
        this.status = ResourceStatus.CRAWLED;
    }

    public void markFailed() {
        this.status = ResourceStatus.FAILED;
    }

    public void markEmbedding() {
        requireStatus(ResourceStatus.CRAWLED);
        this.status = ResourceStatus.EMBEDDING;
    }

    public void markEmbedded() {
        requireStatus(ResourceStatus.EMBEDDING);
        this.status = ResourceStatus.EMBEDDED;
    }

    public void markAnalyzing() {
        if (this.status != ResourceStatus.CRAWLED && this.status != ResourceStatus.EMBEDDED) {
            throw new IllegalStateException("当前状态不允许进入分析");
        }
        this.status = ResourceStatus.ANALYZING;
    }

    public void markAnalyzed(String aiSummary) {
        requireStatus(ResourceStatus.ANALYZING);
        this.aiSummary = aiSummary;
        this.status = ResourceStatus.ANALYZED;
    }

    private void requireStatus(ResourceStatus expected) {
        if (this.status != expected) {
            throw new IllegalStateException("状态不匹配，期望=" + expected + "，实际=" + this.status);
        }
    }

    private static String requireNotBlank(String value, String name) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(name + " 不能为空");
        }
        return value;
    }
}
