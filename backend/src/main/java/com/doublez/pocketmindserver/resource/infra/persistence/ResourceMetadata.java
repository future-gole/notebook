package com.doublez.pocketmindserver.resource.infra.persistence;

import com.baomidou.mybatisplus.annotation.FieldFill;
import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.doublez.pocketmindserver.resource.domain.ResourceStatus;
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

    private ResourceStatus processStatus;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;

}
