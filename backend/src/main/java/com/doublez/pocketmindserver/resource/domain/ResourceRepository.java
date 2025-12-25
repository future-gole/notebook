package com.doublez.pocketmindserver.resource.domain;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ResourceRepository {

    void save(Resource resource);

    void update(Resource resource);

    Optional<Resource> findByIdAndUserId(UUID id, String userId);

    List<Resource> findByIdsAndUserId(List<UUID> ids, String userId);

    /**
     * 根据 URL 查询资源（用于多用户复用的公共资源场景）。
     *
     * 注意：这里不做 userId 过滤，调用方需要确保只用于公开 URL 内容。
     */
    Optional<Resource> findLatestByUrl(String url);

    /**
     * 批量根据 URL 查询资源（用于多用户复用的公共资源场景）。
     *
     * 注意：这里不做 userId 过滤，调用方需要确保只用于公开 URL 内容。
     */
    List<Resource> findByUrls(List<String> urls);
}
