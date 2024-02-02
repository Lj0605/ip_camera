import 'dart:async';
import 'dart:typed_data';

import 'package:vsdk/camera_device/commands/camera_command.dart';
import 'package:vsdk/p2p_device/p2p_command.dart';
import 'package:vsdk/p2p_device/p2p_device.dart';

import '../../app_p2p_api.dart';

class StatusResult {
  bool? isSuccess;
  int? cmd;

  String? result;
  String? alias;
  String? deviceid;

  // ignore: non_constant_identifier_names
  String? sys_ver;

  // ignore: non_constant_identifier_names
  String? app_version;

  // ignore: non_constant_identifier_names
  String? oem_id;

  // ignore: non_constant_identifier_names
  String? current_users;

  // ignore: non_constant_identifier_names
  String? max_support_users;
  String? now;

  // ignore: non_constant_identifier_names
  String? alarm_status;

  // ignore: non_constant_identifier_names
  String? upnp_status;

  // ignore: non_constant_identifier_names
  String? batteryRate;
  String? isCharge;
  String? dnsenable;
  String? osdenable;

  // ignore: non_constant_identifier_names
  String? syswifi_mode;
  String? mac;
  String? wifimac;
  String? sdstatus;

  // ignore: non_constant_identifier_names
  String? record_sd_status;

  // ignore: non_constant_identifier_names
  String? dns_status;
  String? internet;
  String? p2pstatus;
  String? devicetype;
  String? devicesubtype;
  String? externwifi;
  String? encrypt;
  String? under;
  String? sdtotal;
  String? sdfree;
  String? sdlevel;

  // ignore: non_constant_identifier_names
  String? timeplan_ver;

  // ignore: non_constant_identifier_names
  String? camera_type;

  // ignore: non_constant_identifier_names
  String? params_md5;

  // ignore: non_constant_identifier_names
  String? pwd_change_realtime;

  // ignore: non_constant_identifier_names
  String? ircut_forceon;
  String? hardwareTestFunc;

  // ignore: non_constant_identifier_names
  String? customer_code;
  String? pixel;
  String? cameraMode;
  String? haveWifi;
  String? haveMic;
  String? haveHorn;
  String? haveMotor;
  String? haveTf;
  String? support_pir_level;

  // ignore: non_constant_identifier_names
  String? DualAuthentication;

  // ignore: non_constant_identifier_names
  String? support_cryDetect;

  // ignore: non_constant_identifier_names
  String? support_rtspTls;

  // ignore: non_constant_identifier_names
  String? support_focus;

  // ignore: non_constant_identifier_names
  String? support_privacy_pos;

  // ignore: non_constant_identifier_names
  String? support_vuid;
  String? realdeviceid;
  String? vuidResult;

  // ignore: non_constant_identifier_names
  String? support_humanDetect;

  // ignore: non_constant_identifier_names
  String? support_h264_h265_shift;

  // ignore: non_constant_identifier_names
  String? support_pixel_shift;

  // ignore: non_constant_identifier_names
  String? wifi_change_realtime;

  // ignore: non_constant_identifier_names
  String? support_smokeDetect;

  // ignore: non_constant_identifier_names
  String? support_departDetect;

  // ignore: non_constant_identifier_names
  String? support_Face_Recognition;

  // ignore: non_constant_identifier_names
  String? support_faceSearch;

  // ignore: non_constant_identifier_names
  String? support_faceDetect;

  // ignore: non_constant_identifier_names
  String? support_humanoidFrame;

  // ignore: non_constant_identifier_names
  String? support_voiceTypedef;

  // ignore: non_constant_identifier_names
  String? support_motionArea;

  // ignore: non_constant_identifier_names
  String? support_4G_module;

  // ignore: non_constant_identifier_names
  String? support_mode_switch;

  // ignore: non_constant_identifier_names
  String? support_low_power;

  // ignore: non_constant_identifier_names
  String? EchoCancellationVer;

  // ignore: non_constant_identifier_names
  String? support_led_hidden_mode;

  // ignore: non_constant_identifier_names
  String? support_audio_g711a;

  //是否为门铃 1:有门铃按键 0:没有门铃按键
  String? haveDoorBell;

  //1-->支持 PIR 唤醒后人形侦测双鉴定 2-->支持 PIR 唤醒后移动侦测双鉴定
  String? suport_wakeup_correction;

  String? support_Pir_Distance_Adjust;

  String? support_PeopleDetection;

  //（双重认证返回）双重认证明文开关 0 是关闭 1 是打开
  String? ExUserSwitch;

