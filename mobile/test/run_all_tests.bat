@echo off
echo ========================================
echo PocketMind 移动端测试运行
echo ========================================
echo.

echo [1/9] URL Helper 测试...
call flutter test test\url_helper_test.dart --reporter=compact
if errorlevel 1 goto :error

echo.
echo [2/9] 颜色工具测试...
call flutter test test\category_colors_test.dart --reporter=compact
if errorlevel 1 goto :error

echo.
echo [3/9] 应用配置测试...
call flutter test test\app_config_test.dart --reporter=compact
if errorlevel 1 goto :error

echo.
echo [4/9] HTTP 客户端测试...
call flutter test test\http_client_test.dart --reporter=compact
if errorlevel 1 goto :error

echo.
echo [5/9] 链接预览测试...
call flutter test test\link_preview_test.dart --reporter=compact
if errorlevel 1 goto :error

echo.
echo [6/9] 导航项测试...
call flutter test test\nav_item_test.dart --reporter=compact
if errorlevel 1 goto :error

echo.
echo [7/9] 实体模型测试...
call flutter test test\entity_test.dart --reporter=compact
if errorlevel 1 goto :error

echo.
echo [8/9] 数据模型测试...
call flutter test test\model_test.dart --reporter=compact
if errorlevel 1 goto :error

echo.
echo [9/9] 集成测试...
call flutter test test\integration_test.dart --reporter=compact
if errorlevel 1 goto :error

echo.
echo ========================================
echo ✅ 所有测试通过！
echo ========================================
goto :end

:error
echo.
echo ========================================
echo ❌ 测试失败！
echo ========================================
exit /b 1

:end
