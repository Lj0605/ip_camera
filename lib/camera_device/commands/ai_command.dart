import 'dart:convert';
import 'dart:typed_data';
import 'package:vsdk/camera_device/commands/status_command.dart';
import 'package:vsdk/p2p_device/p2p_command.dart';
import 'camera_command.dart';

mixin AICommand on CameraCommand {
  @override
  Future<StatusResult?> getStatus({int timeout = 5, bool cache = true}) async {
    StatusResult? result =
        await super.getStatus(timeout: timeout, cache: cache);
    if (result != null) {
      await setCameraCommand(result);
    }
    return result;
  }

  Future<void> setCameraCommand(StatusResult result) async {
    if (humanTracking == null && result.support_humanDetect == "1") {
      humanTracking = HumanTracking(this);
    }
    if (humanFraming == null && result.support_humanoidFrame == "1") {
      humanFraming = HumanFraming(this);
    }

    if (humanZoom == null && result.support_humanoid_zoom == "1") {
      humanZoom = HumanZoom(this);
    }

    if (customSound == null && result.support_voiceTypedef == "1") {
      customSound = CustomSound(this);
    }

    if (aiDetect == null && result.support_mode_AiDetect != null) {
      aiDetect = AiDetect(this);
    }
  }

  HumanTracking? humanTracking;

  HumanFraming? humanFraming;

  HumanZoom? humanZoom;

  CustomSound? customSound;

  AiDetect? aiDetect;
}

typedef HumanTrackCallBack<T> = void Function(int value);

/// 人形追踪
class HumanTracking {
  final AICommand _command;

  HumanTracking(this._command);

  int humanTrackingEnable = 0;
  int humanTrackStatus = 0;

  ///获取设备人形跟踪
  Future<bool> getHumanTracking(
      {int timeout = 5, HumanTrackCallBack? humanTrackCallBack}) async {
    bool ret = await _command
        .writeCgi("trans_cmd_string.cgi?cmd=2127&command=1&", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2127;") && str.contains("command=1;");
        }
        return false;
      }, timeout);
      _command.removeCallback(24785);
      _command.addCallback(24785, (cmd, result) {
        Map data = result.getMap();
        if (data.containsKey("track_status")) {
          if (humanTrackCallBack != null) {
            humanTrackStatus = int.tryParse(data["track_status"] ?? "0") ?? 0;
            humanTrackCallBack(humanTrackStatus);
          }
        }
      });
      if (result.isSuccess == true) {
        Map data = result.getMap();
        humanTrackingEnable = int.tryParse(data["enable"] ?? "0") ?? 0;
        humanTrackStatus = int.tryParse(data["track_status"] ?? "0") ?? 0;
        return data["result"] == "0";
      }
    }
    return false;
  }

  ///设置设备人形跟踪
  Future<bool> setHumanTracking(int enable, {int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2127&command=0&enable=$enable&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2127;") && str.contains("command=0;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        humanTrackingEnable = int.tryParse(data["enable"] ?? "0") ?? 0;
        return data["result"] == "0";
      }
    }
    return false;
  }
}

/// 人形框定
class HumanFraming {
  final AICommand _command;

  HumanFraming(this._command);

  int humanFrameEnable = 0;

  ///获取人形框定
  Future<bool> getHumanFraming({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("trans_cmd_string.cgi?cmd=2126&command=1&", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2126;") && str.contains("command=1;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        humanFrameEnable = int.tryParse(data["bHumanoidFrame"] ?? "0") ?? 0;
        return data["result"] == "0";
      }
    }
    return false;
  }

  ///设置人形框定
  Future<bool> setHumanFraming(int enable, {int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2126&command=0&bHumanoidFrame=$enable&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2126;") && str.contains("command=0;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        humanFrameEnable = int.tryParse(data["bHumanoidFrame"] ?? "0") ?? 0;
        return data["result"] == "0";
      }
    }
    return false;
  }
}

/// 人形变倍跟踪
class HumanZoom {
  final AICommand _command;

  HumanZoom(this._command);

  int humanZoomEnable = 0;

