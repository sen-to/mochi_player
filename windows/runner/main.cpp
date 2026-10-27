// 【应用宿主】启动共享 Flutter 引擎并提供 Windows 原生窗口操作。
// 通过视图 ID 路由窗口请求，COM 对话框与消息循环在宿主线程内完成。

#include <flutter/dart_project.h>
#include <flutter/flutter_engine.h>
#include <flutter_windows.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter/generated_plugin_registrant.h>
#include <windows.h>
#include <shobjidl.h>
#include <wrl/client.h>

#include "utils.h"

namespace {
using flutter::EncodableValue;
using flutter::EncodableMap;
const EncodableValue& Argument(const EncodableMap& args, const char* key) {
  return args.at(EncodableValue(key));
}
int64_t ViewId(const EncodableValue& value) {
  if (const auto* int32_value = std::get_if<int32_t>(&value)) return *int32_value;
  return std::get<int64_t>(value);
}

bool CheckWindowOperation(BOOL succeeded, const char* operation,
                          flutter::MethodResult<EncodableValue>* result) {
  if (succeeded) return true;
  const DWORD error = GetLastError();
  result->Error("window_operation_failed", operation,
                EncodableValue(static_cast<int64_t>(error)));
  return false;
}

bool ReadWindowStyle(HWND window, int index, LONG_PTR* style,
                     flutter::MethodResult<EncodableValue>* result) {
  SetLastError(ERROR_SUCCESS);
  *style = GetWindowLongPtr(window, index);
  if (*style != 0 || GetLastError() == ERROR_SUCCESS) return true;
  return CheckWindowOperation(FALSE, "GetWindowLongPtr", result);
}

std::wstring Utf16(const std::string& text) {
  const int length = MultiByteToWideChar(CP_UTF8, 0, text.data(), static_cast<int>(text.size()), nullptr, 0);
  std::wstring value(length, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, text.data(), static_cast<int>(text.size()), value.data(), length);
  return value;
}

void PickPath(HWND window, const EncodableMap& args,
              std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  Microsoft::WRL::ComPtr<IFileOpenDialog> dialog;
  HRESULT status = CoCreateInstance(CLSID_FileOpenDialog, nullptr, CLSCTX_INPROC_SERVER,
                                   IID_PPV_ARGS(dialog.GetAddressOf()));
  DWORD options = 0;
  const bool directory = std::get<bool>(Argument(args, "directory"));
  std::wstring filter_label, filter_pattern;
  if (SUCCEEDED(status)) status = dialog->GetOptions(&options);
  if (SUCCEEDED(status)) status = dialog->SetOptions(options | FOS_FORCEFILESYSTEM |
      (directory ? FOS_PICKFOLDERS : FOS_FILEMUSTEXIST));
  auto initial = args.find(EncodableValue("initialDirectory"));
  if (SUCCEEDED(status) && initial != args.end() && std::holds_alternative<std::string>(initial->second)) {
    Microsoft::WRL::ComPtr<IShellItem> folder;
    const auto path = Utf16(std::get<std::string>(initial->second));
    if (SUCCEEDED(SHCreateItemFromParsingName(path.c_str(), nullptr, IID_PPV_ARGS(folder.GetAddressOf())))) {
      status = dialog->SetFolder(folder.Get());
    }
  }
  if (SUCCEEDED(status) && !directory) {
    filter_label = Utf16(std::get<std::string>(Argument(args, "label")));
    for (const auto& extension : std::get<flutter::EncodableList>(Argument(args, "extensions"))) {
      if (!filter_pattern.empty()) filter_pattern += L";";
      filter_pattern += L"*." + Utf16(std::get<std::string>(extension));
    }
    const COMDLG_FILTERSPEC filter{filter_label.c_str(), filter_pattern.c_str()};
    status = dialog->SetFileTypes(1, &filter);
  }
  if (SUCCEEDED(status)) status = dialog->Show(window);
  if (status == HRESULT_FROM_WIN32(ERROR_CANCELLED)) { result->Success(); return; }
  Microsoft::WRL::ComPtr<IShellItem> selection;
  if (SUCCEEDED(status)) status = dialog->GetResult(selection.GetAddressOf());
  PWSTR path = nullptr;
  if (SUCCEEDED(status)) status = selection->GetDisplayName(SIGDN_FILESYSPATH, &path);
  if (SUCCEEDED(status)) {
    result->Success(EncodableValue(Utf8FromUtf16(path)));
  } else {
    result->Error("file_dialog_failed", "Could not show or read the native file dialog.");
  }
  CoTaskMemFree(path);
}
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t* command_line, _In_ int show_command) {
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  flutter::DartProject project(L"data");
  project.set_dart_entrypoint_arguments(GetCommandLineArguments());
  auto engine = std::make_shared<flutter::FlutterEngine>(project);
  RegisterPlugins(engine.get());
  auto registrar = engine->GetRegistrarForPlugin("MochiWindowControls");
  flutter::MethodChannel<EncodableValue> controls(
      engine->messenger(), "mochi_player/window_controls",
      &flutter::StandardMethodCodec::GetInstance());
  controls.SetMethodCallHandler([registrar](const auto& call, auto result) {
    const auto* args = call.arguments() ? std::get_if<EncodableMap>(call.arguments()) : nullptr;
    if (!args || args->count(EncodableValue("viewId")) == 0) {
      result->Error("invalid_arguments", "Expected a Flutter view ID.");
      return;
    }
    auto view = FlutterDesktopPluginRegistrarGetViewById(registrar, ViewId(Argument(*args, "viewId")));
    if (!view) {
      result->Error("window_missing", "Flutter view has no window.");
      return;
    }
    HWND window = GetAncestor(FlutterDesktopViewGetHWND(view), GA_ROOT);
    if (!CheckWindowOperation(window != nullptr, "GetAncestor", result.get())) return;
    const UINT dpi = FlutterDesktopGetDpiForHWND(window);
    if (!CheckWindowOperation(dpi != 0, "FlutterDesktopGetDpiForHWND", result.get())) return;
    const double scale = dpi / 96.0;
    const auto& method = call.method_name();
    if (method == "pickPath") {
      PickPath(window, *args, std::move(result));
      return;
    } else if (method == "startDragging") {
      ReleaseCapture();
      SendMessage(window, WM_NCLBUTTONDOWN, HTCAPTION, 0);
    } else if (method == "getBounds") {
      RECT rect;
      if (!CheckWindowOperation(GetClientRect(window, &rect), "GetClientRect", result.get())) return;
      POINT origin{0, 0};
      if (!CheckWindowOperation(ClientToScreen(window, &origin), "ClientToScreen", result.get())) return;
      result->Success(EncodableValue(flutter::EncodableList{
          EncodableValue(origin.x / scale), EncodableValue(origin.y / scale),
          EncodableValue((rect.right - rect.left) / scale),
          EncodableValue((rect.bottom - rect.top) / scale)}));
      return;
    } else if (method == "setBounds") {
      RECT rect{0, 0,
          static_cast<LONG>(std::get<double>(Argument(*args, "width")) * scale),
          static_cast<LONG>(std::get<double>(Argument(*args, "height")) * scale)};
      LONG_PTR style, extended_style;
      if (!ReadWindowStyle(window, GWL_STYLE, &style, result.get()) ||
          !ReadWindowStyle(window, GWL_EXSTYLE, &extended_style, result.get())) return;
      if (!CheckWindowOperation(
              AdjustWindowRectExForDpi(&rect, static_cast<DWORD>(style), FALSE,
                                      static_cast<DWORD>(extended_style), dpi),
              "AdjustWindowRectExForDpi", result.get())) return;
      if (!CheckWindowOperation(
              SetWindowPos(window, nullptr,
                  static_cast<int>(std::get<double>(Argument(*args, "x")) * scale) + rect.left,
                  static_cast<int>(std::get<double>(Argument(*args, "y")) * scale) + rect.top,
                  rect.right - rect.left, rect.bottom - rect.top, SWP_NOZORDER | SWP_NOACTIVATE),
              "SetWindowPos", result.get())) return;
    } else if (method == "isAlwaysOnTop") {
      LONG_PTR style;
      if (!ReadWindowStyle(window, GWL_EXSTYLE, &style, result.get())) return;
      result->Success(EncodableValue((style & WS_EX_TOPMOST) != 0));
      return;
    } else if (method == "setAlwaysOnTop") {
      if (!CheckWindowOperation(
              SetWindowPos(window, std::get<bool>(Argument(*args, "enabled")) ? HWND_TOPMOST : HWND_NOTOPMOST,
                           0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE),
              "SetWindowPos", result.get())) return;
    } else {
      result->NotImplemented();
      return;
    }
    result->Success();
  });
  if (!engine->Run()) return EXIT_FAILURE;
  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }
  ::CoUninitialize();
  return EXIT_SUCCESS;
}
