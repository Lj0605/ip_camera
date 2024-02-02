import 'dart:typed_data';
import 'package:vsdk/p2p_device/p2p_command.dart';

class RecordResult {
  RecordResult();

  bool isSuccess = false;
  int cmd = 0;

  late String result;

  // ignore: non_constant_identifier_names
  late String enc_size; //跟resolution一致
  // ignore: non_constant_identifier_names
  late String enc_framerate; //主码流帧率
  // ignore: non_constant_identifier_names
  late String enc_keyframe; //主码流关键帧
  // ignore: non_constant_identifier_names
  late String enc_quant; //主码流画质
  // ignore: non_constant_identifier_names
  late String enc_bitrate; //主码流码率
  // ignore: non_constant_identifier_names
  late String enc_ratemode; //主码流码流模式
  // ignore: non_constant_identifier_names
  late String sub_enc_size; //跟resolutionsub一致
  // ignore: non_constant_identifier_names
  late String sub_enc_framerate; //次码流帧率
  // ignore: non_constant_identifier_names
  late String sub_enc_keyframe; //次码流关键帧
  // ignore: non_constant_identifier_names
  late String sub_enc_quant; //次码流画质
  // ignore: non_constant_identifier_names
  late String sub_enc_bitrate; //次码流码率
  // ignore: non_constant_identifier_names
  late String sub_enc_ratemode; //次码流码流模式
  // ignore: non_constant_identifier_names
  late String sub_sub_enc_size; //跟resolutionsubsub一致
  // ignore: non_constant_identifier_names
  late String sub_sub_enc_framerate; //次次码流帧率
  // ignore: non_constant_identifier_names
  late String sub_sub_enc_keyframe; //次次码流关键帧
  // ignore: non_constant_identifier_names
  late String sub_sub_enc_quant; //次次码流画质
  // ignore: non_constant_identifier_names
  late String sub_sub_enc_bitrate; //次次码流码率
  // ignore: non_constant_identifier_names
  late String sub_sub_enc_ratemode; //次次码流码流模式
  // ignore: non_constant_identifier_names
  late String record_audio; //表示录制音频0:不录制音频1:录制音频
  // ignore: non_constant_identifier_names
  late String record_cover_enable; //表示录像覆盖0->表示不允许覆盖1->表示允许覆盖
  // ignore: non_constant_identifier_names
  late String record_timer; //表示录像时长
  // ignore: non_constant_identifier_names
  late String record_size; //保留
  // ignore: non_constant_identifier_names
  late String record_time_enable;

  // ignore: non_constant_identifier_names
  late String tf_enable; //TF卡挂载状态
  // ignore: non_constant_identifier_names
  late String record_chnl; //录像通道选择0：主码流录像1：次码流录像2：次次码流录像
  // ignore: non_constant_identifier_names
  late String sdtotal; //TF卡总容量
  // ignore: non_constant_identifier_names
  late String sdfree; //TF卡剩余容量
  // ignore: non_constant_identifier_names
  late String record_sd_status; //TF卡状态

  Map sourceData = {};

  RecordResult.form(CommandResult? commandResult) {
    isSuccess = false;
    if (commandResult != null && commandResult.isSuccess == true) {
      isSuccess = true;
      cmd = commandResult.cmd;
      try {
        Map data = commandResult.getMap();
        sourceData = data;
        result = data["result"];
        enc_size = data["enc_size"];
        enc_framerate = data["enc_framerate"];
        enc_keyframe = data["enc_keyframe"];
        enc_quant = data["enc_quant"];
        enc_bitrate = data["enc_bitrate"];
        enc_ratemode = data["enc_ratemode"];
        sub_enc_size = data["sub_enc_size"];
        sub_enc_framerate = data["sub_enc_framerate"];
        sub_enc_keyframe = data["sub_enc_keyframe"];
        sub_enc_quant = data["sub_enc_quant"];
        sub_enc_bitrate = data["sub_enc_bitrate"];
        sub_enc_ratemode = data["sub_enc_ratemode"];
        sub_sub_enc_size = data["sub_sub_enc_size"];
        sub_sub_enc_framerate = data["sub_sub_enc_framerate"];
        sub_sub_enc_keyframe = data["sub_sub_enc_keyframe"];
        sub_sub_enc_quant = data["sub_sub_enc_quant"];
        record_sd_status = data["record_sd_status"];
        sub_sub_enc_bitrate = data["sub_sub_enc_bitrate"];
        sub_sub_enc_ratemode = data["sub_sub_enc_ratemode"];
        record_audio = data["record_audio"];
        record_cover_enable = data["record_cover_enable"];
        record_timer = data["record_timer"];
        record_size = data["record_size"];
        record_time_enable = data["record_time_enable"];
        tf_enable = data["tf_enable"];
        record_chnl = data["record_chnl"];
        sdtotal = data["sdtotal"];
        sdfree = data["sdfree"];
        record_sd_status = data["record_sd_status"];
      } catch (Exception) {}
    }
  }

