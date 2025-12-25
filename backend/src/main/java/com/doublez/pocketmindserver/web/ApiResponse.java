package com.doublez.pocketmindserver.web;

/**
 * 统一响应结构
 *
 * @param code    业务码
 * @param message 提示信息
 * @param data    数据
 * @param traceId 链路追踪ID
 */
public record ApiResponse<T>(
        int code,
        String message,
        T data,
        String traceId
) {

    public static <T> ApiResponse<T> ok(T data, String traceId) {
        return new ApiResponse<>(ApiCode.OK.code(), ApiCode.OK.defaultMessage(), data, traceId);
    }

    public static <T> ApiResponse<T> error(ApiCode code, T data, String traceId) {
        return new ApiResponse<>(code.code(), code.defaultMessage(), data, traceId);
    }

    public static ApiResponse<Void> error(ApiCode code, String traceId) {
        return error(code, null, traceId);
    }
}
