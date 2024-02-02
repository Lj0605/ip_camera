import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:vsdk/camera_device/commands/status_command.dart';
import 'package:vsdk/p2p_device/p2p_command.dart';
import 'package:vsdk/p2p_device/p2p_connect.dart';
import 'package:vsdk/p2p_device/p2p_device.dart';
import 'package:path_provider/path_provider.dart';

mixin CameraCommand on P2PBasisDevice, P2PConnect, P2PCommand, StatusCommand {
  @override
  Future<StatusResult?> getStatus({int timeout = 5, bool cache = true}) async {
    StatusResult? result =
        await super.getStatus(timeout: timeout, cache: cache);
    if (result != null) {
      await cameraCommand(result);
      if (result.sys_ver != null) {
        if (result.sys_ver!.startsWith('48.')) {
          if (sirenCommand != null) {
            bool bl = await sirenCommand!.getLightSirenMode();
            if (bl == true) {
              if (sirenCommand!.sirenMode == true) {
                await sirenCommand!.controlSirenMode(false);
              }
            }
          }
        }
      }
    }
    return result;
  }

  Future<void> cameraCommand(StatusResult result) async {
    if (result.haveMotor == "1" && motorCommand == null) {
      motorCommand = MotorCommand(this);
    }
    int? supportMode = int.tryParse(result.hardwareTestFunc ?? "");
    if (supportMode != null &&
        supportMode & 0x04 != 0 &&
        lightCommand == null) {
      lightCommand = LightCommand(this);
    }

    //预置位巡航计划、巡航线
    if (result.support_presetCruise == "1" && presetCruiseCommand == null) {
      presetCruiseCommand = PresetCruiseCommand(this);
    }

    //红蓝灯
    if (supportMode != null &&
        supportMode & 0x0A != 0 &&
        redBlueLightCommand == null) {
      redBlueLightCommand = RedBlueLightCommand(this);
    }

    if (supportMode != null &&
        supportMode & 0x08 != 0 &&
        sirenCommand == null) {
      sirenCommand = SirenCommand(this);
    }
    if (result.haveWifi == "1" && wifiCommand == null) {
      wifiCommand = WifiCommand(this);
    }
    if (result.support_led_hidden_mode == "1" && ledCommand == null) {
      ledCommand = LedCommand(this);
    }
    if (result.support_low_power != null &&
        result.support_low_power != "0" &&
        powerCommand == null) {
      powerCommand = PowerCommand(this);
    }
    if (((result.support_mode_switch != null &&
                result.support_mode_switch != "0") ||
            ["3", "4", "5", "6"].contains(result.support_low_power)) &&
        dvrCommand == null) {
      dvrCommand = DVRCommand(this);
    }
    if (result.support_4G_module != null &&
        result.support_4G_module != "0" &&
        mobileCommand == null) {
      mobileCommand = MobileCommand(this);
      mobileCommand!.getMobileInfo();
    }
    if (passwordCommand == null) {
      passwordCommand = PasswordCommand(this, result);
    }

    if (multipleZoomCommand == null) {
      multipleZoomCommand = MultipleZoomCommand(this);
    }

    if (result.support_privacy_pos != null &&
        int.tryParse(result.support_privacy_pos!)! > 0 &&
        privacyPositionCommand == null) {
      privacyPositionCommand = PrivacyPositionCommand(this);
    }

    if (result.support_Remote_PowerOnOff_Switch != null &&
        int.tryParse(result.support_Remote_PowerOnOff_Switch!)! > 0 &&
        powerSwitchCommand == null) {
      powerSwitchCommand = PowerSwitchCommand(this);
    }

    if (result.support_WiFi_Enhanced_Mode != null &&
        int.tryParse(result.support_WiFi_Enhanced_Mode!)! > 0 &&
        wifiEnhancedModeCommand == null) {
      wifiEnhancedModeCommand = WifiEnhancedModeCommand(this);
    }

    //支持新的定时白光灯/红外灯控制
    if (result.support_WhiteLed_Ctrl != null &&
        int.tryParse(result.support_WhiteLed_Ctrl!)! > 0 &&
        whiteLedCommand == null) {
      whiteLedCommand = WhiteLedCommand(this);
    }

    //检测间隔
    if (result.support_SleepCheckInterval != null &&
        int.tryParse(result.support_SleepCheckInterval!)! > 0 &&
        checkIntervalCommand == null) {
      checkIntervalCommand = CheckIntervalCommand(this);
    }

    //徘徊检测
    if (result.support_LingerCheck != null &&
        int.tryParse(result.support_LingerCheck!)! > 0 &&
        checkIntervalCommand == null) {
      checkIntervalCommand = CheckIntervalCommand(this);
    }

    //门铃解除防拆报警
    if (result.support_tamper_setting != null &&
        int.tryParse(result.support_tamper_setting!)! > 0 &&
        dismantleCommand == null) {
      dismantleCommand = DismantleCommand(this);
    }

    //tf录像分辨率切换
    if (result.support_record_resolution_switch != null &&
        int.tryParse(result.support_record_resolution_switch!)! > 0 &&
        recordResolutionCommand == null) {
      recordResolutionCommand = RecordResolutionCommand(this);
    }

    if ((result.support_pininpic != null &&
                int.tryParse(result.support_pininpic!)! > 0 ||
            result.support_mutil_sensor_stream != null &&
                int.tryParse(result.support_mutil_sensor_stream!)! > 0) &&
        qiangQiuCommand == null) {
      qiangQiuCommand = QiangQiuCommand(this);
    }
  }

  Future<bool> updateOwnerPassword(String userId, String password,
      {int timeout = 5}) async {
    bool ret = await writeCgi(
        "set_users.cgi?pwd_change_realtime=1&OwnerUser=$userId&OwnerPwd=$password&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24590;
      }, timeout);
      if (result.isSuccess) {
        return true;
      }
    }
    return false;
  }

  Future<bool> updateAdminPassword(String password,
      {required int userid, int timeout = 5}) async {
    bool ret = await writeCgi(
        "set_users.cgi?pwd_change_realtime=1&user3=admin&pwd3=$password&app_id=${userid}&",
        timeout: timeout,
        needLogin: false);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24590;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();

        return data["result"] == "0";
      }
    }
    return false;
  }

  /// 重启指令
  Future<bool> reboot({int timeout = 5}) async {
    bool ret = await writeCgi("reboot.cgi?", timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24615;
      }, timeout);
      if (result.isSuccess) {
        return true;
      }
    }
    return false;
  }

  /// 重置指令
  Future<bool> restoreFactory({int timeout = 5}) async {
    bool ret = await writeCgi("restore_factory.cgi&", timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return true;
      }, timeout);
      if (result.isSuccess) {
        return true;
      }
    }
    return false;
  }

  /// 云存储授权
  Future<bool> updatePushUser({int timeout = 5}) async {
    bool ret = await writeCgi("set_update_push_user.cgi?", timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return true;
      }, timeout);
      if (result.isSuccess) {
        return true;
      }
    }
    return false;
  }

  Future<bool> updateDateTime({int timeout = 5}) async {
    DateTime now = DateTime.now();
    int tz = now.timeZoneOffset.inSeconds;
    bool ret = await writeCgi(
        "set_datetime.cgi?tz=${-tz}&ntp_enable=1&ntp_svr=time.windows.com&now=${(now.millisecondsSinceEpoch / 1000).floor()}&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24595;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        return data["result"] == "0";
      }
    }
    return false;
  }

  ///修改水印时间格式
  Future<bool> changeDateTimeType(int value, {int timeout = 5}) async {
    if (value == null) {
      return false;
    }
    bool ret = await writeCgi("camera_control.cgi?param=34&value=$value&");
    if (ret == true) {
      CommandResult result = await waitCommandResult((cmd, data) {
        return cmd == 24594;
      }, timeout);
      return result.isSuccess;
    }
    return false;
  }

  Future<bool> updateFirmware(String server, String file,
      {int timeout = 5}) async {
    bool ret = await writeCgi(
        "auto_download_file.cgi?server=$server&file=$file&type=0&resevered1=&resevered2=&resevered3=&resevered4=&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24578;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        return data["result"] == "0";
      }
    }
    return false;
  }

  ///app版本号传给固件
  Future<bool> setAppVersionOemId(
      String appOemid, String appVersion, int aacSupport,
      {int timeout = 5}) async {
    bool ret = await writeCgi(
        "set_users.cgi?app_oemid=$appOemid&app_version=$appVersion&aac_support=$aacSupport&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24578;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        return data["result"] == "0";
      }
    }
    return false;
  }

  ///修改设备名字
  Future<bool> setDeviceName(String name, {int timeout = 5}) async {
    bool ret = await writeCgi("set_alias.cgi?alias=$name&", timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24591;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        return data["result"] == "0";
      }
    }
    return false;
  }

  ///双目切换镜头
  Future<bool> changeCameraLens(String value, {int timeout = 5}) async {
    bool ret = await writeCgi("camera_control.cgi?param=36&value=$value&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24594;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        return data["result"] == "0";
      }
    }
    return false;
  }

  MotorCommand? motorCommand;

  WifiCommand? wifiCommand;

  LedCommand? ledCommand;

  LightCommand? lightCommand;

  SirenCommand? sirenCommand;

  PowerCommand? powerCommand;

  DVRCommand? dvrCommand;

  MobileCommand? mobileCommand;

  PasswordCommand? passwordCommand;

  RedBlueLightCommand? redBlueLightCommand;

  MultipleZoomCommand? multipleZoomCommand;

  PrivacyPositionCommand? privacyPositionCommand;

  PowerSwitchCommand? powerSwitchCommand;

  WifiEnhancedModeCommand? wifiEnhancedModeCommand;

  WhiteLedCommand? whiteLedCommand;

  CheckIntervalCommand? checkIntervalCommand;

  DismantleCommand? dismantleCommand;

  RecordResolutionCommand? recordResolutionCommand;

  PresetCruiseCommand? presetCruiseCommand;

  QiangQiuCommand? qiangQiuCommand;
}

