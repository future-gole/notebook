package com.doublez.pocketmindserver.resource.application;

import com.doublez.pocketmindserver.dto.ResourceStatusDTO;
import com.doublez.pocketmindserver.dto.StatusRequest;
import com.doublez.pocketmindserver.dto.SubmitRequest;
import com.doublez.pocketmindserver.dto.SubmitResponse;
import com.doublez.pocketmindserver.event.CrawlerRequestEvent;
import com.doublez.pocketmindserver.model.ResourceMetadata;
import com.doublez.pocketmindserver.resource.domain.Resource;
import com.doublez.pocketmindserver.resource.domain.ResourceRepository;
import com.doublez.pocketmindserver.security.UserContext;
import com.doublez.pocketmindserver.service.CrawlerProducer;
import com.doublez.pocketmindserver.service.JinaReaderClient;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class ResourceApplicationService {

    private final ResourceRepository resourceRepository;
    private final CrawlerProducer crawlerProducer;
    private final JinaReaderClient jinaReaderClient;

    public ResourceApplicationService(
            ResourceRepository resourceRepository,
            CrawlerProducer crawlerProducer,
            JinaReaderClient jinaReaderClient
    ) {
        this.resourceRepository = resourceRepository;
        this.crawlerProducer = crawlerProducer;
        this.jinaReaderClient = jinaReaderClient;
    }

    public SubmitResponse submit(SubmitRequest request) {
        String userId = UserContext.getRequiredUserId();

        UUID id = UUID.randomUUID();
        Resource resource = Resource.create(id, userId, request.url());
        resourceRepository.save(resource);

        try {
            crawlerProducer.sendCrawlerRequest(new CrawlerRequestEvent(id, request.url(), userId));
        } catch (Exception e) {
            resource.markFailed();
            resourceRepository.update(resource);
            throw e;
        }

        return new SubmitResponse(id);
    }

    public List<ResourceStatusDTO> checkStatus(StatusRequest request) {
        String userId = UserContext.getRequiredUserId();
        return resourceRepository.findByIdsAndUserId(request.uuids(), userId).stream()
                .map(r -> new ResourceStatusDTO(
                        r.getId(),
                        r.getTitle(),
                        r.getContentMarkdown(),
                        r.getAiSummary(),
                        ResourceMetadata.ProcessStatus.valueOf(r.getStatus().name())
                ))
                .toList();
    }

    public void processCrawlerRequest(CrawlerRequestEvent event) {
        // userId 来自消息体，避免跨租户更新
        var resourceOpt = resourceRepository.findByIdAndUserId(event.uuid(), event.userId());
        if (resourceOpt.isEmpty()) {
            return;
        }

        Resource resource = resourceOpt.get();
        try {
            var response = jinaReaderClient.fetchContent(event.url());
            if (response.code() == 200 && response.data() != null) {
                resource.markCrawled(response.data().title(), response.data().content());
            } else {
                resource.markFailed();
            }
        } catch (Exception e) {
            resource.markFailed();
            throw e;
        } finally {
            resourceRepository.update(resource);
        }
    }
}
