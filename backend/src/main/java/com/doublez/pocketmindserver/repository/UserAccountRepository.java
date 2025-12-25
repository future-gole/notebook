package com.doublez.pocketmindserver.repository;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.doublez.pocketmindserver.model.UserAccount;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface UserAccountRepository extends BaseMapper<UserAccount> {
}
