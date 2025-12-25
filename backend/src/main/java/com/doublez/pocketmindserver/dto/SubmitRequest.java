package com.doublez.pocketmindserver.dto;

import jakarta.validation.constraints.NotBlank;

public record SubmitRequest(
	@NotBlank(message = "url 不能为空")
	String url
) {}
