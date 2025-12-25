package com.doublez.pocketmindserver.dto;

import java.util.List;
import java.util.UUID;

public record StatusRequest(List<UUID> uuids) {}