class PrivacyPositionCommand {
  final CameraCommand _command;

  PrivacyPositionCommand(this._command);

  bool? privacyFlag;

  //设备是否在隐私位置
  Future<bool> isDevicePrivacy({int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2013&command=2&posturn=1&",
        timeout: timeout);

    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2013;") && str.contains("command=2;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          privacyFlag = data["privacyflag"] == "1";
        }
        return data["result"] == "0";
      }
    }
    return false;
  }

  //进入或退出隐私位
  Future<bool> controlPrivacyPosStatus(bool value, {int timeout = 5}) async {
    var switchValue = value ? '1' : '3';
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2013&command=1&posturn=$switchValue&",
        timeout: timeout);

    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2013;") && str.contains("command=1;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        return data["result"] == "0";
      }
    }
    return false;
  }

  Map? privacyPlanData;

  Future<bool> getPrivacyPlan({int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2017&command=11&mark=212&type=6&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2017;") &&
              str.contains("command=11;") &&
              str.contains("type=6;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        if (data.containsKey("privacy_plan_enable")) {
          privacyPlanData = data;
        }
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> setPrivacyPlan(
      {required List records, required int enable, int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2017&command=6&mark=212&"
        "privacy_plan1=${records[0]}&"
        "privacy_plan2=${records[1]}&"
        "privacy_plan3=${records[2]}&"
        "privacy_plan4=${records[3]}&"
        "privacy_plan5=${records[4]}&"
        "privacy_plan6=${records[5]}&"
        "privacy_plan7=${records[6]}&"
        "privacy_plan8=${records[7]}&"
        "privacy_plan9=${records[8]}&"
        "privacy_plan10=${records[9]}&"
        "privacy_plan11=${records[10]}&"
        "privacy_plan12=${records[11]}&"
        "privacy_plan13=${records[12]}&"
        "privacy_plan14=${records[13]}&"
        "privacy_plan15=${records[14]}&"
        "privacy_plan16=${records[15]}&"
        "privacy_plan17=${records[16]}&"
        "privacy_plan18=${records[17]}&"
        "privacy_plan19=${records[18]}&"
        "privacy_plan20=${records[19]}&"
        "privacy_plan21=${records[20]}&"
        "privacy_plan_enable=$enable&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2017;") && str.contains("command=6;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        if (data["status"] == "0" || data["result"] == "0") {
          return true;
        }
      }
    }
    return false;
  }
}

class MultipleZoomCommand {
  final CameraCommand _command;

  MultipleZoomCommand(this._command);

  Future<bool> multipleZoomCommand(int scale, {int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "decoder_control.cgi?command=84&param=$scale&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24601;
      }, timeout);
      return result.isSuccess;
    }
    return false;
  }

  Future<bool> multipleZoom4XCommand(int scale, {int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "decoder_control.cgi?command=${scale + 20}&onestep=0&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24601;
      }, timeout);
      return result.isSuccess;
    }
    return false;
  }
}

