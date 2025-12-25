package com.doublez.pocketmindserver.resource.domain;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ResourceRepository {

    void save(Resource resource);

    void update(Resource resource);

    Optional<Resource> findByIdAndUserId(UUID id, String userId);

    List<Resource> findByIdsAndUserId(List<UUID> ids, String userId);
}
