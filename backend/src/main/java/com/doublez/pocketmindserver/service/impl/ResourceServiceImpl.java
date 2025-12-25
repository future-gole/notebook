package com.doublez.pocketmindserver.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.doublez.pocketmindserver.dto.ResourceStatusDTO;
import com.doublez.pocketmindserver.dto.SubmitRequest;
import com.doublez.pocketmindserver.dto.SubmitResponse;
import com.doublez.pocketmindserver.event.CrawlerRequestEvent;
import com.doublez.pocketmindserver.model.ResourceMetadata;
import com.doublez.pocketmindserver.repository.ResourceMetadataRepository;
import com.doublez.pocketmindserver.service.CrawlerProducer;
import com.doublez.pocketmindserver.service.ResourceService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class ResourceServiceImpl extends ServiceImpl<ResourceMetadataRepository, ResourceMetadata> implements ResourceService {

    private final CrawlerProducer crawlerProducer;

    @Override
    public SubmitResponse submitResource(SubmitRequest request) {
        // TODO: Get real user ID from security context
        String userId = "default_user";

        // 1. Create DB Entry
        ResourceMetadata metadata = new ResourceMetadata();
        metadata.setId(UUID.randomUUID()); // Ideally use UUIDv7 generator
        metadata.setUserId(userId);
        metadata.setOriginalUrl(request.url());
        metadata.setProcessStatus(ResourceMetadata.ProcessStatus.PENDING);
        
        log.info("Submitting new resource: {}", metadata);
        try {
            boolean saved = this.save(metadata);
            if (!saved) {
                throw new RuntimeException("Failed to save resource metadata to database");
            }
        } catch (Exception e) {
            log.error("Database error during resource submission", e);
            throw new RuntimeException("Database error: " + e.getMessage());
        }

        // 2. Send to Queue
        try {
            crawlerProducer.sendCrawlerRequest(new CrawlerRequestEvent(
                    metadata.getId(),
                    request.url(),
                    userId
            ));
            log.info("Sent crawler request for UUID: {}", metadata.getId());
        } catch (Exception e) {
            log.error("Failed to send crawler request to RabbitMQ", e);
            // Update status to FAILED if MQ fails
            metadata.setProcessStatus(ResourceMetadata.ProcessStatus.FAILED);
            this.updateById(metadata);
            throw new RuntimeException("Message Queue error: " + e.getMessage());
        }

        return new SubmitResponse(metadata.getId());
    }

    @Override
    public List<ResourceStatusDTO> checkStatus(String userId, List<UUID> uuids) {
        List<ResourceMetadata> resources = this.list(
                new LambdaQueryWrapper<ResourceMetadata>()
                        .eq(ResourceMetadata::getUserId, userId)
                        .in(ResourceMetadata::getId, uuids)
        );

        return resources.stream()
                .map(r -> new ResourceStatusDTO(
                        r.getId(),
                        r.getTitle(),
                        r.getContentMarkdown(),
                        r.getAiSummary(),
                        r.getProcessStatus()
                ))
                .collect(Collectors.toList());
    }
}
