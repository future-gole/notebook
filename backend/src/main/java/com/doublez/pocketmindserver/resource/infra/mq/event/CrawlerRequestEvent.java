package com.doublez.pocketmindserver.resource.infra.mq.event;

import java.io.Serializable;
import java.util.UUID;

public record CrawlerRequestEvent(
        UUID uuid,
        String url,
        String userId
) implements Serializable {}