  //support_Plaintext_Pwd: 0,不支持明文密码
  String? support_Plaintext_Pwd;

  //MaxZoomMultiple 支持最大的变焦
  String? MaxZoomMultiple;

  //CurZoomMultiple 当前的变焦倍数
  String? CurZoomMultiple;

  //全彩夜视
  String? support_full_color_night_vision_mode;

  //是否支持远程一键开机
  String? support_Remote_PowerOnOff_Switch;

  //是否支持wifi穿墙增强模式
  String? support_WiFi_Enhanced_Mode;

  //是否支持白光灯/红外灯控制参数
  String? support_WhiteLed_Ctrl;

  //白光灯是否亮灯
  String? whiteledstate;

  //是否支持智能电量
  String? support_Smart_Electricity_Sleep;

  //是否支持单片机MCU
  String? scm_version;

  String? support_osd_adjustment;

  //检测间隔
  String? support_SleepCheckInterval;

  //徘徊检测
  String? support_LingerCheck;

  //支持看守位
  String? support_ptz_guard;

  //支持防拆报警
  String? support_tamper_setting;

  //支持tf录像分辨率切换
  String? support_record_resolution_switch;

  //是否隐藏白光灯
  String? support_manual_light;

  //关闭录像模式选择
  String? recordmod;

  //关闭智能侦测定时
  String? smartdetecttime;

  //是否支持预置位自动巡航
  String? support_preset_auto;

  //是否支持预置位定时计划和线路
  String? support_presetCruise;

  //是否支持多目
  String? support_binocular;

  //镜头数量
  String? binocular_num;

  //长焦倍数
  String? binocular_zoom;

  //当前的镜头 0：默认 1：长焦
  String? binocular_value;

  //微功耗
  String? support_micro_power;

  //TF Card Time Line
  String? support_time_line;

  //其中[bit 0 -> 低功耗 bit 1 -> 持续工作 bit 2 ->超低功耗 bit 3 ->微功耗]
  String? support_new_low_power;

  String? support_presetRoi;

  String? wifi_signal_quality;

  String? preset_value;

  String? watch_preset;

  String? preset_cruise_status;

  String? preset_cruise_status_h;

  String? preset_cruise_status_v;

  String? support_pininpic; // T31枪球

  String? support_mutil_sensor_stream; //T40枪球

  String? pininpic_sensor; //镜头0 1

  List<int> binoculars = [];

  int? binocular_offset_x;

  int? binocular_offset_y;

  String? support_auto_record_mode; //自动录像模式

  String? support_humanoid_zoom; //人形变倍追踪

  String? center_status; //云台矫正

  String? support_record_type_seach; //TF卡录像文件否支持日期查询

  String? support_fire_smoke; //烟火监测

  String? fire_smoke_version; //烟火监测版本号

  String? support_area; //烟火监测版本号

  String? preset_cruise_curpos; //当前的巡航预置位

  String? gblinkage_enable; // 0 不显示  1 开关开启  2 开关关闭

  String? sirenStatus; //警笛

  String? support_mode_AiDetect; //（按位计算：011代表车和人， 010代表车， 001代表人，后续可扩充第三位包裹）

  String? support_pure_white_light; //为1时，说明是纯白光模式

  String? support_fix_sensor; //固定镜头

  String? start_or_stop_record_status; //录像

  String? splitScreen; //二目转三目

  Map? sourceData;

