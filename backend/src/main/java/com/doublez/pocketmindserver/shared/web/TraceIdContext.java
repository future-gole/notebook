package com.doublez.pocketmindserver.shared.web;

import org.slf4j.MDC;
import org.springframework.web.context.request.RequestAttributes;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import jakarta.servlet.http.HttpServletRequest;

/**
 * 统一获取 traceId（优先 request attribute，其次 MDC）
 */
public final class TraceIdContext {

    private TraceIdContext() {
    }

    public static String currentTraceId() {
        HttpServletRequest request = currentRequest();
        if (request != null) {
            Object value = request.getAttribute(TraceIdFilter.TRACE_ID_KEY);
            if (value != null) {
                return String.valueOf(value);
            }
        }
        String mdc = MDC.get(TraceIdFilter.TRACE_ID_KEY);
        return mdc == null ? "" : mdc;
    }

    private static HttpServletRequest currentRequest() {
        RequestAttributes attributes = RequestContextHolder.getRequestAttributes();
        if (attributes instanceof ServletRequestAttributes servletRequestAttributes) {
            return servletRequestAttributes.getRequest();
        }
        return null;
    }
}
