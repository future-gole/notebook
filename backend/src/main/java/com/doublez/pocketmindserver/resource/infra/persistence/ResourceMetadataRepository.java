package com.doublez.pocketmindserver.resource.infra.persistence;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface ResourceMetadataRepository extends BaseMapper<ResourceMetadata> {
}
