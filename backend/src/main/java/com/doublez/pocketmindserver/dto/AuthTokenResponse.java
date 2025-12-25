package com.doublez.pocketmindserver.dto;

public record AuthTokenResponse(
        String userId,
        String token,
        long expiresInSeconds
) {
}
