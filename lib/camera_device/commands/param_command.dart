import 'dart:typed_data';

import 'package:vsdk/camera_device/commands/camera_command.dart';
import 'package:vsdk/p2p_device/p2p_command.dart';

class TimeParam {
  String? now;
  String? tz;

  // ignore: non_constant_identifier_names
  String? ntp_enable;

  // ignore: non_constant_identifier_names
  String? ntp_svr;

  TimeParam.from(Map data) {
    now = data["now"];
    tz = data["tz"];
    ntp_enable = data["ntp_enable"];
    ntp_svr = data["ntp_svr"];
  }
}

class NetworkParam {
  String? dhcpen;
  String? ip;
  String? mask;
  String? gateway;
  String? dns1;
  String? dns2;
  String? port;

  NetworkParam.from(Map data) {
    dhcpen = data["dhcpen"];
    ip = data["ip"];
    mask = data["mask"];
    gateway = data["gateway"];
    dns1 = data["dns1"];
    dns2 = data["dns2"];
    port = data["port"];
  }
}

class WiFiParam {
  // ignore: non_constant_identifier_names
  String? wifi_enable;

  // ignore: non_constant_identifier_names
  String? wifi_ssid;

  // ignore: non_constant_identifier_names
  String? wifi_mode;

  // ignore: non_constant_identifier_names
  String? wifi_encrypt;

  // ignore: non_constant_identifier_names
  String? wifi_authtype;

  // ignore: non_constant_identifier_names
  String? wifi_channel;

  WiFiParam.from(Map data) {
    wifi_enable = data["wifi_enable"];
    wifi_ssid = data["wifi_ssid"];
    wifi_mode = data["wifi_mode"];
    wifi_encrypt = data["wifi_encrypt"];
    wifi_authtype = data["wifi_authtype"];
    wifi_channel = data["wifi_channel"];
  }
}

class AlarmMotionParam {
  // ignore: non_constant_identifier_names
  String? alarm_motion_armed;

  // ignore: non_constant_identifier_names
  String? alarm_motion_sensitivity;

  String? cloudVideoDuration;

  AlarmMotionParam.from(Map data) {
    alarm_motion_armed = data["alarm_motion_armed"];
    alarm_motion_sensitivity = data["alarm_motion_sensitivity"];
    if (data.containsKey("CloudVideoDuration")) {
      cloudVideoDuration = data["CloudVideoDuration"];
    } else {
      cloudVideoDuration = "-1";
    }
  }
}

class ParamResult {
  bool? isSuccess;
  int? cmd;

  String? result;
  TimeParam? timeParam;
  NetworkParam? networkParam;
  WiFiParam? wifiParam;
  AlarmMotionParam? alarmMotionParam;

  Map? sourceData;

  ParamResult.form(CommandResult commandResult) {
    isSuccess = false;
    if (commandResult != null && commandResult.isSuccess == true) {
      isSuccess = true;
      cmd = commandResult.cmd;
      try {
        Map data = commandResult.getMap();
        sourceData = data;
        result = data["result"];
        timeParam = TimeParam.from(data);
        networkParam = NetworkParam.from(data);
        wifiParam = WiFiParam.from(data);
        alarmMotionParam = AlarmMotionParam.from(data);
      } catch (Exception) {}
    }
  }

  @override
  String toString() {
    return "$sourceData";
  }
}

mixin ParamsCommand on CameraCommand {
  ParamResult? paramResult;

  /// 获取设备参数
  /// @param [cache] 是否使用缓存,默认为true 使用缓存
  Future<ParamResult?> getParams({int timeout = 5, bool cache = true}) async {
    if (cache) {
      return paramResult;
    }
    bool ret = await writeCgi("get_params.cgi?", timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24578;
      }, timeout);
      if (result.isSuccess) {
        paramResult = ParamResult.form(result);
        return paramResult;
      }
    }
    return null;
  }

  Future<bool> left({int timeout = 5}) async {
    print("left ${left} decoder_control.cgi?command=4&onestep=1&");
    bool ret = await writeCgi("decoder_control.cgi?command=4&onestep=1&",
        timeout: timeout);
    print("left ${left} ");
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24601;
      }, timeout);
      return result.isSuccess;
    }
    return false;
  }

  /// 获取截图快照
  Future<bool> getSnapshot(String name, {int timeout = 5}) async {
    int time = DateTime.now().millisecondsSinceEpoch;
    bool ret = await writeCgi("snapshot.cgi?sensor=${name}&", timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24597;
      }, timeout);
      print(
          "getSnapshot result.isSuccess ${result.isSuccess}  result.data${result.data} ${result?.data?.length}");
      if (result.isSuccess && result.data != null && result.data!.length > 0) {
        ///return await _saveSnapshotFile(result.data, '${time}${"_"}{$name}');
        return true;
      }
    }
    return false;
  }
}
