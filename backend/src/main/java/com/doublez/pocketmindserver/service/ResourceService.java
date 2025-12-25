package com.doublez.pocketmindserver.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.doublez.pocketmindserver.dto.ResourceStatusDTO;
import com.doublez.pocketmindserver.dto.SubmitRequest;
import com.doublez.pocketmindserver.dto.SubmitResponse;
import com.doublez.pocketmindserver.model.ResourceMetadata;

import java.util.List;
import java.util.UUID;

public interface ResourceService extends IService<ResourceMetadata> {
    SubmitResponse submitResource(SubmitRequest request);
    List<ResourceStatusDTO> checkStatus(String userId, List<UUID> uuids);
}
