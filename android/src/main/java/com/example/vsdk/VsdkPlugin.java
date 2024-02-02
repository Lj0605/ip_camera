package com.example.vsdk;

import android.content.Context;

import androidx.annotation.NonNull;

import com.veepai.app_player.AppPlayerPlugin;
import com.vstarcam.app_p2p_api.AppP2PApiPlugin;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
/*import com.tencent.bugly.crashreport.CrashReport;*/
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** VsdkPlugin */
public class VsdkPlugin implements FlutterPlugin, MethodCallHandler {

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
/*    CrashReport.initCrashReport(mContext, "weChatAppId", false);
    CrashReport.putUserData(mContext, "BuglyVersion", CrashReport.getBuglyVersion(mContext));*/
    AppP2PApiPlugin plugin = new AppP2PApiPlugin();
    plugin.onAttachedToEngine(flutterPluginBinding);
    AppPlayerPlugin playerPlugin = new AppPlayerPlugin();
    playerPlugin.onAttachedToEngine(flutterPluginBinding);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
  }
}
