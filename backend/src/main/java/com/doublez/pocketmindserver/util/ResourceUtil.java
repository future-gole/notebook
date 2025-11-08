package com.doublez.pocketmindserver.util;

import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;
import org.springframework.util.Assert;
import org.springframework.util.StreamUtils;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;

public class ResourceUtil {

    public static String loadResourceAsString(Resource resource) {
        Assert.notNull(resource, "resource cannot be null");
        try (InputStream inputStream = resource.getInputStream()) {
            var template = StreamUtils.copyToString(inputStream, Charset.defaultCharset());
            Assert.hasText(template, "template cannot be null or empty");
            return template;
        }
        catch (IOException e) {
            throw new RuntimeException("Failed to read resource", e);
        }
    }

    public static String loadFileContent(String filePath) {
        try {
            ClassPathResource resource = new ClassPathResource(filePath);
            try (InputStream inputStream = resource.getInputStream()) {
                return StreamUtils.copyToString(inputStream, StandardCharsets.UTF_8);
            }
        }
        catch (IOException e) {
            throw new RuntimeException("加载提示词文件失败: " + filePath, e);
        }
    }

}
