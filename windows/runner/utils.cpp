#include "utils.h"
#include <flutter_windows.h>
#include <io.h>
#include <stdio.h>
#include <windows.h>
#include <iostream>
void CreateAndAttachConsole(){ if(!::AllocConsole()) return; FILE* unused; freopen_s(&unused,"CONOUT$","w",stdout); freopen_s(&unused,"CONOUT$","w",stderr); freopen_s(&unused,"CONIN$","r",stdin); std::ios::sync_with_stdio(); FlutterDesktopResyncOutputStreams(); }
std::vector<std::string> GetCommandLineArguments(){ int argc; wchar_t** argv=::CommandLineToArgvW(::GetCommandLineW(),&argc); if(argv==nullptr) return {}; std::vector<std::string> args; for(int i=1;i<argc;i++){ int size_needed=WideCharToMultiByte(CP_UTF8,0,argv[i],-1,nullptr,0,nullptr,nullptr); std::string utf8(size_needed,0); WideCharToMultiByte(CP_UTF8,0,argv[i],-1,utf8.data(),size_needed,nullptr,nullptr); args.push_back(utf8.substr(0,size_needed-1)); } LocalFree(argv); return args; }
