import 'dart:async';
import 'dart:convert';

import 'package:vsdk/p2p_device/p2p_command.dart';
import 'package:vsdk/p2p_device/p2p_device.dart';

import 'camera_command.dart';

enum VideoResolution {
  none,
  high, //高分辨率
  general, //普通分辨率.默认
  unknown, // 未知分辨率
  low, //低分辨率
  superHD, //超高清
}

enum VideoDirection {
  none,
  mirror,
  flip,
  mirrorAndFlip,
}

typedef VideoStateChanged = void Function(P2PBasisDevice device,
    VideoResolution resolution, VideoDirection direction);

mixin VideoCommand on CameraCommand {
  VideoResolution _resolution = VideoResolution.general;

  VideoResolution get resolution => _resolution;

  set resolution(VideoResolution value) {
    if (value != _resolution) {
      _resolution = value;
      notifyListeners<VideoStateChanged>((VideoStateChanged func) {
        func(this, _resolution, _direction);
      });
    }
  }

  VideoDirection _direction = VideoDirection.none;

  VideoDirection get direction => _direction;

  set direction(VideoDirection value) {
    if (value != direction) {
      _direction = value;
      notifyListeners<VideoStateChanged>((VideoStateChanged func) {
        func(this, _resolution, _direction);
      });
    }
  }

  Future<bool> startStream({required VideoResolution resolution}) async {
    resolution = resolution ?? this.resolution;
    int index = resolution.index;
    if (resolution == VideoResolution.superHD) {
      index = 100;
    }

    bool ret = await writeCgi("livestream.cgi?streamid=10&substream=$index&");
    print("startStream ret${ret}");
    if (ret == true) {
      waitCommandResult((cmd, data) {
        return cmd == 24631;
      }, 3)
          .then((result) {
        ret = result?.isSuccess ?? false;
      });
      this.resolution = resolution;
    } else {}
    return ret;
  }

  Future<bool> stopStream() async {
    bool ret = await writeCgi("livestream.cgi?streamid=16&substream=0&");
    if (ret == true) {
      var result = await waitCommandResult((cmd, data) {
        return cmd == 24631;
      }, 3);
      ret = result?.isSuccess ?? false;

      return ret;
    }
    return ret;
  }

  Future<bool> changeResolution(VideoResolution resolution,
      {int timeout = 5}) async {
    resolution = resolution ?? this.resolution;
    if (this.resolution != resolution) {
      int index = resolution.index;
      if (resolution == VideoResolution.superHD) {
        index = 100;
      }
      bool ret = await writeCgi("camera_control.cgi?param=16&value=$index&");
      if (ret == true) {
        CommandResult result = await waitCommandResult((cmd, data) {
          return cmd == 24594;
        }, timeout);
        if (result.isSuccess == true) {
          this.resolution = resolution;
        }
        return result.isSuccess;
      }
      return false;
    }
    return true;
  }

  Future<bool> changeDirection(VideoDirection direction,
      {int timeout = 5}) async {
    if (direction == null) {
      return false;
    }
    if (this.direction != direction) {
      bool ret = await writeCgi(
          "camera_control.cgi?param=5&value=${direction.index}&");
      if (ret == true) {
        CommandResult result = await waitCommandResult((cmd, data) {
          return cmd == 24594;
        }, timeout);
        if (result.isSuccess == true) {
          this.direction = direction;
        }
        return result.isSuccess;
      }
      return false;
    }
    return true;
  }

  int brightness = (255 * 0.5).floor();

  Future<bool> changeBrightness(int value, {int timeout = 5}) async {
    if (value == null) {
      return false;
    }
    bool ret = await writeCgi("camera_control.cgi?param=1&value=$value&");
    if (ret == true) {
      CommandResult result = await waitCommandResult((cmd, data) {
        return cmd == 24594;
      }, timeout);
      if (result.isSuccess) {
        brightness = value;
      }
      return result.isSuccess;
    }
    return false;
  }

  int contrast = (255 * 0.5).floor();

  Future<bool> changeContrast(int value, {int timeout = 5}) async {
    if (value == null) {
      return false;
    }
    bool ret = await writeCgi("camera_control.cgi?param=2&value=$value&");
    if (ret == true) {
      CommandResult result = await waitCommandResult((cmd, data) {
        return cmd == 24594;
      }, timeout);
      if (result.isSuccess) {
        contrast = value;
      }
      return result.isSuccess;
    }
    return false;
  }

  int ircut = 1;

  // ignore: non_constant_identifier_names
  int night_vision_mode = 0; // 1夜视模式为全彩  0黑白
  int full_color_mode = 2; //全彩子项为定时
  int full_color_show = 7; //全彩子项全显示 二进制的
  int full_color_default = 1; //全彩定时  是否勾选默认  0 使用自定义  1 使用默认
  var full_color_start_hw = 19; //全彩定时 产测配置开始时间
  var full_color_end_hw = 8; //全彩定时 产测配置结束时间
  int full_color_start = 20; //全彩定时 APP自定义开始时间
  int full_color_end = 8; //全彩定时 APP自定义结束时间

  Future<bool> changeNightVision(int value, {int timeout = 5}) async {
    if (value == null) {
      return false;
    }
    bool ret = await writeCgi("camera_control.cgi?param=14&value=$value&");
    if (ret == true) {
      CommandResult result = await waitCommandResult((cmd, data) {
        return cmd == 24594;
      }, timeout);
      if (result.isSuccess) {
        ircut = value;
      }
      return result.isSuccess;
    }
    return false;
  }

  Future<bool> fullColorChangeNightVision(int value, {int timeout = 5}) async {
    if (value == null) {
      return false;
    }
    bool ret = await writeCgi("camera_control.cgi?param=33&value=$value&");
    if (ret == true) {
      CommandResult result = await waitCommandResult((cmd, data) {
        return cmd == 24594;
      }, timeout);
      if (result.isSuccess) {
        ircut = value;
      }
      return result.isSuccess;
    }
    return false;
  }

  Future<bool> fullColorChangeNightVisionChild(int value,
      {int timeout = 5}) async {
    if (value == null) {
      return false;
    }
    bool ret = await writeCgi(
        "camera_control.cgi?param=37&value=0&fullcolormode=$value&");
    if (ret == true) {
      CommandResult result = await waitCommandResult((cmd, data) {
        return cmd == 24594;
      }, timeout);
      return result.isSuccess;
    }
    return false;
  }

  //全彩定时默认设置
  Future<bool> fullColorTimingDefault(int value, {int timeout = 5}) async {
    if (value == null) {
      return false;
    }
    bool ret = await writeCgi(
        "camera_control.cgi?param=37&value=0&fullcolormode=2&fullcolordefault=1&");
    if (ret == true) {
      CommandResult result = await waitCommandResult((cmd, data) {
        return cmd == 24594;
      }, timeout);
      return result.isSuccess;
    }
    return false;
  }

  //全彩定时自定义设置
  Future<bool> fullColorTiming(int start, int end, {int timeout = 5}) async {
    if (start == null && end == null) {
      return false;
    }
    bool ret = await writeCgi(
        "camera_control.cgi?param=37&value=0&fullcolormode=2&fullcolordefault=0&fullcolorstart=$start&fullcolorstop=$end");
    if (ret == true) {
      CommandResult result = await waitCommandResult((cmd, data) {
        return cmd == 24594;
      }, timeout);
      return result.isSuccess;
    }
    return false;
  }

  int? lightMode;
  int? involume;
  int? outvolume;

  Future<bool> changeVolume(int param, int value, {int timeout = 5}) async {
    if (value == null) {
      return false;
    }
    bool ret = await writeCgi("camera_control.cgi?param=$param&value=$value&");
    if (ret == true) {
      CommandResult result = await waitCommandResult((cmd, data) {
        return cmd == 24594;
      }, timeout);
      if (result.isSuccess) {
        lightMode = value;
      }
      return result.isSuccess;
    }
    return false;
  }

  Future<bool> changeLightMode(int value, {int timeout = 5}) async {
    if (value == null) {
      return false;
    }
    bool ret = await writeCgi("camera_control.cgi?param=3&value=$value&");
    if (ret == true) {
      CommandResult result = await waitCommandResult((cmd, data) {
        return cmd == 24594;
      }, timeout);
      if (result.isSuccess) {
        lightMode = value;
      }
      return result.isSuccess;
    }
    return false;
  }

  Future<bool> getCameraParams({int timeout = 5}) async {
    bool ret = await writeCgi("get_camera_params.cgi?");
    if (ret == true) {
      CommandResult result = await waitCommandResult((cmd, data) {
        return cmd == 24579;
      }, timeout);
      Map data = result.getMap();
      if (result.isSuccess) {
        this.contrast =
            int.tryParse(data["vcontrast"] ?? "") ?? (255 * 0.5).floor();
        this.brightness =
            int.tryParse(data["vbright"] ?? "") ?? (255 * 0.5).floor();
        try {
          this.direction =
              VideoDirection.values[int.tryParse(data["flip"] ?? "") ?? 0];
        } catch (e) {
          this.direction = VideoDirection.values[0];
        }
        this.ircut = int.tryParse(data["ircut"] ?? "") ?? 1;
        this.night_vision_mode =
            int.tryParse(data["night_vision_mode"] ?? "") ?? 0;
        //print"night_vision_mode ===========0>> " + night_vision_mode.toString());
        this.full_color_mode =
            int.tryParse(data["full_color_mode"] ?? "") ?? 0; //全彩子项为定时
        //print"full_color_mode ===========1>> " + full_color_mode.toString());
        this.full_color_show =
            int.tryParse(data["full_color_show"] ?? "") ?? 0; //全彩子项全显示 二进制的
        //print"full_color_show ===========2>> " + full_color_show.toString());
        this.full_color_default =
            int.tryParse(data["full_color_default"] ?? "") ??
                1; //全彩定时  是否勾选默认  0 使用自定义  1 使用默认
        //print"full_color_default ===========3>> " + full_color_default.toString());
        this.full_color_start_hw =
            int.tryParse(data["full_color_start_hw"] ?? "") ??
                0; //全彩定时 APP自定义开始时间

        this.full_color_end_hw =
            int.tryParse(data["full_color_end_hw"] ?? "") ??
                0; //全彩定时 APP自定义结束时间

        this.full_color_start =
            int.tryParse(data["full_color_start"] ?? "") ?? 0; //全彩定时 APP自定义开始时间
        //print"full_color_start ===========6>> " + full_color_start.toString());
        this.full_color_end =
            int.tryParse(data["full_color_end"] ?? "") ?? 0; //全彩定时 APP自定义结束时间
        //print"full_color_end ===========7>> " + full_color_end.toString());
        try {
          this.lightMode = int.tryParse(data["mode"] ?? "") ?? 0;
        } catch (e) {
          this.lightMode = 0;
        }
        this.osdEnable = int.tryParse(data["OSDEnable"] ?? "") ?? 0;
        this.involume = int.tryParse(data["involume"] ?? "") ?? 0;
        this.outvolume = int.tryParse(data["outvolume"] ?? "") ?? 0;
      }
      return result.isSuccess;
    }
    return false;
  }

  int? osdEnable;

  Future<bool> changeShowTime(int value, {int timeout = 5}) async {
    if (value == null) {
      return false;
    }
    bool ret = await writeCgi("set_misc.cgi?osdenable=$value&");
    if (ret == true) {
      CommandResult result = await waitCommandResult((cmd, data) {
        return true;
      }, timeout);
      if (result.isSuccess) {
        osdEnable = value;
      }
      return result.isSuccess;
    }
    return false;
  }

  int? videoFormat;

  Future<bool> changeVideoFormat(int value, {int timeout = 5}) async {
    if (value == null) {
      return false;
    }
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2105&command=2&videoFormat=$value&mark=112233445566_1234&");
    if (ret == true) {
      CommandResult result = await waitCommandResult((cmd, data) {
        return true;
      }, timeout);
      if (result.isSuccess) {
        videoFormat = value;
      }
      return result.isSuccess;
    }
    return false;
  }

  Future<bool> getVideoDecodingMode({int timeout = 5}) async {
    //解码模式
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2105&command=1&mark=112233445566_1234&");
    if (ret == true) {
      CommandResult result = await waitCommandResult((cmd, data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2105;") && str.contains("command=1;");
        }
        return false;
      }, timeout);
      Map data = result.getMap();
      if (result.isSuccess) {
        if (int.tryParse(data["cmd"] ?? "") == 2105) {
          this.videoFormat = int.tryParse(data["videoFormat"] ?? "") ?? 0;
        }
      }
      return result.isSuccess;
    }
    return false;
  }

  ///200w 还是300w 参数
  int? videoPix;

  Future<bool> changeVideoPix(int value, {int timeout = 5}) async {
    if (value == null) {
      return false;
    }
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2105&command=4&bPixel300=$value&mark=112233445566_1234&");
    if (ret == true) {
      CommandResult result = await waitCommandResult((cmd, data) {
        return true;
      }, timeout);
      if (result.isSuccess) {
        videoPix = value;
      }
      return result.isSuccess;
    }
    return false;
  }

  Future<bool> getVideoPix({int timeout = 5}) async {
    //解码模式
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2105&command=3&mark=112233445566_1234&");
    if (ret == true) {
      CommandResult result = await waitCommandResult((cmd, data) {
        if (cmd == 24785) {
          String str = utf8.decode(data);
          return str.contains("cmd=2105;") && str.contains("command=3;");
        }
        return false;
      }, timeout);
      Map data = result.getMap();
      if (result.isSuccess) {
        if (int.tryParse(data["cmd"] ?? "") == 2105) {
          this.videoPix = int.tryParse(data["bPixel300"] ?? "") ?? 0;
        }
      }
      return result.isSuccess;
    }
    return false;
  }

  ///双击坐标放大
  Future<bool> videoDoubleTap(int width, int height, int doublex, int doubley,
      {int timeout = 5}) async {
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2163&command=0&mark=112233445566_1234&width=$width&height=$height&x=$doublex&y=$doubley&");
    if (ret == true) {
      CommandResult result = await waitCommandResult((cmd, data) {
        return cmd == 24785;
      }, timeout);
      if (result.isSuccess) {
        return result.isSuccess;
      }
    }
    return false;
  }

  @override
  Future<void> deviceDestroy() async {
    super.deviceDestroy();
  }
}
