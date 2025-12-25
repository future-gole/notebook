package com.doublez.pocketmindserver.resource.application;

import com.doublez.pocketmindserver.resource.api.dto.ResourceStatusDTO;
import com.doublez.pocketmindserver.resource.api.dto.StatusRequest;
import com.doublez.pocketmindserver.resource.api.dto.SubmitRequest;
import com.doublez.pocketmindserver.resource.api.dto.SubmitResponse;
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

        // 同一个 URL 可能有多条记录（例如历史失败后重新提交），取 updatedAt 最新的一条
        // 这里没有 domain 的 updatedAt，所以退化为：同 URL 取任意一条（优先非 FAILED）
        Map<String, Resource> bestByUrl = resources.stream()
                .collect(Collectors.toMap(
                        Resource::getOriginalUrl,
                        Function.identity(),
                        (a, b) -> {
                            if (a.getStatus() == com.doublez.pocketmindserver.resource.domain.ResourceStatus.FAILED
                                    && b.getStatus() != com.doublez.pocketmindserver.resource.domain.ResourceStatus.FAILED) {
                                return b;
                            }
                            return a;
                        }
                ));

        return request.urls().stream()
                .map(url -> {
                    Resource r = bestByUrl.get(url);
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

    private ResourceMetadata.ProcessStatus mapToProcessStatus(com.doublez.pocketmindserver.resource.domain.ResourceStatus status) {
        // 兼容 domain 扩展状态，避免 valueOf 直接抛异常
        return switch (status) {
            case PENDING -> ResourceMetadata.ProcessStatus.PENDING;
            case CRAWLED, EMBEDDING, ANALYZING, ANALYZED -> ResourceMetadata.ProcessStatus.CRAWLED;
            case EMBEDDED -> ResourceMetadata.ProcessStatus.EMBEDDED;
            case FAILED -> ResourceMetadata.ProcessStatus.FAILED;
        };
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

