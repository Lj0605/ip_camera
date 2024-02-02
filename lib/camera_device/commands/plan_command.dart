import 'dart:convert';
import 'dart:typed_data';

import 'package:vsdk/p2p_device/p2p_command.dart';

mixin PlanCommand on P2PCommand {
  Map? whiteLightPlanData;

  Future<bool> getWhiteLightPlan({int timeout = 5}) async {
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2017&command=11&mark=212&type=5&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2017;") &&
              str.contains("command=11;") &&
              str.contains("type=5;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        if (data.containsKey("light_plan_enable")) {
          whiteLightPlanData = data;
        }
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> setWhiteLightPlan(
      {required List records, required int enable, int timeout = 5}) async {
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2017&command=5&mark=212&"
        "light_plan1=${records[0]}&"
        "light_plan2=${records[1]}&"
        "light_plan3=${records[2]}&"
        "light_plan4=${records[3]}&"
        "light_plan5=${records[4]}&"
        "light_plan6=${records[5]}&"
        "light_plan7=${records[6]}&"
        "light_plan8=${records[7]}&"
        "light_plan9=${records[8]}&"
        "light_plan10=${records[9]}&"
        "light_plan11=${records[10]}&"
        "light_plan12=${records[11]}&"
        "light_plan13=${records[12]}&"
        "light_plan14=${records[13]}&"
        "light_plan15=${records[14]}&"
        "light_plan16=${records[15]}&"
        "light_plan17=${records[16]}&"
        "light_plan18=${records[17]}&"
        "light_plan19=${records[18]}&"
        "light_plan20=${records[19]}&"
        "light_plan21=${records[20]}&"
        "light_plan_enable=$enable&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
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

  Map? motionAlarmPlanData;

  Future<bool> getMotionAlarmPlan({int timeout = 5}) async {
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2017&command=11&mark=212&type=2&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2017;") &&
              str.contains("command=11;") &&
              str.contains("type=2;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        if (data.containsKey("motion_push_enable")) {
          motionAlarmPlanData = data;
        }
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> setMotionAlarmPlan(
      {required List records, required int enable, int timeout = 5}) async {
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2017&command=2&mark=212&"
        "motion_push_plan1=${records[0]}&"
        "motion_push_plan2=${records[1]}&"
        "motion_push_plan3=${records[2]}&"
        "motion_push_plan4=${records[3]}&"
        "motion_push_plan5=${records[4]}&"
        "motion_push_plan6=${records[5]}&"
        "motion_push_plan7=${records[6]}&"
        "motion_push_plan8=${records[7]}&"
        "motion_push_plan9=${records[8]}&"
        "motion_push_plan10=${records[9]}&"
        "motion_push_plan11=${records[10]}&"
        "motion_push_plan12=${records[11]}&"
        "motion_push_plan13=${records[12]}&"
        "motion_push_plan14=${records[13]}&"
        "motion_push_plan15=${records[14]}&"
        "motion_push_plan16=${records[15]}&"
        "motion_push_plan17=${records[16]}&"
        "motion_push_plan18=${records[17]}&"
        "motion_push_plan19=${records[18]}&"
        "motion_push_plan20=${records[19]}&"
        "motion_push_plan21=${records[20]}&"
        "motion_push_plan_enable=$enable&",
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
        if (data["status"] == "0" || data["result"] == "0") {
          return true;
        }
      }
    }
    return false;
  }

  ///获取绘制区域
  ///command 1:移动侦测区域, 3:人形侦测区域, 5:离岗侦测区域, 7:脸侦测区域, 9:人脸识别区域

  Map? customeZoneData;

  Future<bool> getAlarmCustomeZone(int command,
      {int timeout = 5, int sensor = 0}) async {
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2123&command=$command&sensor=${sensor}&",
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
        customeZoneData = data;
        return data["result"] == "0";
      }
    }
    return false;
  }

  ///设置侦测区域
  Future<bool> setAlarmCustomeZone(
      {required List records,
      required int command,
      int timeout = 5,
      int sensor = 0}) async {
    String reignString = "md_";
    switch (command) {
      case 0: //CustomAreaType_MoveDetect 设置移动侦测区域
        reignString = "md_";
        break;
      case 2: //CustomAreaType_HumanDetect 设置人形侦测区域
        reignString = "pd_";
        break;
      case 4: //CustomAreaType_OffDuty 设置离岗侦测区域
        reignString = "depart_";
        break;
      case 6: //CustomAreaType_FaceDetect  设置人脸侦测区域
        reignString = "face_detect_";
        break;
      case 8: //CustomAreaType_FaceDiscernment  设置人脸识别区域
        reignString = "face_recognition_";
        break;
      default:
        break;
    }

    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2123&command=$command&sensor=${sensor}&"
        "${reignString}reign0=${records[0]}&"
        "${reignString}reign1=${records[1]}&"
        "${reignString}reign2=${records[2]}&"
        "${reignString}reign3=${records[3]}&"
        "${reignString}reign4=${records[4]}&"
        "${reignString}reign5=${records[5]}&"
        "${reignString}reign6=${records[6]}&"
        "${reignString}reign7=${records[7]}&"
        "${reignString}reign8=${records[8]}&"
        "${reignString}reign9=${records[9]}&"
        "${reignString}reign10=${records[10]}&"
        "${reignString}reign11=${records[11]}&"
        "${reignString}reign12=${records[12]}&"
        "${reignString}reign13=${records[13]}&"
        "${reignString}reign14=${records[14]}&"
        "${reignString}reign15=${records[15]}&"
        "${reignString}reign16=${records[16]}&"
        "${reignString}reign17=${records[17]}&",
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
        if (data["status"] == "0" || data["result"] == "0") {
          return true;
        }
      }
    }
    return false;
  }

  ///实时录像计划指令
  ///获取实时计划录像
  Map? realTimeRecordPlanData;

  Future<bool> getReocrdPlan({int timeout = 5}) async {
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2017&command=11&mark=212&type=3&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2017;") &&
              str.contains("command=11;") &&
              str.contains("type=3;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        if (data.containsKey("record_plan_enable")) {
          realTimeRecordPlanData = data;
        }
        return data["result"] == "0";
      }
    }
    return false;
  }

  ///设置实时计划录像
  Future<bool> setReocrdPlan(
      {required List records, required int enable, int timeout = 5}) async {
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2017&command=3&mark=212&"
        "record_plan1=${records[0]}&"
        "record_plan2=${records[1]}&"
        "record_plan3=${records[2]}&"
        "record_plan4=${records[3]}&"
        "record_plan5=${records[4]}&"
        "record_plan6=${records[5]}&"
        "record_plan7=${records[6]}&"
        "record_plan8=${records[7]}&"
        "record_plan9=${records[8]}&"
        "record_plan10=${records[9]}&"
        "record_plan11=${records[10]}&"
        "record_plan12=${records[11]}&"
        "record_plan13=${records[12]}&"
        "record_plan14=${records[13]}&"
        "record_plan15=${records[14]}&"
        "record_plan16=${records[15]}&"
        "record_plan17=${records[16]}&"
        "record_plan18=${records[17]}&"
        "record_plan19=${records[18]}&"
        "record_plan20=${records[19]}&"
        "record_plan21=${records[20]}&"
        "record_plan_enable=$enable&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2017;") && str.contains("command=3;");
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

  ///侦测计划录像计划指令
  ///获取侦测计划录像
  Map? detectionRecordPlanData;

  Future<bool> getDetectionReocrdPlan({int timeout = 5}) async {
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2017&command=11&mark=212&type=1&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2017;") &&
              str.contains("command=11;") &&
              str.contains("type=1;");
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        if (data.containsKey("motion_record_enable")) {
          detectionRecordPlanData = data;
        }
        return data["result"] == "0";
      }
    }
    return false;
  }

  ///设置侦测计划录像
  Future<bool> setDetectionReocrdPlan(
      {required List records, required int enable, int timeout = 5}) async {
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2017&command=1&mark=212&"
        "motion_record_plan1=${records[0]}&"
        "motion_record_plan2=${records[1]}&"
        "motion_record_plan3=${records[2]}&"
        "motion_record_plan4=${records[3]}&"
        "motion_record_plan5=${records[4]}&"
        "motion_record_plan6=${records[5]}&"
        "motion_record_plan7=${records[6]}&"
        "motion_record_plan8=${records[7]}&"
        "motion_record_plan9=${records[8]}&"
        "motion_record_plan10=${records[9]}&"
        "motion_record_plan11=${records[10]}&"
        "motion_record_plan12=${records[11]}&"
        "motion_record_plan13=${records[12]}&"
        "motion_record_plan14=${records[13]}&"
        "motion_record_plan15=${records[14]}&"
        "motion_record_plan16=${records[15]}&"
        "motion_record_plan17=${records[16]}&"
        "motion_record_plan18=${records[17]}&"
        "motion_record_plan19=${records[18]}&"
        "motion_record_plan20=${records[19]}&"
        "motion_record_plan21=${records[20]}&"
        "motion_record_plan_enable=$enable&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2017;") && str.contains("command=1;");
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
