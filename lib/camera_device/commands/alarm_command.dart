import 'dart:convert';
import 'dart:typed_data';

import 'package:vsdk/p2p_device/p2p_command.dart';

mixin AlarmCommand on P2PCommand {
  bool? pirPushEnable;
  bool? pirPushVideoEnable;
  int? pirDetection;
  int? pirCloudVideoDuration; //视频时长

  int? pirLevel; //人体
  int? motionLevel; //移动
  int? humanLevel; //人形

  int? pushEnable; //推送开关
  int? videoEnable; //视频开关
  int? videoDuration; //视频时长

  int? humanDetection; //
  int? distanceAdjust; //侦测距离
  int? humanoidDetection; //人形检测

  int? autoRecordVideoMode; //录像时长自动

  Future<bool> getAlarmParam({int timeout = 5}) async {
    bool ret = await writeCgi("trans_cmd_string.cgi?cmd=2106&command=8&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2106;") && str.contains("command=8;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        pirPushEnable = data["pirPushSwitch"] == "1";
        pirPushVideoEnable = data["pirPushSwitchVideo"] == "1";
        if (data.containsKey("CloudVideoDuration")) {
          pirCloudVideoDuration =
              int.tryParse(data["CloudVideoDuration" ?? "15"]) ?? -1;
        } else {
          pirCloudVideoDuration = -1;
        }
        if (data.containsKey("autoRecordMode")) {
          autoRecordVideoMode =
              int.tryParse(data["autoRecordMode" ?? "0"]) ?? 0;
        } else {
          autoRecordVideoMode = 0;
        }
        await getPirDetection();
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> setPriPush(
      {bool pushEnable = true,
      bool videoEnable = true,
      int videoDuration = 15,
      int autoRecordMode = 0,
      int timeout = 5}) async {
    pushEnable = (pushEnable ?? pirPushEnable) ?? false;
    videoEnable = (videoEnable ?? pirPushVideoEnable) ?? false;
    videoDuration = (videoDuration ?? pirCloudVideoDuration) ?? 15;
    autoRecordMode = (autoRecordMode ?? autoRecordVideoMode) ?? 0;
    String cgi =
        "trans_cmd_string.cgi?cmd=2106&command=9&pirPushSwitch=${pushEnable ? 1 : 0}&pirPushSwitchVideo=${videoEnable ? 1 : 0}&";
    if (videoDuration != -1) {
      cgi =
          "trans_cmd_string.cgi?cmd=2106&command=9&pirPushSwitch=${pushEnable ? 1 : 0}&pirPushSwitchVideo=${videoEnable ? 1 : 0}&CloudVideoDuration=${videoDuration ?? 15}&autoRecordMode=${autoRecordMode ?? 0}&";
    }
    bool ret = await writeCgi(cgi, timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2106;") && str.contains("command=9;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          pirPushEnable = pushEnable;
          pirPushVideoEnable = videoEnable;
          pirCloudVideoDuration = videoDuration;
          autoRecordVideoMode = autoRecordMode;
          return true;
        }
      }
    }
    return false;
  }

  ///人体侦测等级
  ///关-----0
  ///低-----1
  ///中-----2
  ///高-----3
  Future<bool> getPirDetection({int timeout = 5}) async {
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2106&command=3&mark=12345678&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2106;") && str.contains("command=3;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        pirDetection = int.tryParse(data["humanDetection"] ?? "") ?? 0;
        pirLevel = int.tryParse(data["humanDetection"] ?? "") ?? 0;
        distanceAdjust = int.tryParse(data["DistanceAdjust"] ?? "") ?? 0;
        humanoidDetection = int.tryParse(data["HumanoidDetection"] ?? "") ?? 0;
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> setPriDetection(int detection, {int timeout = 5}) async {
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2106&command=4&humanDetection=$detection&&mark=123456789&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2106;") && str.contains("command=4;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          pirDetection = detection;
          pirLevel = detection;
          return true;
        }
      }
    }
    return false;
  }

  ///移动侦测等级
  Future<bool> setAlarmMotionDetection(bool enable, int level,
      {int timeout = 5, int? videoDuration}) async {
    int plan = 0;
    if (enable) {
      plan = -1;
    }
    videoDuration = videoDuration ?? pirCloudVideoDuration;
    String cgi =
        "set_alarm.cgi?enable_alarm_audio=0&motion_armed=${enable ? 1 : 0}&motion_sensitivity=$level&"
        "input_armed=1&ioin_level=0&iolinkage=0&ioout_level=0&preset=0&mail=0&snapshot=1&"
        "record=1&upload_interval=0&schedule_enable=1&schedule_sun_0=$plan&schedule_sun_1=$plan&"
        "schedule_sun_2=$plan&schedule_mon_0=$plan&schedule_mon_1=$plan&schedule_mon_2=$plan&"
        "schedule_tue_0=$plan&schedule_tue_1=$plan&schedule_tue_2=$plan&schedule_wed_0=$plan&"
        "schedule_wed_1=$plan&schedule_wed_2=$plan&schedule_thu_0=$plan&schedule_thu_1=$plan&"
        "schedule_thu_2=$plan&schedule_fri_0=$plan&schedule_fri_1=$plan&schedule_fri_2=$plan&"
        "schedule_sat_0=$plan&schedule_sat_1=$plan&schedule_sat_2=$plan&defense_plan1=0&"
        "defense_plan2=0&defense_plan3=0&defense_plan4=0&defense_plan5=0&defense_plan6=0&defense_plan7=0&"
        "defense_plan8=0&defense_plan9=0&defense_plan10=0&defense_plan11=0&defense_plan12=0&defense_plan13=0&"
        "defense_plan14=0&defense_plan15=0&defense_plan16=0&defense_plan17=0&defense_plan18=0&defense_plan19=0&"
        "defense_plan20=0&defense_plan21=0&";

    if (videoDuration != -1) {
      cgi =
          "set_alarm.cgi?enable_alarm_audio=0&motion_armed=${enable ? 1 : 0}&motion_sensitivity=$level&CloudVideoDuration=$videoDuration&"
          "input_armed=1&ioin_level=0&iolinkage=0&ioout_level=0&preset=0&mail=0&snapshot=1&"
          "record=1&upload_interval=0&schedule_enable=1&schedule_sun_0=$plan&schedule_sun_1=$plan&"
          "schedule_sun_2=$plan&schedule_mon_0=$plan&schedule_mon_1=$plan&schedule_mon_2=$plan&"
          "schedule_tue_0=$plan&schedule_tue_1=$plan&schedule_tue_2=$plan&schedule_wed_0=$plan&"
          "schedule_wed_1=$plan&schedule_wed_2=$plan&schedule_thu_0=$plan&schedule_thu_1=$plan&"
          "schedule_thu_2=$plan&schedule_fri_0=$plan&schedule_fri_1=$plan&schedule_fri_2=$plan&"
          "schedule_sat_0=$plan&schedule_sat_1=$plan&schedule_sat_2=$plan&defense_plan1=0&"
          "defense_plan2=0&defense_plan3=0&defense_plan4=0&defense_plan5=0&defense_plan6=0&defense_plan7=0&"
          "defense_plan8=0&defense_plan9=0&defense_plan10=0&defense_plan11=0&defense_plan12=0&defense_plan13=0&"
          "defense_plan14=0&defense_plan15=0&defense_plan16=0&defense_plan17=0&defense_plan18=0&defense_plan19=0&"
          "defense_plan20=0&defense_plan21=0&";
    }
    bool ret = await writeCgi(cgi, timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24588;
      }, timeout);
      if (result.isSuccess) {
        pirCloudVideoDuration = videoDuration;
        Map data = result.getMap();
        if (data["result"] == "0") {
          return true;
        }
      }
    }
    return false;
  }

  ///人形侦测等级
  ///关-----0
  ///高-----1
  ///中-----2
  ///低-----3
  Future<bool> setHumanDetectionLevel(int sensitive, {int timeout = 5}) async {
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2126&command=0&sensitive=$sensitive&&mark=123456789&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2126;") && str.contains("command=0;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          humanLevel = sensitive;
          return true;
        }
      }
    }
    return false;
  }

  Future<bool> getHumanDetectionLevel({int timeout = 5}) async {
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2126&command=1&mark=123456789&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2126;") && str.contains("command=1;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          humanLevel = int.tryParse(data["sensitive"] ?? "") ?? 0;
          return true;
        }
      }
    }
    return false;
  }

  ///获取pir视频录像状态（人体侦测）
  Future<bool> getAlarmPirVideoPush({int timeout = 5}) async {
    bool ret = await writeCgi("trans_cmd_string.cgi?cmd=2106&command=8&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2106;") && str.contains("command=8;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          pushEnable = int.tryParse(data["pirPushSwitch"] ?? "") ?? 0;
          videoEnable = int.tryParse(data["pirPushSwitchVideo"] ?? "") ?? 0;
          if (data.containsKey("CloudVideoDuration")) {
            videoDuration =
                int.tryParse(data["CloudVideoDuration" ?? "15"]) ?? -1;
          } else {
            videoDuration = -1;
          }
          if (data.containsKey("autoRecordModey")) {
            autoRecordVideoMode =
                int.tryParse(data["autoRecordMode" ?? "0"]) ?? -1;
          } else {
            autoRecordVideoMode = 0;
          }
        }
        return data["result"] == "0";
      }
    }
    return false;
  }

  ///设置pir视频录像状态（人体侦测）
  Future<bool> setAlarmPirVideoPush(
      {int? pirPushEnable,
      int? pirVideoEnable,
      int? pirVideoDuration,
      int? autoRecordMode,
      int timeout = 5}) async {
    int? pushEnable1 = pirPushEnable ?? pushEnable;
    int? videoEnable1 = pirVideoEnable ?? videoEnable;
    int? videoDuration1 = pirVideoDuration ?? videoDuration;
    int? autoRecordMode1 = autoRecordMode ?? autoRecordVideoMode;
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2106&command=9&pirPushSwitch=${pushEnable1 == 1 ? 1 : 0}&pirPushSwitchVideo=${videoEnable1 == 1 ? 1 : 0}&CloudVideoDuration=${videoDuration1 ?? 15}&autoRecordMode=${autoRecordMode1 ?? 0}&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2106;") && str.contains("command=9;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          pushEnable = pushEnable1;
          videoEnable = videoEnable1;
          videoDuration = videoDuration1;
          autoRecordVideoMode = autoRecordMode1;
          return true;
        }
      }
    }
    return false;
  }

  ///获取侦测距离
  Future<bool> getDetectionRange({int timeout = 5}) async {
    bool ret = await writeCgi("trans_cmd_string.cgi?cmd=2106&command=3&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2106;") && str.contains("command=3;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          distanceAdjust = int.tryParse(data["DistanceAdjust"] ?? "0") ?? 0;
          pirLevel = int.tryParse(data["humanDetection"] ?? "") ?? 0;
          humanoidDetection =
              int.tryParse(data["HumanoidDetection"] ?? "") ?? 0;
          return true;
        }
      }
    }
    return false;
  }

  ///设置侦测距离
  Future<bool> setDetectionRange(int distance, {int timeout = 5}) async {
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2106&command=4&humanDetection=$pirLevel&DistanceAdjust=$distance&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2106;") && str.contains("command=4;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          distanceAdjust = distance;
          return true;
        }
      }
    }
    return false;
  }

  ///设置人形检测开关
  Future<bool> setHuanoidDetection(int value, {int timeout = 5}) async {
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2106&command=4&humanDetection=$pirLevel&DistanceAdjust=$distanceAdjust&HumanoidDetection=$value&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2106;") && str.contains("command=4;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          humanDetection = value; //note
          humanoidDetection = value;
          return true;
        }
      }
    }
    return false;
  }

  ///获取报警计划
  ///type == 2 报警计划
  Future<bool> getAlarmPlan(int command, int type, {int timeout = 5}) async {
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2017&command=11&type=$type&mark=123456789&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2017;") && str.contains("command=11;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          if (data["motion_push_enable"] == "0") {
            pirPushEnable = false;
          } else {
            pirPushEnable = true;
          }
          //currentAlarmType = int.parse(data["motion_push_enable"]);
          return true;
        }
      }
    }
    return false;
  }

  ///设置报警计划
  ///command == 2 报警计划
  Future<bool> setAlarmPlan(
      int command,
      int motion_push_plan_enable,
      int motion_push_plan1,
      int motion_push_plan2,
      int motion_push_plan3,
      int motion_push_plan4,
      int motion_push_plan5,
      int motion_push_plan6,
      int motion_push_plan7,
      int motion_push_plan8,
      int motion_push_plan9,
      int motion_push_plan10,
      int motion_push_plan11,
      int motion_push_plan12,
      int motion_push_plan13,
      int motion_push_plan14,
      int motion_push_plan15,
      int motion_push_plan16,
      int motion_push_plan17,
      int motion_push_plan18,
      int motion_push_plan19,
      int motion_push_plan20,
      int motion_push_plan21,
      {int timeout = 5}) async {
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2017&command=2&mark=10611404&motion_push_plan1=$motion_push_plan1&motion_push_plan2=$motion_push_plan2&motion_push_plan3=$motion_push_plan3&motion_push_plan4=$motion_push_plan4&motion_push_plan5=$motion_push_plan5&motion_push_plan6=$motion_push_plan6&motion_push_plan7=$motion_push_plan7"
        "&motion_push_plan8=$motion_push_plan8&motion_push_plan9=$motion_push_plan9&motion_push_plan10=$motion_push_plan10&motion_push_plan11=$motion_push_plan11&motion_push_plan12=$motion_push_plan12&motion_push_plan13=$motion_push_plan13&motion_push_plan14=$motion_push_plan14&motion_push_plan15=$motion_push_plan15"
        "&motion_push_plan16=$motion_push_plan16&motion_push_plan17=$motion_push_plan17&motion_push_plan18=$motion_push_plan18&motion_push_plan19=$motion_push_plan19&motion_push_plan20=$motion_push_plan20&motion_push_plan21=$motion_push_plan21&motion_push_plan_enable=$motion_push_plan_enable&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2017;") && str.contains("command=2;");
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

  ///设置报警计划
  ///command == 2 报警计划
  Future<bool> setAlarmMotion(int motion_push_plan_enable,
      {int timeout = 5}) async {
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2017&command=2&mark=10672216&motion_push_plan1=0&motion_push_plan2=0&motion_push_plan3=0&motion_push_plan4=0&motion_push_plan5=0&motion_push_plan6=0&motion_push_plan7=0&motion_push_plan8=0&motion_push_plan9=0&motion_push_plan10=0&motion_push_plan11=0&motion_push_plan12=0&motion_push_plan13=0&motion_push_plan14=0&motion_push_plan15=0&motion_push_plan16=0&motion_push_plan17=0&motion_push_plan18=0&motion_push_plan19=0&motion_push_plan20=0&motion_push_plan21=0&motion_push_plan_enable=$motion_push_plan_enable&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2017;") && str.contains("command=2;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        if (data["motion_push_enable"] == "0") {
          pirPushEnable = false;
        } else if (data["motion_push_enable"] == "1") {
          pirPushEnable = true;
        }

        return true;
      }
    }
    return false;
  }

  ///获取绘制区域
  ///command ===1   /移动侦测区域
  ///command ===3   /人形侦测区域
  Future<bool> getAlarmZone(int command, {int timeout = 5}) async {
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2123&command=$command&mark=123456789&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2123;") && str.contains("command=$command;");
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

  ///设置绘制区域
  ///command ===1   /移动侦测区域
  ///command ===3   /人形侦测区域
  Future<bool> setAlarmZone(
      int command,
      int pd_reign0,
      int pd_reign1,
      int pd_reign2,
      int pd_reign3,
      int pd_reign4,
      int pd_reign5,
      int pd_reign6,
      int pd_reign7,
      int pd_reign8,
      int pd_reign9,
      int pd_reign10,
      int pd_reign11,
      int pd_reign12,
      int pd_reign13,
      int pd_reign14,
      int pd_reign15,
      int pd_reign16,
      int pd_reign17,
      {int timeout = 5}) async {
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2123&command=$command&pd_reign0=$pd_reign0&pd_reign1=$pd_reign1&pd_reign2=$pd_reign2&pd_reign3=$pd_reign3&pd_reign4=$pd_reign4&pd_reign5=$pd_reign5&pd_reign6=$pd_reign6&pd_reign7=$pd_reign7&pd_reign8=$pd_reign8&pd_reign9=$pd_reign9&pd_reign10=$pd_reign10&pd_reign11=$pd_reign11&pd_reign12=$pd_reign12&pd_reign13=$pd_reign13&pd_reign14=$pd_reign14&pd_reign15=$pd_reign15&pd_reign16=$pd_reign16&pd_reign17=$pd_reign17&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2126;") && str.contains("command=0;");
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
}
