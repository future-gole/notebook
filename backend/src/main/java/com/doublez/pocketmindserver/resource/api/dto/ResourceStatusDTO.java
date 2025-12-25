package com.doublez.pocketmindserver.resource.api.dto;

import com.doublez.pocketmindserver.resource.infra.persistence.ResourceMetadata;

import java.util.UUID;

public record ResourceStatusDTO(
        String url,
        UUID uuid,
        String title,
        String previewContent,
        String aiSummary,
        ResourceMetadata.ProcessStatus status
) {
}