  @override
  String toString() {
    return "$sourceData";
  }
}

mixin RecordCommand on P2PCommand {
  RecordResult recordResult = RecordResult();

  Future<bool> getRecordParam({int timeout = 5}) async {
    bool ret = await writeCgi("get_record.cgi?", timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24582;
      }, timeout);
      if (result.isSuccess) {
        recordResult = RecordResult.form(result);
        if (recordResult.result == "0") {
          return true;
        }
      }
    }
    return false;
  }

  Future<bool> changedRecordVoice(bool enable, {int timeout = 5}) async {
    //record_cover_enable=1&record_size=0&&record_timer=15 这个字段去掉
    bool ret = await writeCgi(
        "set_recordsch.cgi?record_audio=${enable ? 1 : 0}&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24617;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          recordResult.record_audio = enable ? "1" : "0";
          return true;
        }
      }
    }
    return false;
  }

  /// 格式化SD 卡
  Future<bool> formatSD({int timeout = 5}) async {
    bool ret = await writeCgi("set_formatsd.cgi?", timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24616;
      }, timeout);
      if (result.isSuccess) {
        if (result.getMap()["result"] == "0") {
          recordResult.record_sd_status = "4";
          return true;
        }
      }
    }
    return false;
  }

  /// 实时录像
  Future<bool> setRecordParams(int enable, {int timeout = 5}) async {
    String strCMD;
    if (enable == 1) {
      strCMD = "set_recordsch.cgi?record_cover=1&"
          "record_timer=${recordResult.record_timer}&"
          "time_schedule_enable=$enable&"
          "schedule_sun_0=-1&"
          "schedule_sun_1=-1&"
          "schedule_sun_2=-1&"
          "schedule_mon_0=-1&"
          "schedule_mon_1=-1&"
          "schedule_mon_2=-1&"
          "schedule_tue_0=-1&"
          "schedule_tue_1=-1&"
          "schedule_tue_2=-1&"
          "schedule_wed_0=-1&"
          "schedule_wed_1=-1&"
          "schedule_wed_2=-1&"
          "schedule_thu_0=-1&"
          "schedule_thu_1=-1&"
          "schedule_thu_2=-1&"
          "schedule_fri_0=-1&"
          "schedule_fri_1=-1&"
          "schedule_fri_2=-1&"
          "schedule_sat_0=-1&"
          "schedule_sat_1=-1&"
          "schedule_sat_2=-1&"
          "record_audio=${recordResult.record_audio}&";
    } else {
      strCMD = "set_recordsch.cgi?record_cover=1&"
          "record_timer=${recordResult.record_timer}&"
          "time_schedule_enable=$enable&"
          "schedule_sun_0=0&"
          "schedule_sun_1=0&"
          "schedule_sun_2=0&"
          "schedule_mon_0=0&"
          "schedule_mon_1=0&"
          "schedule_mon_2=0&"
          "schedule_tue_0=0&"
          "schedule_tue_1=0&"
          "schedule_tue_2=0&"
          "schedule_wed_0=0&"
          "schedule_wed_1=0&"
          "schedule_wed_2=0&"
          "schedule_thu_0=0&"
          "schedule_thu_1=0&"
          "schedule_thu_2=0&"
          "schedule_fri_0=0&"
          "schedule_fri_1=0&"
          "schedule_fri_2=0&"
          "schedule_sat_0=0&"
          "schedule_sat_1=0&"
          "schedule_sat_2=0&"
          "record_audio=${recordResult.record_audio}&";
    }

    bool ret = await writeCgi(strCMD, timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24617;
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
