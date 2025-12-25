package com.doublez.pocketmindserver.dto;

import com.doublez.pocketmindserver.model.ResourceMetadata;
import java.util.UUID;

public record ResourceStatusDTO(
        UUID uuid,
        String title,
        String previewContent,
        String aiSummary,
        ResourceMetadata.ProcessStatus status
) {}
