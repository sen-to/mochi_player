//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import dart_smb2
import media_kit_libs_macos_video
import package_info_plus
import shared_preferences_foundation
import sqflite_darwin
import wakelock_plus
import media_kit_video

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  DartSmb2Plugin.register(with: registry.registrar(forPlugin: "DartSmb2Plugin"))
  MediaKitLibsMacosVideoPlugin.register(with: registry.registrar(forPlugin: "MediaKitLibsMacosVideoPlugin"))
  FPPPackageInfoPlusPlugin.register(with: registry.registrar(forPlugin: "FPPPackageInfoPlusPlugin"))
  SharedPreferencesPlugin.register(with: registry.registrar(forPlugin: "SharedPreferencesPlugin"))
  SqflitePlugin.register(with: registry.registrar(forPlugin: "SqflitePlugin"))
  WakelockPlusMacosPlugin.register(with: registry.registrar(forPlugin: "WakelockPlusMacosPlugin"))
  MediaKitVideoPlugin.register(with: registry.registrar(forPlugin: "MediaKitVideoPlugin"))
}
