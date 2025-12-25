package com.doublez.pocketmindserver.shared.web;

public record ApiErrorResponse(
        String code,
        String message
) {
}
