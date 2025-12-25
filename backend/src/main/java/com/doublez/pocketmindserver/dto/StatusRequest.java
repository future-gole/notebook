package com.doublez.pocketmindserver.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

import java.util.List;
import java.util.UUID;

public record StatusRequest(
	@NotEmpty(message = "uuids 不能为空")
	List<@NotNull(message = "uuid 不能为空") UUID> uuids
) {}