//定时白光灯红外灯的控制
class WhiteLedCommand {
  final CameraCommand _command;

  WhiteLedCommand(this._command);

  int? whiteLed;
  int? ledTimes;
  int? mode;

  //设置白光灯参数 亮度 时长 模式
  Future<bool> controlWhiteLedValue(
      {int? whiteValue,
      int? timeValue,
      int? modeValue,
      int timeout = 5}) async {
    if (whiteValue == null && timeValue == null && modeValue == null) {
      return false;
    }

    bool? ret;

    if (whiteValue != null && timeValue == null && modeValue == null) {
      ret = await _command.writeCgi(
          "set_whiteled_value.cgi?whiteled=$whiteValue&",
          timeout: timeout);
    }

    if (whiteValue == null && timeValue != null && modeValue == null) {
      ret = await _command.writeCgi(
          "set_whiteled_value.cgi?ledtimes=$timeValue&",
          timeout: timeout);
    }

    if (whiteValue == null && timeValue == null && modeValue != null) {
      ret = await _command.writeCgi("set_whiteled_value.cgi?mode=$modeValue&",
          timeout: timeout);
    }

    if (whiteValue != null && timeValue != null && modeValue == null) {
      ret = await _command.writeCgi(
          "set_whiteled_value.cgi?whiteled=$whiteValue&ledtimes=$timeValue&",
          timeout: timeout);
    }

    if (whiteValue == null && timeValue != null && modeValue != null) {
      ret = await _command.writeCgi(
          "set_whiteled_value.cgi?ledtimes=$timeValue&mode=$modeValue&",
          timeout: timeout);
    }

    if (whiteValue != null && timeValue == null && modeValue != null) {
      ret = await _command.writeCgi(
          "set_whiteled_value.cgi?whiteled=$whiteValue&mode=$modeValue&",
          timeout: timeout);
    }

    if (whiteValue != null && timeValue != null && modeValue != null) {
      ret = await _command.writeCgi(
          "set_whiteled_value.cgi?whiteled=$whiteValue&ledtimes=$timeValue&mode=$modeValue&",
          timeout: timeout);
    }

    if (ret ?? false) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        return true;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        return data["result"] == "0";
      }
    }
    return false;
  }

  //获取白光灯参数 亮度 时长 模式
  Future<bool> getWhiteLedValue({int timeout = 5}) async {
    bool ret =
        await _command.writeCgi("get_whiteled_value.cgi?", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        return true;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        whiteLed = int.tryParse(data["whiteled"] ?? "0") ?? 0;
        ledTimes = int.tryParse(data["ledtimes"] ?? "0") ?? 0;
        // mode = int.tryParse(data["mode"]??'') ?? 0;
        return data["result"] == "0";
      }
    }
    return false;
  }

  //定时计划
  Map? whiteLedLightPlanData;

  Future<bool> getWhiteLedLightPlan({int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2017&command=11&mark=213&type=5&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2017;") && str.contains("command=11;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        if (data.containsKey("light_plan_enable")) {
          whiteLedLightPlanData = data;
        }
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> setWhiteLedLightPlan(
      {required List records, int enable = 1, int timeout = 5}) async {
    //计算enable和switch的值
    var enableValue = 0;
    var switchValue = 0;

    var enableList = [];
    var switchList = [];
    for (int i = 0; i <= 20; i++) {
      var tempEnable = records[i]['enable'];
      var tempSwitch = records[i]['onOff'];
      enableList.add(tempEnable);
      switchList.add(tempSwitch);
    }

    var enableString = enableList.reversed
        .toString()
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .replaceAll('(', '')
        .replaceAll(')', '');
    var switchSting = switchList.reversed
        .toString()
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .replaceAll('(', '')
        .replaceAll(')', '');

    enableValue = int.parse(enableString, radix: 2);
    switchValue = int.parse(switchSting, radix: 2);

    var commandString = "trans_cmd_string.cgi?cmd=2017&command=5&mark=213&"
        "light_plan1=${records[0]['content']}&"
        "light_plan2=${records[1]['content']}&"
        "light_plan3=${records[2]['content']}&"
        "light_plan4=${records[3]['content']}"
        "light_plan5=${records[4]['content']}&"
        "light_plan6=${records[5]['content']}&"
        "light_plan7=${records[6]['content']}&"
        "light_plan8=${records[7]['content']}&"
        "light_plan9=${records[8]['content']}&"
        "light_plan10=${records[9]['content']}&"
        "light_plan11=${records[10]['content']}&"
        "light_plan12=${records[11]['content']}&"
        "light_plan13=${records[12]['content']}&"
        "light_plan14=${records[13]['content']}&"
        "light_plan15=${records[14]['content']}&"
        "light_plan16=${records[15]['content']}&"
        "light_plan17=${records[16]['content']}&"
        "light_plan18=${records[17]['content']}&"
        "light_plan19=${records[18]['content']}&"
        "light_plan20=${records[19]['content']}&"
        "light_plan21=${records[20]['content']}&"
        "light_enable=$enableValue&"
        "light_switch=$switchValue&"
        "light_plan_enable=$enable&";

    // var commandString = "trans_cmd_string.cgi?cmd=2017&command=5&mark=213&"
    //     "light_plan1=${records[0]['content']}&enable1=${records[0]['enable']}&"
    //     "light_plan2=${records[1]['content']}&enable2=${records[1]['enable']}&"
    //     "light_plan3=${records[2]['content']}&enable3=${records[2]['enable']}&"
    //     "light_plan4=${records[3]['content']}&enable4=${records[3]['enable']}&"
    //     "light_plan5=${records[4]['content']}&enable5=${records[4]['enable']}&"
    //     "light_plan6=${records[5]['content']}&enable6=${records[5]['enable']}&"
    //     "light_plan7=${records[6]['content']}&enable7=${records[6]['enable']}&"
    //     "light_plan8=${records[7]['content']}&enable8=${records[7]['enable']}&"
    //     "light_plan9=${records[8]['content']}&enable9=${records[8]['enable']}&"
    //     "light_plan10=${records[9]['content']}&enable10=${records[9]['enable']}&"
    //     "light_plan11=${records[10]['content']}&enable11=${records[10]['enable']}&"
    //     "light_plan12=${records[11]['content']}&enable12=${records[11]['enable']}&"
    //     "light_plan13=${records[12]['content']}&enable13=${records[12]['enable']}&"
    //     "light_plan14=${records[13]['content']}&enable14=${records[13]['enable']}&"
    //     "light_plan15=${records[14]['content']}&enable15=${records[14]['enable']}&"
    //     "light_plan16=${records[15]['content']}&enable16=${records[15]['enable']}&"
    //     "light_plan17=${records[16]['content']}&enable17=${records[16]['enable']}&"
    //     "light_plan18=${records[17]['content']}&enable18=${records[17]['enable']}&"
    //     "light_plan19=${records[18]['content']}&enable19=${records[18]['enable']}&"
    //     "light_plan20=${records[19]['content']}&enable20=${records[19]['enable']}&"
    //     "light_plan21=${records[20]['content']}&enable21=${records[20]['enable']}&"
    //     "light_plan_enable=${enable}&";

    bool ret = await _command.writeCgi(commandString, timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2017;") && str.contains("command=5;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        if (data["status"] == "0") {
          return true;
        }
      }
    }
    return false;
  }
}

