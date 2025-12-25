package com.doublez.pocketmindserver.repository;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.doublez.pocketmindserver.model.ResourceMetadata;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface ResourceMetadataRepository extends BaseMapper<ResourceMetadata> {
}
