#include "generated_plugin_registrant.h"
#include <file_picker/file_picker_windows.h>
void RegisterPlugins(flutter::PluginRegistry* registry) {
  FilePickerWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FilePickerWindows"));
}
