// 【宿主工具声明】定义 Windows 启动所需的控制台与字符串转换能力。
// 实现在 utils.cpp，调用方遵循返回值处理编码失败。

#ifndef RUNNER_UTILS_H_
#define RUNNER_UTILS_H_

#include <string>
#include <vector>

// 为进程创建控制台，并重定向宿主及 Flutter 的标准输出与错误输出。
void CreateAndAttachConsole();

// 将以空字符结尾的 UTF-16 字符串转换为 UTF-8，失败时返回空字符串。
std::string Utf8FromUtf16(const wchar_t* utf16_string);

// 读取 UTF-8 格式的启动参数，失败时返回空列表。
std::vector<std::string> GetCommandLineArguments();

#endif  // RUNNER_UTILS_H_
