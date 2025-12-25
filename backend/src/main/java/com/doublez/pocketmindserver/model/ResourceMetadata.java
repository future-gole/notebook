package com.doublez.pocketmindserver.model;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@TableName("resource_metadata")
public class ResourceMetadata {

    @TableId(type = IdType.INPUT)
    private UUID id;

    private String userId;

    private String originalUrl;

    private String title;

    private String contentMarkdown;

    private String aiSummary;

    private ProcessStatus processStatus;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;

    public enum ProcessStatus {
        PENDING,
        CRAWLED,
        EMBEDDED,
        FAILED
    }
}
