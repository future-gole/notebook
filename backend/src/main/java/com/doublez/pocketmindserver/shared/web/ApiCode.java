package com.doublez.pocketmindserver.shared.web;

/**
 * 统一业务码（数字）与默认提示文案映射
 */
public enum ApiCode {

    OK(0, "success"),

    REQ_VALIDATION(400001, "参数校验失败"),

    AUTH_UNAUTHORIZED(401001, "未授权"),
    AUTH_BAD_CREDENTIALS(401002, "用户名或密码错误"),
    AUTH_USERNAME_EXISTS(409001, "用户名已存在"),

    AUTH_REGISTER_FAILED(500101, "注册失败"),
    INTERNAL_ERROR(500000, "服务器内部错误");

    private final int code;
    private final String defaultMessage;

    ApiCode(int code, String defaultMessage) {
        this.code = code;
        this.defaultMessage = defaultMessage;
    }

    public int code() {
        return code;
    }

    public String defaultMessage() {
        return defaultMessage;
    }
}