//预置位巡航线路
class PresetCruiseCommand {
  final CameraCommand _command;

  PresetCruiseCommand(this._command);

  Map? presetCruiseLineData;
  int? sumPreset;

  //获取路线
  Future<bool> getPresetCruiseLine({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("trans_cmd_string.cgi?cmd=2160&command=0&", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2160;") && str.contains("command=0;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        if (data.containsKey("sumPreset")) {
          presetCruiseLineData = data;
          sumPreset = int.tryParse(data['sumPreset']) ?? 0;
        }
        return data["result"] == "0";
      }
    }
    return false;
  }

  //设置路线
  Future<bool> setPresetCruiseLine(
      {required List records, int timeout = 5}) async {
    var cmdString = 'trans_cmd_string.cgi?cmd=2160&command=0&';
    if (records == null) {
      cmdString += 'sumPreset=0&';
    } else {
      cmdString += 'sumPreset=${records.length}&';

      for (int i = 0; i < records.length; i++) {
        var num = records[i]['num'];
        var speed = records[i]['speed'];
        var time = records[i]['time']; //停留时间

        var flag = i + 1;

        cmdString += 'preset${flag}_num=$num&';
        cmdString += 'preset${flag}_speed=$speed&';
        cmdString += 'preset${flag}_stoptime=$time&';
      }
    }

    bool ret = await _command.writeCgi(cmdString, timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2160;") && str.contains("command=0;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          return true;
        }
      }
    }
    return false;
  }

  //定时计划
  Map? presetCruisePlanData;
  int? presetCruisePlanEnable;

  Future<bool> getPresetCruisePlan({int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2017&command=11&mark=781698&type=10&status=0&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2017;") && str.contains("command=11;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        if (data.containsKey("preset_cruise_plan_enable")) {
          presetCruisePlanData = data;
          presetCruisePlanEnable =
              int.tryParse(data["preset_cruise_plan_enable"]) ?? 0;
        }
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> setPresetCruisePlan(
      {required List records, required int enable, int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2017&command=10&mark=781698&"
        "preset_cruise_plan1=${records[0]}&"
        "preset_cruise_plan2=${records[1]}&"
        "preset_cruise_plan3=${records[2]}&"
        "preset_cruise_plan4=${records[3]}&"
        "preset_cruise_plan5=${records[4]}&"
        "preset_cruise_plan6=${records[5]}&"
        "preset_cruise_plan7=${records[6]}&"
        "preset_cruise_plan8=${records[7]}&"
        "preset_cruise_plan9=${records[8]}&"
        "preset_cruise_plan10=${records[9]}&"
        "preset_cruise_plan11=${records[10]}&"
        "preset_cruise_plan12=${records[11]}&"
        "preset_cruise_plan13=${records[12]}&"
        "preset_cruise_plan14=${records[13]}&"
        "preset_cruise_plan15=${records[14]}&"
        "preset_cruise_plan16=${records[15]}&"
        "preset_cruise_plan17=${records[16]}&"
        "preset_cruise_plan18=${records[17]}&"
        "preset_cruise_plan19=${records[18]}&"
        "preset_cruise_plan20=${records[19]}&"
        "preset_cruise_plan21=${records[20]}&"
        "preset_cruise_plan_enable=$enable&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2017;") && str.contains("command=10;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          return true;
        }
      }
    }
    return false;
  }

  var presetCruiseLinePointsData; //已经设置预置位的数据
  //获取已设置的预置位
  Future<bool> getPresetCruiseLinePoints({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("trans_cmd_string.cgi?cmd=2161&command=0&", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2161;") && str.contains("command=0;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        presetCruiseLinePointsData = data;
        return data["result"] == "0";
      }
    }
    return false;
  }
}

///红蓝光指令
class RedBlueLightCommand {
  final CameraCommand _command;

  RedBlueLightCommand(this._command);

  bool? redBlueSwitch;
  bool? redBlueMode;

//手动
  Future<bool> getRedBlueLightStatus({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("trans_cmd_string.cgi?cmd=2109&command=2&", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2109;") && str.contains("command=2;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          redBlueSwitch = data["alarmLedStatus"] == "1";
        }
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> controlRedBlueLightStatus(int value, {int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2109&command=0&alarmLed=$value&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2109;") && str.contains("command=0;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          redBlueSwitch = data["alarmLedStatus"] == "1";
        }
        return data["result"] == "0";
      }
    }
    return false;
  }

  //报警
  Future<bool> getRedBlueLightMode({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("trans_cmd_string.cgi?cmd=2108&command=0&", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2108;") && str.contains("command=0;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          redBlueMode = data["alarmLedMode"] == "1";
        }
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> controlRedBlueLightMode(int mode, {int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2108&command=1&alarmLedMode=$mode&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2108;") && str.contains("command=1;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          redBlueMode = data["alarmLedMode"] == "1";
        }
        return data["result"] == "0";
      }
    }
    return false;
  }
}

/// 白光灯指令
class LightCommand {
  final CameraCommand _command;

  LightCommand(this._command);

  bool? lightSwitch;
  int? lightMode;

