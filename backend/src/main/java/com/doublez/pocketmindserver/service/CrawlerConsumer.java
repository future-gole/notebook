package com.doublez.pocketmindserver.service;

import com.doublez.pocketmindserver.event.CrawlerRequestEvent;
import com.doublez.pocketmindserver.model.ResourceMetadata;
import com.doublez.pocketmindserver.repository.ResourceMetadataRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class CrawlerConsumer {

    private final JinaReaderClient jinaReaderClient;
    private final ResourceMetadataRepository repository;

    @RabbitListener(queues = "crawler_queue")
    public void handleCrawlerRequest(CrawlerRequestEvent event) {
        log.info("Processing crawler request for UUID: {}", event.uuid());

        try {
            // 1. Call Jina
            var response = jinaReaderClient.fetchContent(event.url());

            // 2. Update DB
            ResourceMetadata metadata = repository.selectById(event.uuid());
            if (metadata != null) {
                log.info("metadata: {}",metadata);
                if (response.code() == 200 && response.data() != null) {
                    metadata.setTitle(response.data().title());
                    metadata.setContentMarkdown(response.data().content());
                    metadata.setProcessStatus(ResourceMetadata.ProcessStatus.CRAWLED);
                    // TODO: Trigger Embedding/Analysis Event here
                } else {
                    metadata.setProcessStatus(ResourceMetadata.ProcessStatus.FAILED);
                    log.error("Jina failed for URL: {}", event.url());
                }
                repository.updateById(metadata);
            } else {
                log.warn("Metadata not found for UUID: {}", event.uuid());
            }

        } catch (Exception e) {
            log.error("Error processing crawler request", e);
            // Update status to FAILED
            ResourceMetadata metadata = repository.selectById(event.uuid());
            if (metadata != null) {
                metadata.setProcessStatus(ResourceMetadata.ProcessStatus.FAILED);
                repository.updateById(metadata);
            }
        }
    }
}
