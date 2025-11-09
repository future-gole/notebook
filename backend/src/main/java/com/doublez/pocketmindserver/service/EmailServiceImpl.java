package com.doublez.pocketmindserver.service;

import com.doublez.pocketmindserver.model.response.ReportResponse;
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
public class EmailServiceImpl {
    private static final Logger logger = LoggerFactory.getLogger(EmailServiceImpl.class);
    @Resource
    private JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String fromEmail;

    //发送邮箱
    public void sendEmail(String toEmail, ReportResponse<?> response) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(toEmail);
            message.setSubject("网页分析结果");
            message.setText("分析结果" + response.status() + "\n" +
                    "网址: " + response.url() + "\n" +
                    "数据: " + response.data().toString());
            mailSender.send(message);
            logger.info("邮件已发送至: {}", toEmail);
        } catch (Exception e) {
            logger.error("发送邮件失败: {}", e.getMessage());
        }
    }
}