  Future<bool> controlLight(bool light, {int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2109&command=0&light=${light == true ? 1 : 0}&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2109;") && str.contains("command=0;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") lightSwitch = data["lightStatus"] == "1";
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> getLightState({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("trans_cmd_string.cgi?cmd=2109&command=2&", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2109;") && str.contains("command=2;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") lightSwitch = data["lightStatus"] == "1";
        return data["result"] == "0";
      }
    }
    return false;
  }

  ///get 白光灯模式  闪烁/不逛
  Future<bool> getLightSirenMode({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("trans_cmd_string.cgi?cmd=2108&command=0&", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2108;") && str.contains("command=0;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          lightMode = int.tryParse(data["lightMode"]) ?? 0;
        }
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> controlLightMode(int light, {int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2108&command=1&lightMode=$light&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2108;") && str.contains("command=1;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          lightMode = int.tryParse(data["lightMode"]) ?? 0;
        }
        return data["result"] == "0";
      }
    }
    return false;
  }
}

///远程一键开关机指令
class PowerSwitchCommand {
  final CameraCommand _command;

  PowerSwitchCommand(this._command);

  int? powerSwitch;

  Future<bool> controlPowerSwitch(int open, {int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2106&command=13&PowerSwitch=$open&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2106;") && str.contains("command=13;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          powerSwitch = int.tryParse(data["PowerSwitch"] ?? '0') ?? 0;
        }
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> getPowerSwitch({int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2106&command=14&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2106;") && str.contains("command=14;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          powerSwitch = int.tryParse(data["PowerSwitch"] ?? '0') ?? 0;
        }
        return data["result"] == "0";
      }
    }
    return false;
  }
}

///WiFi穿墙模式
class WifiEnhancedModeCommand {
  final CameraCommand _command;

  WifiEnhancedModeCommand(this._command);

  int? wifiEnhancedMode;

  Future<bool> controlWifiEnhancedMode(int open, {int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2106&command=15&WifiEnhancedMode=$open&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2106;") && str.contains("command=15;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          wifiEnhancedMode = int.tryParse(data["WifiEnhancedMode"] ?? '0') ?? 0;
        }
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> getWifiEnhancedMode({int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2106&command=16&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2106;") && str.contains("command=16;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          wifiEnhancedMode = int.tryParse(data["WifiEnhancedMode"] ?? '0') ?? 0;
        }
        return data["result"] == "0";
      }
    }
    return false;
  }
}

/// 警笛指令
class SirenCommand {
  final CameraCommand _command;

  SirenCommand(this._command);

  bool? sirenSwitch;

  bool? sirenMode;

  Future<bool> controlSiren(bool siren, {int timeout = 5}) async {
    print(
        "-----------controlSiren--------siren-$siren----_command-$_command---------");
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2109&command=0&siren=${siren == true ? 1 : 0}&",
        timeout: timeout);
    print("-----------ret--------$ret---------");
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2109;") && str.contains("command=0;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") sirenSwitch = data["sirenStatus"] == "1";
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> getSirenState({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("trans_cmd_string.cgi?cmd=2109&command=2&", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2109;") && str.contains("command=2;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") sirenSwitch = data["sirenStatus"] == "1";
        return data["result"] == "0";
      }
    }
    return false;
  }

  ///get 白光灯模式  闪烁/不逛
  Future<bool> getLightSirenMode({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("trans_cmd_string.cgi?cmd=2108&command=0&", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2108;") && str.contains("command=0;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          sirenMode = data["sirenMode"] == "1";
        }
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> controlSirenMode(bool siren, {int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2108&command=1&sirenMode=${siren == true ? 1 : 0}&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2108;") && str.contains("command=1;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          sirenMode = data["sirenMode"] == "1";
        }
        return data["result"] == "0";
      }
    }
    return false;
  }
}

/// 云台指令
class MotorCommand {
  final CameraCommand _command;

  MotorCommand(this._command);

