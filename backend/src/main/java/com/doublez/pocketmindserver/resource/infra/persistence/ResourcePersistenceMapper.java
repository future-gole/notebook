package com.doublez.pocketmindserver.resource.infra.persistence;

import com.doublez.pocketmindserver.resource.domain.Resource;
import com.doublez.pocketmindserver.resource.domain.ResourceStatus;

final class ResourcePersistenceMapper {

    private ResourcePersistenceMapper() {
    }

    static ResourceMetadata toModel(Resource resource) {
        ResourceMetadata model = new ResourceMetadata();
        model.setId(resource.getId());
        model.setUserId(resource.getUserId());
        model.setOriginalUrl(resource.getOriginalUrl());
        model.setTitle(resource.getTitle());
        model.setContentMarkdown(resource.getContentMarkdown());
        model.setAiSummary(resource.getAiSummary());
        model.setProcessStatus(toProcessStatus(resource.getStatus()));
        return model;
    }

    static Resource toDomain(ResourceMetadata model) {
        return Resource.rehydrate(
                model.getId(),
                model.getUserId(),
                model.getOriginalUrl(),
                model.getTitle(),
                model.getContentMarkdown(),
                model.getAiSummary(),
                fromProcessStatus(model.getProcessStatus())
        );
    }

    static ResourceMetadata.ProcessStatus toProcessStatus(ResourceStatus status) {
        return switch (status) {
            case PENDING -> ResourceMetadata.ProcessStatus.PENDING;
            case CRAWLED -> ResourceMetadata.ProcessStatus.CRAWLED;
            case EMBEDDED -> ResourceMetadata.ProcessStatus.EMBEDDED;
            case FAILED -> ResourceMetadata.ProcessStatus.FAILED;
            default -> throw new IllegalStateException("当前 DB 不支持状态: " + status);
        };
    }

    private static ResourceStatus fromProcessStatus(ResourceMetadata.ProcessStatus status) {
        if (status == null) {
            return ResourceStatus.PENDING;
        }
        return switch (status) {
            case PENDING -> ResourceStatus.PENDING;
            case CRAWLED -> ResourceStatus.CRAWLED;
            case EMBEDDED -> ResourceStatus.EMBEDDED;
            case FAILED -> ResourceStatus.FAILED;
        };
    }
}
