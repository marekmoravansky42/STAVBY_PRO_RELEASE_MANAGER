#include "win32_window.h"
#include <flutter_windows.h>
#include <propkey.h>
#include <propvarutil.h>
#include "resource.h"
#include <shobjidl_core.h>
namespace { constexpr const wchar_t kWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW"; constexpr const wchar_t kRegistryPath[] = L"Software\\Microsoft\\Windows\\DWM"; constexpr const wchar_t kRegistryKey[] = L"AppsUseLightTheme"; }

namespace {
void SetTaskbarIdentityAndIcon(HWND window) {
  IPropertyStore* properties = nullptr;
  if (FAILED(SHGetPropertyStoreForWindow(window, IID_PPV_ARGS(&properties)))) {
    return;
  }

  wchar_t executable_path[MAX_PATH]{};
  if (GetModuleFileName(nullptr, executable_path, MAX_PATH) > 0) {
    const std::wstring executable(executable_path);
    const auto separator = executable.find_last_of(L"\\/");
    std::wstring icon_resource = executable + L",-101";
    if (separator != std::wstring::npos) {
      const std::wstring packaged_icon =
          executable.substr(0, separator + 1) + L"app_icon.ico";
      if (GetFileAttributes(packaged_icon.c_str()) != INVALID_FILE_ATTRIBUTES) {
        icon_resource = packaged_icon + L",0";
      }
    }
    PROPVARIANT icon_value{};
    if (SUCCEEDED(InitPropVariantFromString(icon_resource.c_str(), &icon_value))) {
      properties->SetValue(PKEY_AppUserModel_RelaunchIconResource, icon_value);
      PropVariantClear(&icon_value);
    }
  }

  PROPVARIANT app_id{};
  if (SUCCEEDED(InitPropVariantFromString(L"STAVBY.PRO.ReleaseManager", &app_id))) {
    properties->SetValue(PKEY_AppUserModel_ID, app_id);
    PropVariantClear(&app_id);
  }
  properties->Commit();
  properties->Release();
}
}  // namespace
Win32Window::Win32Window() {}
Win32Window::~Win32Window() { Destroy(); }
bool Win32Window::Create(const std::wstring& title, const Point& origin, const Size& size) {
  Destroy();
  WNDCLASS window_class{};
  window_class.hCursor = LoadCursor(nullptr, IDC_ARROW);
  window_class.lpszClassName = kWindowClassName;
  window_class.style = CS_HREDRAW | CS_VREDRAW;
  window_class.cbClsExtra = 0;
  window_class.cbWndExtra = 0;
  window_class.hInstance = GetModuleHandle(nullptr);
  window_class.hIcon = static_cast<HICON>(LoadImage(
      window_class.hInstance, MAKEINTRESOURCE(IDI_APP_ICON), IMAGE_ICON, 0,
      0, LR_DEFAULTSIZE | LR_SHARED));
  window_class.hbrBackground = 0;
  window_class.lpszMenuName = nullptr;
  window_class.lpfnWndProc = Win32Window::WndProc;
  RegisterClass(&window_class);
  window_handle_ = CreateWindow(
      kWindowClassName, title.c_str(), WS_OVERLAPPEDWINDOW, origin.x, origin.y,
      size.width, size.height, nullptr, nullptr, GetModuleHandle(nullptr), this);
  if (window_handle_ && window_class.hIcon) {
    SendMessage(window_handle_, WM_SETICON, ICON_BIG,
                reinterpret_cast<LPARAM>(window_class.hIcon));
    SendMessage(window_handle_, WM_SETICON, ICON_SMALL,
                reinterpret_cast<LPARAM>(window_class.hIcon));
  }
  if (window_handle_) SetTaskbarIdentityAndIcon(window_handle_);
  return window_handle_ && OnCreate();
}
bool Win32Window::Show(){ return ShowWindow(window_handle_,SW_SHOWNORMAL); }
void Win32Window::Destroy(){ OnDestroy(); if(window_handle_){DestroyWindow(window_handle_);window_handle_=nullptr;} UnregisterClass(kWindowClassName,nullptr); }
void Win32Window::SetChildContent(HWND content){ child_content_=content; SetParent(content,window_handle_); RECT frame=GetClientArea(); MoveWindow(content,frame.left,frame.top,frame.right-frame.left,frame.bottom-frame.top,true); SetFocus(child_content_); }
void Win32Window::SetQuitOnClose(bool q){quit_on_close_=q;} HWND Win32Window::GetHandle(){return window_handle_;} RECT Win32Window::GetClientArea(){RECT frame;GetClientRect(window_handle_,&frame);return frame;}
bool Win32Window::OnCreate(){return true;} void Win32Window::OnDestroy(){}
LRESULT Win32Window::MessageHandler(HWND window, UINT const message, WPARAM const wparam, LPARAM const lparam) noexcept { switch(message){case WM_DESTROY: window_handle_=nullptr; if(quit_on_close_) PostQuitMessage(0); return 0; case WM_SIZE: if(child_content_){RECT frame=GetClientArea();MoveWindow(child_content_,frame.left,frame.top,frame.right-frame.left,frame.bottom-frame.top,true);} return 0; case WM_ACTIVATE: if(child_content_) SetFocus(child_content_); return 0;} return DefWindowProc(window,message,wparam,lparam); }
LRESULT CALLBACK Win32Window::WndProc(HWND const window, UINT const message, WPARAM const wparam, LPARAM const lparam) noexcept { if(message==WM_NCCREATE){auto window_struct=reinterpret_cast<CREATESTRUCT*>(lparam);SetWindowLongPtr(window,GWLP_USERDATA,reinterpret_cast<LONG_PTR>(window_struct->lpCreateParams));auto that=static_cast<Win32Window*>(window_struct->lpCreateParams);EnableNonClientDpiScaling(window);that->window_handle_=window;} else if(Win32Window* that=GetThisFromHandle(window)){return that->MessageHandler(window,message,wparam,lparam);} return DefWindowProc(window,message,wparam,lparam); }
Win32Window* Win32Window::GetThisFromHandle(HWND const window) noexcept { return reinterpret_cast<Win32Window*>(GetWindowLongPtr(window,GWLP_USERDATA)); }
