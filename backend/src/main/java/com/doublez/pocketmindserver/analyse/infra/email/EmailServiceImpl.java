package com.doublez.pocketmindserver.analyse.infra.email;

import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Slf4j
@Service
public class EmailServiceImpl implements EmailService {

    private static final Logger logger = LoggerFactory.getLogger(EmailServiceImpl.class);

    @Resource
    private JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String fromEmail;

    @Override
    public void sendAnalyseResult(String toEmail, String threadId, String url, boolean success, String summary) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(toEmail);
            message.setSubject("网页分析结果");
            message.setText(
                    "threadId: " + threadId + "\n" +
                            "status: " + (success ? "success" : "error") + "\n" +
                            "url: " + url + "\n" +
                            "summary: " + summary
            );
            mailSender.send(message);
            logger.info("邮件已发送至: {}", toEmail);
        } catch (Exception e) {
            logger.error("发送邮件失败: {}", e.getMessage());
        }
    }
}
