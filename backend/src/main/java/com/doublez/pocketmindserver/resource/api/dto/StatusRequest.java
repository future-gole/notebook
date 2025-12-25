package com.doublez.pocketmindserver.resource.api.dto;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotBlank;

import java.util.List;

public record StatusRequest(
        @NotEmpty(message = "urls 不能为空")
        List<@NotBlank(message = "url 不能为空") String> urls
) {
}
