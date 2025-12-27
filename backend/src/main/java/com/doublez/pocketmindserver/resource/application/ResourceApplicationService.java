package com.doublez.pocketmindserver.resource.application;

import com.doublez.pocketmindserver.resource.api.dto.ResourceStatusDTO;
import com.doublez.pocketmindserver.resource.api.dto.StatusRequest;
import com.doublez.pocketmindserver.resource.api.dto.SubmitRequest;
import com.doublez.pocketmindserver.resource.api.dto.SubmitResponse;
import com.doublez.pocketmindserver.resource.domain.ResourceStatus;
import com.doublez.pocketmindserver.resource.infra.mq.event.CrawlerRequestEvent;
import com.doublez.pocketmindserver.resource.infra.persistence.ResourceMetadata;
import com.doublez.pocketmindserver.resource.domain.Resource;
import com.doublez.pocketmindserver.resource.domain.ResourceRepository;
import com.doublez.pocketmindserver.shared.security.UserContext;
import com.doublez.pocketmindserver.resource.infra.mq.CrawlerProducer;
import com.doublez.pocketmindserver.resource.infra.http.JinaReaderClient;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

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

        // URL 内容复用：如果已有成功/处理中资源，直接复用，不重复投递抓取任务
        var existing = resourceRepository.findLatestByUrl(request.url());
        if (existing.isPresent() && existing.get().getStatus() != com.doublez.pocketmindserver.resource.domain.ResourceStatus.FAILED) {
            return new SubmitResponse(existing.get().getId());
        }

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
        UserContext.getRequiredUserId();

        // URL 维度查询：同一 URL 多用户可复用
        List<Resource> resources = resourceRepository.findByUrls(request.urls());
        if (resources.isEmpty()) {
            return List.of();
        }

        // 1. 一个url只会有一个记录，不会有多个
        Map<String, Resource> resourceMap = resources.stream()
                .collect(Collectors.toMap(Resource::getOriginalUrl, Function.identity(), (a, b) -> a));

        return request.urls().stream()
                .map(url -> {
                    Resource r = resourceMap.get(url);
                    // 2. 如果无记录返回错误码 (这里返回null，由Controller判断空列表抛出异常)
                    // 如果有记录且为fail 那么还是返回正常状态码
                    if (r == null) {
                        return null;
                    }
                    return new ResourceStatusDTO(
                            r.getOriginalUrl(),
                            r.getId(),
                            r.getTitle(),
                            r.getContentMarkdown(),
                            r.getAiSummary(),
                            mapToProcessStatus(r.getStatus())
                    );
                })
                .filter(v -> v != null)
                .toList();
    }

    private ResourceStatus mapToProcessStatus(ResourceStatus status) {
        // 兼容 domain 扩展状态，避免 valueOf 直接抛异常
        return switch (status) {
            case PENDING -> ResourceStatus.PENDING;
            case CRAWLED, EMBEDDING, ANALYZING, ANALYZED -> ResourceStatus.CRAWLED;
            case EMBEDDED -> ResourceStatus.EMBEDDED;
            case FAILED -> ResourceStatus.FAILED;
        };
    }

    public void processCrawlerRequest(CrawlerRequestEvent event) {
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