  Future<bool> left({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("decoder_control.cgi?command=4&onestep=1&", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24601;
      }, timeout);
      return result.isSuccess;
    }
    return false;
  }

  Future<bool> right({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("decoder_control.cgi?command=6&onestep=1&", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24601;
      }, timeout);
      return result.isSuccess;
    }
    return false;
  }

  Future<bool> up({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("decoder_control.cgi?command=0&onestep=1&", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24601;
      }, timeout);
      return result.isSuccess;
    }
    return false;
  }

  Future<bool> down({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("decoder_control.cgi?command=2&onestep=1&", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24601;
      }, timeout);
      return result.isSuccess;
    }
    return false;
  }

  Future<bool> ptzCorrect({int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "decoder_control.cgi?command=25&onestep=0&",
        timeout: timeout);
    return ret;
  }

  Future<bool> startLeft(
      {int? currBinocular, int? motorSpeed, int timeout = 5}) async {
    String _cgi = "decoder_control.cgi?command=4&onestep=0&";
    if (currBinocular != null) {
      _cgi = _cgi + "curr_binocular=$currBinocular&";
    }
    if (motorSpeed != null) {
      _cgi = _cgi + "motor_speed=$motorSpeed&";
    }
    bool ret = await _command.writeCgi(_cgi, timeout: timeout);
    return ret;
  }

  Future<bool> startRight(
      {int? currBinocular, int? motorSpeed, int timeout = 5}) async {
    String _cgi = "decoder_control.cgi?command=6&onestep=0&";
    if (currBinocular != null) {
      _cgi = _cgi + "curr_binocular=$currBinocular&";
    }
    if (motorSpeed != null) {
      _cgi = _cgi + "motor_speed=$motorSpeed&";
    }
    bool ret = await _command.writeCgi(_cgi, timeout: timeout);
    return ret;
  }

  Future<bool> startUp(
      {int? currBinocular, int? motorSpeed, int timeout = 5}) async {
    String _cgi = "decoder_control.cgi?command=0&onestep=0&";
    if (currBinocular != null) {
      _cgi = _cgi + "curr_binocular=$currBinocular&";
    }
    if (motorSpeed != null) {
      _cgi = _cgi + "motor_speed=$motorSpeed&";
    }
    bool ret = await _command.writeCgi(_cgi, timeout: timeout);
    return ret;
  }

  Future<bool> startDown(
      {int? currBinocular, int? motorSpeed, int timeout = 5}) async {
    String _cgi = "decoder_control.cgi?command=2&onestep=0&";
    if (currBinocular != null) {
      _cgi = _cgi + "curr_binocular=$currBinocular&";
    }
    if (motorSpeed != null) {
      _cgi = _cgi + "motor_speed=$motorSpeed&";
    }
    bool ret = await _command.writeCgi(_cgi, timeout: timeout);
    return ret;
  }

  Future<bool> stopLeft({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("decoder_control.cgi?command=5&onestep=0&", timeout: timeout);
    return ret;
  }

  Future<bool> stopRight({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("decoder_control.cgi?command=7&onestep=0&", timeout: timeout);
    return ret;
  }

  Future<bool> stopUp({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("decoder_control.cgi?command=1&onestep=0&", timeout: timeout);
    return ret;
  }

  Future<bool> stopDown({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("decoder_control.cgi?command=3&onestep=0&", timeout: timeout);
    return ret;
  }

  //开启预置位自动巡航
  Future<bool> startPresetCruise({int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "decoder_control.cgi?command=22&onestep=0&",
        timeout: timeout);
    return ret;
  }

  //停止预置位自动巡航
  Future<bool> stopPresetCruise({int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "decoder_control.cgi?command=23&onestep=0&",
        timeout: timeout);
    return ret;
  }

  //开启上下巡航
  Future<bool> startUpAndDown({int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "decoder_control.cgi?command=26&onestep=0&",
        timeout: timeout);
    return ret;
  }

  //停止上下巡航
  Future<bool> stopUpAndDown({int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "decoder_control.cgi?command=27&onestep=0&",
        timeout: timeout);
    return ret;
  }

  //开启左右巡航
  Future<bool> startLeftAndRight({int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "decoder_control.cgi?command=28&onestep=0&",
        timeout: timeout);
    return ret;
  }

  //停止左右巡航
  Future<bool> stopLeftAndRight({int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "decoder_control.cgi?command=29&onestep=0&",
        timeout: timeout);
    return ret;
  }

  //圆圈循环巡航
  Future<bool> startCircleLoop({int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "decoder_control.cgi?command=80&onestep=0&",
        timeout: timeout);
    return ret;
  }

  //上下循环巡航
  Future<bool> startUpAndDownLoop({int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "decoder_control.cgi?command=79&onestep=0&",
        timeout: timeout);
    return ret;
  }

  //折线循环巡航
  Future<bool> startPolylineLoop({int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "decoder_control.cgi?command=78&onestep=0&",
        timeout: timeout);
    return ret;
  }

  //设置预置位
  Future<bool> setPresetLocation(int index, {int timeout = 5}) async {
    int? cmd;
    switch (index) {
      case 0:
        cmd = 30;
        break;
      case 1:
        cmd = 32;
        break;
      case 2:
        cmd = 34;
        break;
      case 3:
        cmd = 36;
        break;
      case 4:
        cmd = 38;
        break;
      default:
        break;
    }
    bool ret = await _command.writeCgi(
        "decoder_control.cgi?command=$cmd&onestep=0&",
        timeout: timeout);
    return ret;
  }

  //巡航到预置位
  Future<bool> toPresetLocation(int index, {int timeout = 5}) async {
    int? cmd;
    switch (index) {
      case 0:
        cmd = 31;
        break;
      case 1:
        cmd = 33;
        break;
      case 2:
        cmd = 35;
        break;
      case 3:
        cmd = 37;
        break;
      case 4:
        cmd = 39;
        break;
      default:
        break;
    }
    bool ret = await _command.writeCgi(
        "decoder_control.cgi?command=$cmd&onestep=0&",
        timeout: timeout);
    return ret;
  }

  //删除预置位
  Future<bool> deletePresetLocation(int index, {int timeout = 5}) async {
    int? cmd;
    switch (index) {
      case 0:
        cmd = 62;
        break;
      case 1:
        cmd = 63;
        break;
      case 2:
        cmd = 64;
        break;
      case 3:
        cmd = 65;
        break;
      case 4:
        cmd = 66;
        break;
      default:
        break;
    }
    bool ret = await _command.writeCgi(
        "decoder_control.cgi?command=$cmd&onestep=0&",
        timeout: timeout);
    return ret;
  }

  //设置看守位 index 0代表关闭 1-16:对应位置
  Future<bool> configCameraSensorGuard(int index, {int timeout = 5}) async {
    if (index < 0 || index > 16) return false;

    bool ret = await _command.writeCgi(
        "set_sensor_preset.cgi?sensorid=255&presetid=$index&",
        timeout: timeout);
    return ret;
  }

  var presetCruiseLinePointsData; //已经设置预置位的数据
  //获取已设置的预置位
  Future<bool> getPresetCruiseLinePoints({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("trans_cmd_string.cgi?cmd=2161&command=0&", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2161;") && str.contains("command=0;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        presetCruiseLinePointsData = data;
        return data["result"] == "0";
      }
    }
    return false;
  }
}

class WiFiInfo {
  String? ssid;
  String? mac;
  String? security;
  String? dbm0;
  String? dbm1;
  String? mode;
  String? channel;

  String toString() {
    return ("ssid:$ssid mac:$mac security:$security mode:$mode channel:$channel dbm0:$dbm0 dbm1:$dbm1");
  }
}

class WifiCommand {
  final CameraCommand _command;

  WifiCommand(this._command);

  List<WiFiInfo> wifiList = [];

  void _setWIfiInfo(Map data) {
    String result = data["result"];
    if (result == "0") {
      String apNumberStr = data["ap_number"] ?? "";

      int apNumber = int.tryParse(apNumberStr) ?? 0;
      wifiList.clear();
      for (int i = 0; i < apNumber; i++) {
        WiFiInfo info = WiFiInfo();
        info.ssid = data["ap_ssid[$i]"];
        info.mac = data["ap_mac[$i]"];
        info.security = data["ap_security[$i]"];
        info.dbm0 = data["ap_dbm0[$i]"];
        info.dbm1 = data["ap_dbm1[$i]"];
        info.mode = data["ap_mode[$i]"];
        info.channel = data["ap_channel[$i]"];
        wifiList.add(info);
      }
    }
  }

  Future<List<WiFiInfo>> wifiScan({bool cache = true, int timeout = 5}) async {
    if (cache == true) {
      return wifiList;
    }
    //get_wifi_scan_result
    //wifi_scan
    bool ret = await _command.writeCgi("wifi_scan.cgi?", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24618;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        if (data == null) {
          bool ret2 = await _command.writeCgi("get_wifi_scan_result.cgi?",
              timeout: timeout);
          if (ret2) {
            CommandResult result2 =
                await _command.waitCommandResult((int cmd, Uint8List data) {
              return cmd == 24584;
            }, timeout);
            if (result2.isSuccess) {
              Map data2 = result2.getMap();
              _setWIfiInfo(data2);
            }
          }
        } else {
          _setWIfiInfo(data);
        }
      }
    }
    return wifiList;
  }

  /// 获取设备WIFI
  Future<bool> configWiFi(WiFiInfo info, String password,
      {int timeout = 5, String area = ""}) async {
    String cgiParam =
        "ssid=${Uri.encodeQueryComponent(info.ssid ?? "")}&channel=${info.channel}&authtype=${info.security}&wpa_psk=${Uri.encodeQueryComponent(password)}&enable=1&";
    if (area != "") {
      cgiParam =
          "ssid=${Uri.encodeQueryComponent(info.ssid ?? "")}&channel=${info.channel}&authtype=${info.security}&wpa_psk=${Uri.encodeQueryComponent(password)}&enable=1&$area&";
    }

    bool ret =
        await _command.writeCgi("set_wifi.cgi?$cgiParam", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24593;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        return data["result"] == "0";
      }
      return false;
    }
    return ret;
  }
}

/// 摄像机LED灯控制
class LedCommand {
  final CameraCommand _command;

  LedCommand(this._command);

  bool? hideLed;

  Future<bool> controlLed(bool hide, {int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2125&command=0&hide_led_disable=${hide == true ? 1 : 0}&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2125;") && str.contains("command=0;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") hideLed = data["hide_led_disable"] == "1";
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> getLedState({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("trans_cmd_string.cgi?cmd=2125&command=1&", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2125;") && str.contains("command=1;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") hideLed = data["hide_led_disable"] == "1";

        return data["result"] == "0";
      }
    }
    return false;
  }
}

enum PowerMode {
  none,
  low,
  veryLow,
}

/// 摄像机功耗控制
class PowerCommand {
  final CameraCommand _command;

  PowerCommand(this._command);

  PowerMode? powerMode;

  String? chargingNoSleep;

  String _getPowerValue(PowerMode mode) {
    switch (mode) {
      case PowerMode.none:
        return "0";
      case PowerMode.low:
        return "30";
      case PowerMode.veryLow:
        return "10000";
    }
    return "30";
  }

  PowerMode _getPowerMode(String value) {
    if (value == "30") {
      return PowerMode.low;
    } else if (value == "10000") {
      return PowerMode.veryLow;
    } else {
      return PowerMode.none;
    }
  }

  Future<bool> controlPower(PowerMode mode, {int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2106&command=2&lowPower=${_getPowerValue(mode)}&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2106;") && str.contains("command=2;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") powerMode = _getPowerMode(data["lowPower"]);
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> controlChargingNoSleep(String isOpen, {int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2106&command=2&chargingNoSleep=$isOpen&lowPower=${_getPowerValue(powerMode!)}&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2106;") && str.contains("command=2;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["chargingNoSleep"] != null) {
          chargingNoSleep = data["chargingNoSleep"];
        }
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> getPowerMode({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("trans_cmd_string.cgi?cmd=2106&command=1&", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2106;") && str.contains("command=1;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") powerMode = _getPowerMode(data["lowPower"]);
        if (data["chargingNoSleep"] != null) {
          chargingNoSleep = data["chargingNoSleep"];
        }
        return data["result"] == "0";
      }
    }
    return false;
  }

  bool? electricitySleepSwitch;
  String? electricityThreshold;

  ///智能电量
  Future<bool> getSmartElectricitySleep({int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2106&command=17&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2106;") && str.contains("command=17;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          electricitySleepSwitch =
              data["Smart_Electricity_Sleep_Switch"] == "1";
          if (data["Smart_Electricity_Threshold"] != null) {
            electricityThreshold = data["Smart_Electricity_Threshold"];
          }
        }
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> setSmartElectricitySleep(int enable,
      {int timeout = 5, int electricityThreshold = 50}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2106&command=18&Smart_Electricity_Sleep_Switch=$enable&Smart_Electricity_Threshold=$electricityThreshold&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2106;") && str.contains("command=18;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        return data["result"] == "0";
      }
    }
    return false;
  }
}

/// 摄像机功耗控制
class DVRCommand {
  final CameraCommand _command;

  DVRCommand(this._command);

  bool? dvrMode;

  Future<bool> controlDVR(bool mode, {int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2106&command=12&DvModeSleepSwitch=${mode ? 1 : 0}&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2106;") && str.contains("command=12;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") dvrMode = data["DvModeSleepSwitch"] == "1";
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> getDVRMode({int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2106&command=11&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2106;") && str.contains("command=11;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") dvrMode = data["DvModeSleepSwitch"] == "1";
        return data["result"] == "0";
      }
    }
    return false;
  }
}

enum MobileNetwork {
  none,
  china_mobile, //中国移动
  china_unicom, //中国联通
  china_telecom, //中国电信
}

typedef MobileNotification = void Function(
    P2PBasisDevice device, MobileNetwork? network, int? single, String? iccid);

/// 移动网络指令
class MobileCommand {
  final CameraCommand _command;

  MobileCommand(this._command);

  ///移动网络类型
  MobileNetwork? mobileNetwork;

  ///移动网络信号
  int? mobileSingle;

  ///移动卡号ID
  String? mobileICCID;

  Future<bool> getMobileInfo({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("trans_cmd_string.cgi?cmd=2138&command=0&", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2138;") && str.contains("command=0;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          int index = int.tryParse(data["operator"] ?? "0") ?? 0;
          if (index < MobileNetwork.values.length) {
            mobileNetwork = MobileNetwork.values[index];
          }
          mobileSingle = int.tryParse(data["signal"] ?? "0") ?? 0;
          mobileICCID = data["iccid"];
          _command
              .notifyListeners<MobileNotification>((MobileNotification func) {
            func(_command, mobileNetwork, mobileSingle, mobileICCID);
          });
        }
        return data["result"] == "0";
      }
    }
    return false;
  }
}

/// 摄像机修改密码指令
class PasswordCommand {
  final CameraCommand _command;
  final StatusResult _result;

  PasswordCommand(this._command, this._result);

  Future<bool> pwdChangeCommand(String password, {int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "set_users.cgi?&user1=''&user2=''&user3=admin&pwd1=''&pwd2=''&pwd3=$password&",
        timeout: timeout);
    if (_result.pwd_change_realtime != null &&
        _result.pwd_change_realtime == '1') {
      ret = await _command.writeCgi(
          "set_users.cgi?pwd_change_realtime=1&user1=''&user2=''&user3=admin&pwd1=''&pwd2=''&pwd3=$password&",
          timeout: timeout);
    }
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        return true;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        return data["result"] == "0";
      }
    }
    return false;
  }
}

///检测间隔  徘徊检测  humanDetection人体侦测等级不能去掉
class CheckIntervalCommand {
  final CameraCommand _command;

  CheckIntervalCommand(this._command);

  bool? sleepCheckIntervalSwitch;

  bool? lingerCheckIntervalSwitch;

  int sleepCheckIntervalDuration = 15;

  int lingerCheckIntervalDuration = 15;

  //获取检测间隔状态
  Future<bool> getCheckInterval({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("trans_cmd_string.cgi?cmd=2106&command=3&", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2106;") && str.contains("command=3;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          sleepCheckIntervalSwitch = data["SleepCheckIntervalSwitch"] == "1";
          lingerCheckIntervalSwitch = data["LingerCheckIntervalSwitch"] == "1";
          var sleepDuration = data["SleepCheckIntervalDuration"];
          var lingerDuration = data["LingerCheckIntervalSDuration"];
          if (sleepDuration != null) {
            sleepCheckIntervalDuration = int.tryParse(sleepDuration) ?? 0;
          }
          if (lingerDuration != null) {
            lingerCheckIntervalDuration = int.tryParse(lingerDuration) ?? 0;
          }
        }
        return data["result"] == "0";
      }
    }
    return false;
  }

  //设置检测间隔状态
  Future<bool> setSleepCheckInterval(int enable, int humanDetection,
      {int timeout = 5, int duration = 15}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2106&command=4&humanDetection=$humanDetection&SleepCheckIntervalSwitch=$enable&SleepCheckIntervalDuration=$duration&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2106;") && str.contains("command=4;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        return data["result"] == "0";
      }
    }
    return false;
  }

  //设置徘徊检测
  Future<bool> setLingerCheckInterval(int enable, int humanDetection,
      {int timeout = 5, int duration = 15}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2106&command=4&humanDetection=$humanDetection&LingerCheckIntervalSwitch=$enable&LingerCheckIntervalSDuration=$duration&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2106;") && str.contains("command=4;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        return data["result"] == "0";
      }
    }
    return false;
  }
}

