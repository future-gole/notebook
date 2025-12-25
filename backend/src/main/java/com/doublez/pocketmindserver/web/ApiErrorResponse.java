package com.doublez.pocketmindserver.web;

public record ApiErrorResponse(
        String code,
        String message
) {
}
