package com.doublez.pocketmindserver.security;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "pocketmind.jwt")
public record JwtProperties(
        String secret,
        String userIdClaim,
        long leewaySeconds,
        long tokenTtlSeconds
) {
}