/// 门铃解除防拆报警
class DismantleCommand {
  final CameraCommand _command;

  DismantleCommand(this._command);

  bool? dismantleAlarm;

  //cmd = 0 永久设置， cmd = 1 获取， cmd = 2临时设置
  Future<bool> controlDismantle(bool dismantl, int command,
      {int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2203&command=$command&tamper_alarm=${dismantl == true ? 1 : 0}&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2203;") && str.contains("command=$command;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") dismantleAlarm = data["tamper_alarm"] == "1";
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> getDismantleState({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("trans_cmd_string.cgi?cmd=2203&command=1&", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2203;") && str.contains("command=1;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0") dismantleAlarm = data["tamper_alarm"] == "1";

        return data["result"] == "0";
      }
    }
    return false;
  }
}

/// tf录像分辨率的切换
class RecordResolutionCommand {
  final CameraCommand _command;

  RecordResolutionCommand(this._command);

  int? recordResolut;

  // 0-->录像主码流（超高清）
  // 1-->录像主码流 （高清）
  // 2-->录像子码流（标清）
  Future<bool> controlRecordResolution(int resolution,
      {int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2204&command=2&record_resolution=$resolution&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2204;") && str.contains("command=2;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> getRecordResolutionState({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("trans_cmd_string.cgi?cmd=2204&command=1&", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2204;") && str.contains("command=1;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0" && data["record_resolution"] != null)
          recordResolut = int.tryParse(data["record_resolution"]) ?? 0;
        return data["result"] == "0";
      }
    }
    return false;
  }
}

///枪球机指令
class QiangQiuCommand {
  final CameraCommand _command;

  int? picconrection_status;
  int? gblinkage_enable;

  QiangQiuCommand(this._command);

  Future<bool> controlFocalPoint(int x_percent, int y_percent,
      {int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "camera_control.cgi?param=39&value=0&x_percent=${x_percent}&y_percent=${y_percent}");
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24594;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> controlSensorSwitch(int sensor, {int timeout = 5}) async {
    bool ret =
        await _command.writeCgi("camera_control.cgi?param=38&value=${sensor}&");
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24594;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> controlLinkageEnable(int enable, {int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=4101&command=1&gblinkage_enable=$enable&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=4101;") && str.contains("command=1;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        print('==>>设置抢球开关 返回结果:${data}');
        if (data["result"] == "0" && data["gblinkage_enable"] != null)
          gblinkage_enable = int.tryParse(data["gblinkage_enable"]) ?? 0;
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> getLinkageEnable({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("trans_cmd_string.cgi?cmd=4101&command=0&", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=4101;") && str.contains("command=0;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        print('==>>获取抢球开关 返回结果:${data}');

        if (data["result"] == "0" && data["gblinkage_enable"] != null)
          gblinkage_enable = int.tryParse(data["gblinkage_enable"]) ?? 0;
        return data["result"] == "0";
      }
    }
    return false;
  }

  ///云台复位进度
  Future<bool> qiangqiuPTZReset({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("trans_cmd_string.cgi?cmd=4100&command=0&", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=4100;") && str.contains("command=0;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0" && data["picconrection_status"] != null)
          picconrection_status =
              int.tryParse(data["picconrection_status"]) ?? 0;
        return data["result"] == "0";
      }
    }
    return false;
  }

  ///查询复位进度
  Future<bool> qiangqiuPTZCheck({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("trans_cmd_string.cgi?cmd=4100&command=1&", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=4100;") && str.contains("command=1;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        if (data["result"] == "0" && data["picconrection_status"] != null)
          picconrection_status =
              int.tryParse(data["picconrection_status"]) ?? 0;
        return data["result"] == "0";
      }
    }
    return false;
  }

  ///画面校正
  Future<bool> controlRevisePoint(int x_percent, int y_percent,
      {int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "camera_control.cgi?param=40&value=0&x_percent=${x_percent}&y_percent=${y_percent}");
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24594;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<Directory> getDeviceDirectory() async {
    Directory dir = await getApplicationDocumentsDirectory();
    dir = Directory("${dir.path}/${'qiangji'}");
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<File> _saveSnapshotFile(Uint8List data, String name) async {
    Directory directory = await getDeviceDirectory();
    String filePath = '${directory.path}/images/${'qiangji'}${name}';
    File file = File(filePath);
    if (file.existsSync()) {
      file.deleteSync();
    }
    file.createSync(recursive: true);
    file = await file.writeAsBytes(data, mode: FileMode.write, flush: true);
    return file;
  }

  /// 获取截图快照
  Future<File?> getSnapshot(String name, {int timeout = 5}) async {
    int time = DateTime.now().millisecondsSinceEpoch;
    bool ret = await _command.writeCgi("snapshot.cgi?sensor=${name}&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24597;
      }, timeout);
      if (result.isSuccess && result.data != null && result.data!.length > 0) {
        return await _saveSnapshotFile(result.data!, '${time}${"_"}{$name}');
      }
    }
    return null;
  }
}
