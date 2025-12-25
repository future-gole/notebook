package com.doublez.pocketmindserver.controller;

import com.doublez.pocketmindserver.dto.*;
import com.doublez.pocketmindserver.service.ResourceService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/resource")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ResourceController {

    private final ResourceService resourceService;

    @PostMapping("/submit")
    public ResponseEntity<?> submitResource(@RequestBody SubmitRequest request) {
        try {
            SubmitResponse response = resourceService.submitResource(request);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error submitting resource", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", e.getMessage(), "status", "500"));
        }
    }

    @PostMapping("/status")
    public ResponseEntity<?> checkStatus(@RequestBody StatusRequest request) {
        try {
            // TODO: Get real user ID
            String userId = "default_user";
            List<ResourceStatusDTO> statusList = resourceService.checkStatus(userId, request.uuids());
            return ResponseEntity.ok(statusList);
        } catch (Exception e) {
            log.error("Error checking status", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", e.getMessage(), "status", "500"));
        }
    }
}
