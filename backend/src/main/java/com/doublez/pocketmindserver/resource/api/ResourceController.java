package com.doublez.pocketmindserver.resource.api;

import com.doublez.pocketmindserver.resource.api.dto.ResourceStatusDTO;
import com.doublez.pocketmindserver.resource.api.dto.StatusRequest;
import com.doublez.pocketmindserver.resource.api.dto.SubmitRequest;
import com.doublez.pocketmindserver.resource.api.dto.SubmitResponse;
import com.doublez.pocketmindserver.resource.application.ResourceApplicationService;
import com.doublez.pocketmindserver.resource.domain.ResourceStatus;
import com.doublez.pocketmindserver.shared.web.ApiCode;
import com.doublez.pocketmindserver.shared.web.BusinessException;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/resource")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class ResourceController {

    private final ResourceApplicationService resourceApplicationService;

    @PostMapping("/submit")
    public ResponseEntity<SubmitResponse> submitResource(@Valid @RequestBody SubmitRequest request) {
        SubmitResponse response = resourceApplicationService.submit(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/status")
    public ResponseEntity<List<ResourceStatusDTO>> checkStatus(@Valid @RequestBody StatusRequest request) {
        List<ResourceStatusDTO> statusList = resourceApplicationService.checkStatus(request);
        if (statusList.isEmpty()) {
            throw new BusinessException(ApiCode.RESOURCE_NOT_FOUND, HttpStatus.NOT_FOUND);
        }

        return ResponseEntity.ok(statusList);
    }
}
