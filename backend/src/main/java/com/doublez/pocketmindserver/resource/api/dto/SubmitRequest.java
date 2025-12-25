package com.doublez.pocketmindserver.resource.api.dto;

import jakarta.validation.constraints.NotBlank;

public record SubmitRequest(
        @NotBlank(message = "url 不能为空")
        String url
) {
}
