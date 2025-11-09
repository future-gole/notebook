package com.doublez.pocketmindserver.model.response;

import com.fasterxml.jackson.annotation.JsonProperty;

public record ReportResponse<T>(

        /**
         * 线程ID，用于标识当前对话的唯一性
         */
        @JsonProperty("thread_id") String threadId,

        /**
         * 状态
         */
        @JsonProperty("status") String status,

        /**
         * 消息
         */
        @JsonProperty("message") String message,

        /**
         * 网址
         */
        @JsonProperty("url") String url,

        /**
         * 数据
         */
        @JsonProperty("report_information") T data) {
    public static <T> ReportResponse<T> success(String threadId, String message,String url, T data) {
        return new ReportResponse<>(threadId, "success", message, url, data);
    }

    public static <T> ReportResponse<T> notfound(String threadId, String message,String url) {
        return new ReportResponse<>(threadId, "notfound", message, url,null);
    }

    public static ReportResponse error(String threadId, String message,String url) {
        return new ReportResponse(threadId, "error", message, url, null);
    }
}