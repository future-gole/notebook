package com.doublez.pocketmindserver.analyse.infra.email;

public interface EmailService {

    void sendAnalyseResult(String toEmail, String threadId, String url, boolean success, String summary);
}