  StatusResult.form(CommandResult? commandResult) {
    isSuccess = false;
    if (commandResult != null && commandResult.isSuccess == true) {
      isSuccess = true;
      cmd = commandResult.cmd;
      try {
        Map data = commandResult.getMap();
        sourceData = data;
        result = data["result"];
        alias = data["alias"];
        deviceid = data["deviceid"];
        sys_ver = data["sys_ver"];
        current_users = data["current_users"];
        max_support_users = data["max_support_users"];
        app_version = data["app_version"];
        oem_id = data["oem_id"];
        now = data["now"];
        alarm_status = data["alarm_status"];
        upnp_status = data["upnp_status"];
        dnsenable = data["dnsenable"];
        osdenable = data["osdenable"];
        syswifi_mode = data["syswifi_mode"];
        mac = data["mac"];
        wifimac = data["wifimac"];
        sdstatus = data["sdstatus"];
        record_sd_status = data["record_sd_status"];
        dns_status = data["dns_status"];
        internet = data["internet"];
        p2pstatus = data["p2pstatus"];
        devicetype = data["devicetype"];
        devicesubtype = data["devicesubtype"];
        externwifi = data["externwifi"];
        encrypt = data["encrypt"];
        under = data["under"];
        sdtotal = data["sdtotal"];
        sdfree = data["sdfree"];
        sdlevel = data["sdlevel"];
        timeplan_ver = data["timeplan_ver"];
        batteryRate = data["batteryRate"];
        isCharge = data["isCharge"];
        camera_type = data["camera_type"];
        params_md5 = data["params_md5"];
        pwd_change_realtime = data["pwd_change_realtime"];
        ircut_forceon = data["ircut_forceon"];
        hardwareTestFunc = data["hardwareTestFunc"];
        customer_code = data["customer_code"];
        pixel = data["pixel"];
        cameraMode = data["cameraMode"];
        haveWifi = data["haveWifi"];
        haveMic = data["haveMic"];
        haveHorn = data["haveHorn"];
        haveMotor = data["haveMotor"];
        DualAuthentication = data["DualAuthentication"];
        support_cryDetect = data["support_cryDetect"];
        support_rtspTls = data["support_rtspTls"];
        support_focus = data["support_focus"];
        support_privacy_pos = data["support_privacy_pos"];
        support_vuid = data["support_vuid"];
        realdeviceid = data["realdeviceid"];
        support_humanDetect = data["support_humanDetect"];
        support_h264_h265_shift = data["support_h264_h265_shift"];
        support_pixel_shift = data["support_pixel_shift"];
        wifi_change_realtime = data["wifi_change_realtime"];
        support_smokeDetect = data["support_smokeDetect"];
        support_departDetect = data["support_departDetect"];
        support_Face_Recognition = data["support_Face_Recognition"];
        support_faceSearch = data["support_faceSearch"];
        support_faceDetect = data["support_faceDetect"];
        support_humanoidFrame = data["support_humanoidFrame"];
        support_voiceTypedef = data["support_voiceTypedef"];
        support_motionArea = data["support_motionArea"];
        support_4G_module = data["support_4G_module"];
        support_low_power = data["support_low_power"];
        EchoCancellationVer = data["EchoCancellationVer"];
        support_led_hidden_mode = data["support_led_hidden_mode"];
        support_mode_switch = data["support_mode_switch"];
        support_audio_g711a = data["support_g711a"];
        haveDoorBell = data["haveDoorBell"];
        suport_wakeup_correction = data["suport_wakeup_correction"];
        support_Pir_Distance_Adjust = data["support_Pir_Distance_Adjust"];
        support_PeopleDetection = data["support_PeopleDetection"];
        ExUserSwitch = data["ExUserSwitch"];
        support_Plaintext_Pwd = data["support_Plaintext_Pwd"];
        MaxZoomMultiple = data["MaxZoomMultiple"];
        CurZoomMultiple = data["CurZoomMultiple"];
        support_full_color_night_vision_mode =
            data["support_full_color_night_vision_mode"];
        support_Remote_PowerOnOff_Switch =
            data["support_Remote_PowerOnOff_Switch"];
        support_WiFi_Enhanced_Mode = data["support_WiFi_Enhanced_Mode"];
        support_WhiteLed_Ctrl = data["support_WhiteLed_Ctrl"];
        whiteledstate = data["whiteledstate"];
        support_Smart_Electricity_Sleep =
            data["support_Smart_Electricity_Sleep"];
        scm_version = data["scm_version"];
        support_osd_adjustment = data["support_osd_adjustment"];
        support_SleepCheckInterval = data["support_SleepCheckInterval"];
        support_LingerCheck = data["support_LingerCheck"];
        support_ptz_guard = data["support_ptz_guard"];
        support_tamper_setting = data["support_tamper_setting"];
        support_record_resolution_switch =
            data["support_record_resolution_switch"];
        support_manual_light = data["support_manual_light"] ?? "";
        recordmod = data["recordmod"] ?? "1";
        smartdetecttime = data["smartdetecttime"] ?? "1";
        support_preset_auto = data["support_preset_auto"];
        support_presetCruise = data["support_presetCruise"];
        support_binocular = data["support_binocular"];
        binocular_zoom = data["binocular_zoom"];
        binocular_value = data["binocular_value"];
        support_micro_power = data["support_micro_power"];
        support_time_line = data["support_time_line"];

        support_pir_level = data["support_pir_level"];
        support_new_low_power = data["support_new_low_power"];
        support_presetRoi = data["support_presetRoi"];
        wifi_signal_quality = data["wifi_signal_quality"];

        preset_value = data["preset_value"];
        watch_preset = data["watch_preset"];
        preset_cruise_status = data["preset_cruise_status"];
        preset_cruise_status_h = data["preset_cruise_status_h"];
        preset_cruise_status_v = data["preset_cruise_status_v"];

        support_pininpic = data['support_pininpic'];
        support_mutil_sensor_stream = data['support_mutil_sensor_stream'];
        pininpic_sensor = data['pininpic_sensor'];
        support_auto_record_mode = data['support_auto_record_mode'];
        support_humanoid_zoom = data['support_humanoid_zoom'];
        center_status = data['center_status'];
        support_record_type_seach = data['support_record_type_seach'];

        support_fire_smoke = data['support_fire_smoke'];
        fire_smoke_version = data['fire_smoke_version'];
        preset_cruise_curpos = data['preset_cruise_curpos'];
        gblinkage_enable = data['gblinkage_enable'];
        support_area = data['support_area'];
        sirenStatus = data['sirenStatus'];
        int supportBinocular = int.tryParse(support_binocular ?? "0") ?? 0;
        if (supportBinocular > 0) {
          binocular_offset_x =
              int.tryParse(data["binocular_offset_x"] ?? "0") ?? 0;
          binocular_offset_y =
              int.tryParse(data["binocular_offset_y"] ?? "0") ?? 0;
          binocular_num = data["binocular_num"];
          int binocularNum = int.tryParse(binocular_num ?? "0") ?? 0;
          binoculars = [];
          for (int i = 0; i < binocularNum; i++) {
            String? binocular_zoom = data["binocular_zoom$i"];
            if (binocular_zoom != null) {
              int? binocularZoom = int.tryParse(binocular_zoom);
              if (binocularZoom != null) {
                binoculars.add(binocularZoom);
              }
            }
          }
        }

        support_mode_AiDetect = data['support_mode_AiDetect'];
        support_pure_white_light = data['support_pure_white_light'];
        support_fix_sensor = data["support_fix_sensor"];
        start_or_stop_record_status = data["start_or_stop_record_status"];
        splitScreen = data["splitScreen"];
      } catch (err) {}
    }
  }