  Future<bool> getHumanZoom({int timeout = 5}) async {
    bool ret = await _command
        .writeCgi("trans_cmd_string.cgi?cmd=2126&command=1&", timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2126;") && str.contains("command=1;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        humanZoomEnable = int.tryParse(data["humanoid_zoom"] ?? "0") ?? 0;
        return data["result"] == "0";
      }
    }
    return false;
  }

  ///设置人形框定
  Future<bool> setHumanZoom(int enable, {int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2126&command=0&humanoid_zoom=$enable&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2126;") && str.contains("command=0;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        humanZoomEnable = int.tryParse(data["humanoid_zoom"] ?? "0") ?? 0;
        return data["result"] == "0";
      }
    }
    return false;
  }
}

class CustomSound {
  final AICommand _command;

  CustomSound(this._command);

  Map? soundData;

  ///获取报警声音
  ///voicetype
  ///0---人脸侦测报警提 示音
  ///1---人形侦测报警提 示音
  ///2---烟感报警提示音
  ///3---移动侦测报警提 示音
  ///4---离岗检测提示音
  ///5---哭声检测提示音
  ///6---在岗监测提示音
  ///7---烟火相机火焰提示音
  ///8---烟火相机烟雾提示音
  Future<bool> getVoiceInfo(int voiceType, {int timeout = 10}) async {
    String cgi =
        "trans_cmd_string.cgi?cmd=2135&command=1&voicetype=$voiceType&";
    bool ret = await _command.writeCgi(cgi, timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2135;") && str.contains("command=1;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        print('==>>getVoiceInfo获取到的数据:${data}');
        soundData = data;
        return data["result"] == "0";
      }
    }
    return false;
  }

  ///设置报警声音
  ///param [voiceUrl] 下载服务器地址
  ///param [voiceName] 文件名
  ///param [swtich] 0无声音  1 有声音
  ///param [voicetype] 0---人脸侦测报警提 示音 1---人形侦测报警提 示音 2---烟感报警提示音 3---移动侦测报警提 示音 4---离岗检测提示音 5---哭声检测提示音 6---在岗监测提示音 7---烟火相机火焰提示音 8---烟火相机烟雾提示音
  ///param [playInDevice] 是否让设备播放
  Future<bool> setVoiceInfo(
      String? voiceUrl, String voiceName, int swtich, int voicetype,
      {bool playInDevice = false,
      int timeout = 20,
      String playTimes = '3'}) async {
    String urlJson = "{}";
    if (voiceUrl != null && voiceUrl.isNotEmpty) {
      var dic = {"url": voiceUrl};
      urlJson = json.encode(dic);
    }
    String cgi =
        "trans_cmd_string.cgi?cmd=2135&command=0&urlJson=$urlJson&filename=$voiceName&switch=$swtich&voicetype=$voicetype&";
    if (swtich == 0) {
      cgi =
          "trans_cmd_string.cgi?cmd=2135&command=0&switch=$swtich&voicetype=$voicetype&";
    }
    if (playInDevice == true) {
      cgi = cgi + "play=1&" + "playtimes=$playTimes&";
    } else {
      cgi = cgi + "playtimes=$playTimes&";
    }
    bool ret = await _command.writeCgi(cgi, timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2135;") && str.contains("command=0;");
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

class AiDetect {
  final AICommand _command;

  AiDetect(this._command);

  Map<String, dynamic>? aiConfigMap;

  Future<bool> getAiDetectData(int aiType, {int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2400&command=1&AiType=$aiType&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2400;") && str.contains("command=1;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        print('==>>获取getAiDetectData:$data');
        Map<String, dynamic> aiCfg = jsonDecode((data["AiCfg"]));
        if (aiCfg is Map) {
          aiConfigMap = aiCfg;
        } else {
          print('==>>AiCfg 不是个Map');
        }
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> setAiDetectData(int aiType, String aiConfigSring,
      {int timeout = 5}) async {
    print('==>>设置setAiDetectData 类型:${aiType} 数据:$aiConfigSring');

    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2400&command=0&AiType=$aiType&AiCfg=$aiConfigSring&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2400;") && str.contains("command=0;");
        }
        return false;
      }, timeout);
      if (result.isSuccess == true) {
        Map data = result.getMap();
        print('==>>设置setAiDetectData结果:$data');
        return data["result"] == "0";
      }
    }
    return false;
  }

//  获取AI定时计划
//  command=11
//  type=12 获取火计划
//  type=14 获取区域入侵计划
//  type=15 获取人逗留计划
//  type=16 获取车违停计划
//  type=17 获取越线检测计划
//  type=18 获取离岗检测计划
//  type=19 获取车辆逆行计划
//  type=20 获取包裹计划

  Map? firePlanData;
  Map? areaIntrusionPlanData;
  Map? personStayPlanData;
  Map? illegalParkingPlanData;
  Map? crossBorderPlanData;
  Map? offPostMonitorPlanData;
  Map? carRetrogradePlanData;
  Map? packageDetectPlanData;

  Future<bool> getAiDetectPlan(int type, {int timeout = 5}) async {
    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2017&command=11&mark=1&type=$type&",
        timeout: timeout);
    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2017;") &&
              str.contains("command=11;") &&
              str.contains("type=$type;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        print('==>>获取到AI检测类型:${type}的结果:${data}');
        if (type == 12) {
          //获取火计划
          if (data.containsKey("fire_plan_enable")) {
            firePlanData = data;
          }
        } else if (type == 14) {
          //获取区域入侵计划
          if (data.containsKey("region_entry_plan_enable")) {
            areaIntrusionPlanData = data;
          }
        } else if (type == 15) {
          //获取人逗留计划
          if (data.containsKey("person_stay_plan_enable")) {
            personStayPlanData = data;
          }
        } else if (type == 16) {
          //获取车违停计划
          if (data.containsKey("car_stay_plan_enable")) {
            illegalParkingPlanData = data;
          }
        } else if (type == 17) {
          //获取越线检测计划
          if (data.containsKey("line_cross_plan_enable")) {
            crossBorderPlanData = data;
          }
        } else if (type == 18) {
          //获取离岗检测计划
          if (data.containsKey("person_onduty_plan_enable")) {
            offPostMonitorPlanData = data;
          }
        } else if (type == 19) {
          //获取车辆逆行计划
          if (data.containsKey("car_retrograde_plan_enable")) {
            carRetrogradePlanData = data;
          }
        } else if (type == 20) {
          //包裹计划
          if (data.containsKey("package_detect_plan_enable")) {
            packageDetectPlanData = data;
          }
        }
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> configAiDetectPlan(int type,
      {required List records, int enable = 1, int timeout = 5}) async {
    var typeString;
    switch (type) {
      case 12:
        //火
        typeString = 'fire';
        break;
      case 14:
        //区域入侵
        typeString = 'region_entry';
        break;
      case 15:
        //人逗留计划
        typeString = 'person_stay';
        break;
      case 16:
        //车违停计划
        typeString = 'car_stay';
        break;
      case 17:
        //越线检测计划
        typeString = 'line_cross';
        break;
      case 18:
        //离岗检测计划
        typeString = 'person_onduty';
        break;
      case 19:
        //车辆逆行计划
        typeString = 'car_retrograde';
        break;
      case 20:
        //包裹监测
        typeString = 'package_detect';
        break;
      default:
        break;
    }

    bool ret = await _command.writeCgi(
        "trans_cmd_string.cgi?cmd=2017&command=$type&mark=1&"
        "${typeString}_plan1=${records[0]}&"
        "${typeString}_plan2=${records[1]}&"
        "${typeString}_plan3=${records[2]}&"
        "${typeString}_plan4=${records[3]}&"
        "${typeString}_plan5=${records[4]}&"
        "${typeString}_plan6=${records[5]}&"
        "${typeString}_plan7=${records[6]}&"
        "${typeString}_plan8=${records[7]}&"
        "${typeString}_plan9=${records[8]}&"
        "${typeString}_plan10=${records[9]}&"
        "${typeString}_plan11=${records[10]}&"
        "${typeString}_plan12=${records[11]}&"
        "${typeString}_plan13=${records[12]}&"
        "${typeString}_plan14=${records[13]}&"
        "${typeString}_plan15=${records[14]}&"
        "${typeString}_plan16=${records[15]}&"
        "${typeString}_plan17=${records[16]}&"
        "${typeString}_plan18=${records[17]}&"
        "${typeString}_plan19=${records[18]}&"
        "${typeString}_plan20=${records[19]}&"
        "${typeString}_plan21=${records[20]}&"
        "${typeString}_plan_enable=$enable&",
        timeout: timeout);

    if (ret) {
      CommandResult result =
          await _command.waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2017;") && str.contains("command=$type;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        print('==>>configAiDetectPlan:$type的结果:${data}');
        if (data["status"] == "0" || data["result"] == "0") {
          return true;
        }
      }
    }
    return false;
  }
}