  @override
  String toString() {
    return "$sourceData";
  }
}

typedef StatusChanged = void Function(P2PBasisDevice device, StatusResult?);

mixin StatusCommand on P2PCommand {
  StatusResult? _statusResult;

  StatusResult? get statusResult => _statusResult;

  set statusResult(StatusResult? value) {
    _statusResult = value;
    notifyListeners<StatusChanged>((StatusChanged func) {
      func(this, _statusResult);
    });
  }

  String displayPassword(String password) {
    if (password == null) return "null";
    if (password == "888888") return "初始密码";
    if (password.length > 6)
      return "${password.substring(0, 2)}****${password.substring(password.length - 2)}";
    if (password.length > 3)
      return "****${password.substring(password.length - 2)}";
    return "随机密码***$password";
  }

  /// 登录指令
  Future<StatusResult?> login(String username, String password,
      {int timeout = 5}) async {
    var status = null;
    if (p2pConnectState != ClientConnectState.CONNECT_STATUS_ONLINE) {
      return status;
    }

    AppP2PApi().clientLogin(clientPtr!, username, password);
    bool ret = await AppP2PApi().clientLogin(clientPtr!, username, password);
    if (ret == true) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        if (cmd == 24577) return true;
        if (cmd == 24785) {
          CommandResult cmdResult = CommandResult(true, cmd, data);
          var map = cmdResult.getMap();
          if (map == null) return false;
          if (map.containsKey("result") && map.keys.length == 1) return true;
          if (map.containsKey("result") &&
              map.containsKey("current_users") &&
              map.containsKey("max_support_users")) return true;
        }
        return false;
      }, timeout);
      if (result.isSuccess) {
        statusResult = StatusResult.form(result);
        status = statusResult;
      }
    }

    return status;
  }

  /// 获取设备状态
  /// @param [cache] 是否使用缓存,默认为true 使用缓存
  Future<StatusResult?> getStatus({int timeout = 5, bool cache = true}) async {
    if (cache) {
      return statusResult;
    }
    var getstatus = 'get_status.cgi?';
    if (isVirtualId) {
      getstatus = 'get_status.cgi?vuid=$id&';
    }

    bool ret = await writeCgi(getstatus, timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24577;
      }, timeout);
      if (result.isSuccess) {
        statusResult = StatusResult.form(result);
        return statusResult;
      }
    }
    return statusResult;
  }
}
