import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:ffi';

import 'app_dart.dart';

enum VideoSourceType {
  /// 文件源
  FILE_SOURCE,

  /// 设备实时源
  LIVE_SOURCE,

  /// 设备TF卡回放源
  CARD_SOURCE,

  /// 网络下载源
  NETWORK_SOURCE,

  /// TF卡时间轴回放源
  TimeLine_SOURCE,

  ///
  SUB_PLAYER_SOURCE,

  //SUB2_PLAYER_SOURCE,
}

abstract class VideoSource {
  final VideoSourceType sourceType;

  VideoSource(this.sourceType);

  dynamic getSource();
}

class FileVideoSource extends VideoSource {
  FileVideoSource(this.filePath) : super(VideoSourceType.FILE_SOURCE);
  final String filePath;

  @override
  getSource() {
    return filePath;
  }
}

class LiveVideoSource extends VideoSource {
  LiveVideoSource(this.clientPtr) : super(VideoSourceType.LIVE_SOURCE);
  final int clientPtr;

  @override
  getSource() {
    return clientPtr;
  }
}

class CardVideoSource extends VideoSource {
  CardVideoSource(this.clientPtr, this.size, {this.checkHead = 1})
      : super(VideoSourceType.CARD_SOURCE);
  final int clientPtr;
  final int size;
  final int checkHead;

  @override
  getSource() {
    return [clientPtr, size, checkHead];
  }
}

class TimeLineSource extends VideoSource {
  TimeLineSource(this.clientPtr) : super(VideoSourceType.TimeLine_SOURCE);
  final int clientPtr;

  @override
  getSource() {
    return [clientPtr];
  }
}

class NetworkVideoSource extends VideoSource {
  NetworkVideoSource(this.urls) : super(VideoSourceType.NETWORK_SOURCE);
  final List<String> urls;

  @override
  getSource() {
    return urls;
  }
}

class SubPlayerSource extends VideoSource {
  SubPlayerSource() : super(VideoSourceType.SUB_PLAYER_SOURCE);

  @override
  getSource() {}
}

// class Sub2PlayerSource extends VideoSource {
//   Sub2PlayerSource() : super(VideoSourceType.SUB2_PLAYER_SOURCE);
//
//   @override
//   getSource() {}
// }

enum VideoStatus { STOP, STARTING, PLAY, PAUSE }

enum VoiceStatus { PLAY, STOP }

enum RecordStatus { PLAY, STOP }

enum RecordEncoderType { ADPCM, G711, PCM }

enum SoundTouchType {
  /// 无效果
  TOUCH_0,

  /// 大叔
  TOUCH_1,

  /// 搞怪
  TOUCH_2
}

typedef CreatedCallback<T> = void Function(T? data);
typedef StateChangeCallback<T> = void Function(
    T? data,
    VideoStatus videoStatus,
    VoiceStatus voiceStatus,
    RecordStatus recordStatus,
    SoundTouchType touchType);
typedef ProgressChangeCallback<T> = void Function(T? data, int totalSec,
    int playSec, int progress, int loadState, int velocity);

typedef FocalChangeCallback<T> = void Function(T data, int focal);

class AppPlayerController<T> {
  static const MethodChannel app_player_channel =
      const MethodChannel('app_player');

  static const EventChannel app_player_event =
      const EventChannel("app_player/event");

  static Stream _eventStream = app_player_event.receiveBroadcastStream();

  static final DynamicLibrary playerLib = Platform.isAndroid
      ? DynamicLibrary.open('libOKSMARTPLAY.so')
      : DynamicLibrary.process();

  late void Function(
      int playerPtr,
      double minScale,
      double maxScale,
      int minFocal,
      int maxFocal,
      int direction,
      double threshold) appPlayerSetScale;
  late void Function(
      int playerPtr,
      double minScale,
      double maxScale,
      int minFocal,
      int maxFocal,
      int direction,
      double threshold,
      double x,
      double y) appPlayerSetScaleCenter;
  late void Function(int playerPtr, int channel, int key) appPlayerSetChannel;

  void scale(int direction, int minFocal, int maxFocal, double minScale,
      double maxScale, double threshold) {
    if (appPlayerSetScale == null) return;
    if (minScale < 1.0) minScale = 1.0;
    if (maxScale < 1.0) maxScale = 1.0;
    appPlayerSetScale(
        playerId, minScale, maxScale, minFocal, maxFocal, direction, threshold);
  }

  void scaleCenter(int direction, int minFocal, int maxFocal, double minScale,
      double maxScale, double threshold, double x, double y) {
    if (appPlayerSetScale == null) return;
    if (minScale < 1.0) minScale = 1.0;
    if (maxScale < 1.0) maxScale = 1.0;
    appPlayerSetScaleCenter(playerId, minScale, maxScale, minFocal, maxFocal,
        direction, threshold, x, y);
  }

  void setChannelKey(int channel, int key) {
    appPlayerSetChannel(playerId, channel, key);
  }

  late StreamSubscription _subscription;

  T? userData;

  AppPlayerController({this.changeCallback, this.userData}) {
    // _subscription = _eventStream.listen(progressListener);
    appPlayerSetScale = playerLib
        .lookup<
            NativeFunction<
                Void Function(Int64, Double, Double, Uint8, Uint8, Int8,
                    Double)>>("app_player_set_scale")
        .asFunction();
    appPlayerSetScaleCenter = playerLib
        .lookup<
            NativeFunction<
                Void Function(Int64, Double, Double, Uint8, Uint8, Int8, Double,
                    Double, Double)>>("app_player_set_scale_center")
        .asFunction();

    appPlayerSetChannel = playerLib
        .lookup<NativeFunction<Void Function(Int64, Int32, Int32)>>(
            "app_player_set_channel")
        .asFunction();
    AppDart().addListener(progressListener);
  }

  CreatedCallback<T?>? createdCallback;
  StateChangeCallback<T>? changeCallback;
  List<ProgressChangeCallback<T>> progressCallbacks = [];
  List<FocalChangeCallback<T?>> focalCallbacks = [];

  bool isCreated = false;
  int textureId = 0;
  int playerId = 0;
  late VideoSourceType sourceType;
  VoiceStatus _voiceStatus = VoiceStatus.STOP;

  VoiceStatus get voiceStatus => _voiceStatus;

  set voiceStatus(VoiceStatus value) {
    if (value != _voiceStatus) {
      _voiceStatus = value;
      if (changeCallback != null)
        changeCallback!(userData, _videoStatus, _voiceStatus, _recordStatus,
            _soundTouchType);
    }
  }

  VideoStatus _videoStatus = VideoStatus.STOP;

  VideoStatus get videoStatus => _videoStatus;

  set videoStatus(VideoStatus value) {
    if (value != _videoStatus) {
      _videoStatus = value;
      if (changeCallback != null)
        changeCallback!(userData, _videoStatus, _voiceStatus, _recordStatus,
            _soundTouchType);
    }
  }

  RecordStatus _recordStatus = RecordStatus.STOP;

  RecordStatus get recordStatus => _recordStatus;

  set recordStatus(RecordStatus value) {
    if (value != _recordStatus) {
      _recordStatus = value;
      if (changeCallback != null)
        changeCallback!(userData, _videoStatus, _voiceStatus, _recordStatus,
            _soundTouchType);
    }
  }

  SoundTouchType _soundTouchType = SoundTouchType.TOUCH_0;

  SoundTouchType get soundTouchType => _soundTouchType;

  set soundTouchType(SoundTouchType value) {
    if (value != _soundTouchType) {
      _soundTouchType = value;
      if (changeCallback != null)
        changeCallback!(userData, _videoStatus, _voiceStatus, _recordStatus,
            _soundTouchType);
    }
  }

  void setCreatedCallback(CreatedCallback<T> callback) {
    this.createdCallback = callback;
  }

  void setStateChangeCallback(StateChangeCallback<T> callback) {
    this.changeCallback = callback;
  }

  void addProgressChangeCallback(ProgressChangeCallback<T> callback) {
    this.progressCallbacks.add(callback);
  }

  void removeProgressChangeCallback(ProgressChangeCallback<T> callback) {
    this.progressCallbacks.remove(callback);
  }

  void clearProgressChangeCallback() {
    this.progressCallbacks.clear();
  }

  void addFocalChangeCallback(FocalChangeCallback<T?> callback) {
    this.focalCallbacks.add(callback);
  }

  void removeFocalChangeCallback(FocalChangeCallback<T> callback) {
    this.focalCallbacks.remove(callback);
  }

  void clearFocalChangeCallback() {
    this.focalCallbacks.clear();
  }

  dynamic source;

  int totalSec = 0,
      playSec = 0,
      progress = 0,
      velocity = 0,
      loadState = 0,
      focal = 0,
      version = 0;

  bool changedProgress = false;

  void progressListener(dynamic args) {
    if (args is List) {
      if (args[0] == textureId) {
        totalSec = args[1];
        playSec = args[2];
        progress = args[3];
        loadState = args[4];
        velocity = args[5];
        version = args[7];
        if (videoStatus == VideoStatus.STARTING) {
          videoStatus = VideoStatus.PLAY;
        }
        print(
            "progressListener: totalSec:$totalSec  playSec:$playSec progress:$progress loadState:$loadState velocity:$velocity version:$version videoStatus:$videoStatus");
        if (args[6] != focal) {
          if (focalCallbacks.isNotEmpty) {
            for (var item in focalCallbacks) {
              item(userData, args[6]);
            }
          }
        }
        focal = args[6];
        if (progressCallbacks.isNotEmpty && changedProgress == false) {
          for (var item in progressCallbacks) {
            item(userData, args[1], args[2], args[3], args[4], args[5]);
          }
        }
      }
    }
  }

  AppPlayerController? sub_controller;
  AppPlayerController? sub2_controller;

  ///创建对象
  Future<bool> create() async {
    print("start isCreated${isCreated}");
    if (isCreated == true) {
      print("isCreated:$isCreated end");
      return true;
    }
    var result =
        await app_player_channel.invokeMapMethod("app_player_create", [0, 0]);
    print("create result:$result ");
    if (result == null || result["result"] == false) {
      print("result:$result error");
      return false;
    }
    textureId = result["textureId"];
    if (result.containsKey("playerId"))
      playerId = result["playerId"];
    else
      playerId = 0;
    isCreated = true;
    if (createdCallback != null) {
      createdCallback!(userData);
    }
    print("textureId:$textureId end");
    return true;
  }

  ///
  /// 设置视频源
  ///
  /// [sourceType] 视频源类型
  /// [source] 视频源
  /// 如果[sourceType]为[VideoSourceType.VIDEO_FILE_SOURCE]
  /// source应该为文件路径
  ///
  /// 如果[sourceType]为[VideoSourceType.VIDEO_LIVE_SOURCE]
  /// source应该为设备指针
  ///
  /// 如果[sourceType]为[VideoSourceType.VIDEO_CARD_SOURCE]
  /// source应该为设备指针
  ///
  /// 如果[sourceType]为[VideoSourceType.VIDEO_NETWORK_SOURCE]
  /// source应该为下载地址
  Future<bool> setVideoSource(VideoSource source) async {
    if (isCreated == false) return false;
    print("textureId:$textureId source:$source start");

    if (source is FileVideoSource) {
      if (source.filePath == null ||
          File(source.filePath).existsSync() == false) {
        print("textureId:$textureId error");
        return false;
      }
    }
    if (source is NetworkVideoSource) {
      if (source.urls == null || source.urls.isEmpty) {
        print("textureId:$textureId error");
        return false;
      }
    }
    if (source is LiveVideoSource) {
      if (source.clientPtr == null || source.clientPtr == 0) {
        print("textureId:$textureId error");
        return false;
      }
    }
    if (source is CardVideoSource) {
      if (source.clientPtr == null || source.clientPtr == 0) {
        print("textureId:$textureId error");
        return false;
      }
      if (source.size == null || source.size < 0) {
        print("textureId:$textureId error");
        return false;
      }
    }

    if (source is TimeLineSource) {
      if (source.clientPtr == null || source.clientPtr == 0) {
        print("textureId:$textureId error");
        return false;
      }
    }
    print("textureId:$textureId source:$source start2222");
    var result = await app_player_channel.invokeMethod("app_player_source",
        [this.textureId, source.sourceType.index, source.getSource()]);
    print("textureId:$textureId source:$source start3333");
    if (result == true) {
      this.sourceType = source.sourceType;
      this.source = source;
    }
    print("textureId:$textureId result:$result end");
    return result;
  }

  Future<bool> enableSubPlayer(AppPlayerController controller) async {
    if (sub_controller != null) return true;
    var result = await app_player_channel.invokeMethod(
        "app_player_enable_sub_player", [this.textureId, controller.textureId]);
    sub_controller = controller;
    print(
        "textureId:$textureId subTextureId:${controller.textureId} result:$result end");
    return result;
  }

  Future<bool> enableSub2Player(AppPlayerController controller) async {
    if (sub2_controller != null) return true;
    var result = await app_player_channel.invokeMethod(
        "app_player_enable_sub2_player",
        [this.textureId, controller.textureId]);
    sub2_controller = controller;
    print(
        "textureId:$textureId sub2TextureId:${controller.textureId} result:$result end");
    return result;
  }

  Future<bool> disableSubPlayer() async {
    if (sub_controller == null) return true;
    var result = await app_player_channel.invokeMethod(
        "app_player_disable_sub_player", this.textureId);

    print(
        "textureId:$textureId subTextureId:${sub_controller!.textureId} result:$result end");
    sub_controller = null;
    if (sub2_controller != null) {
      sub2_controller = null;
    }
    return result;
  }

  Future<bool> start() async {
    print("textureId:$textureId videoStatus:$videoStatus source:$source start");
    if (source == null) return false;
    var result = await app_player_channel.invokeMethod(
        "app_player_start", this.textureId);
    if (result == true) {
      if (videoStatus == VideoStatus.STOP)
        this.videoStatus = VideoStatus.STARTING;
    }
    print("textureId:$textureId result:$result end");
    return result;
  }

  Future<bool> startVoice() async {
    if (source == null) return false;
    print("textureId:$textureId start");
    var result = await app_player_channel.invokeMethod(
        "app_player_start_voice", this.textureId);
    if (result == true) {
      this.voiceStatus = VoiceStatus.PLAY;
    }
    print("textureId:$textureId result:$result end");
    return result;
  }

  ///开始录像
  Future<bool> startRecord(
      {RecordEncoderType encoderType = RecordEncoderType.G711}) async {
    if (source == null) return false;
    var result = await app_player_channel.invokeMethod(
        "app_player_start_record", [this.textureId, encoderType.index]);
    if (result == true) {
      this.recordStatus = RecordStatus.PLAY;
    }
    return result;
  }

  Future<bool> stop() async {
    if (videoStatus == VideoStatus.STOP) return true;
    print("textureId:$textureId start");
    var result = await app_player_channel.invokeMethod(
        "app_player_stop", this.textureId);
    if (result == true) {
      this.videoStatus = VideoStatus.STOP;
    }
    print("textureId:$textureId result:$result end");
    return result;
  }

  Future<bool> stopVoice() async {
    if (source == null) return false;
    print("textureId:$textureId start");
    var result = await app_player_channel.invokeMethod(
        "app_player_stop_voice", this.textureId);
    if (result == true) {
      this.voiceStatus = VoiceStatus.STOP;
    }
    print("textureId:$textureId result:$result end");
    return result;
  }

  ///暂停录像
  Future<bool> stopRecord() async {
    if (source == null) return false;
    print("textureId:$textureId start");
    var result = await app_player_channel.invokeMethod(
        "app_player_stop_record", this.textureId);
    if (result == true) {
      this.recordStatus = RecordStatus.STOP;
    }
    print("textureId:$textureId result:$result end");
    return result;
  }

  Future<bool> pause() async {
    if (videoStatus == VideoStatus.PAUSE) return true;
    if (videoStatus != VideoStatus.PLAY) return false;
    var result = await app_player_channel.invokeMethod(
        "app_player_pause", this.textureId);
    if (result == true) {
      this.videoStatus = VideoStatus.PAUSE;
    }
    return result;
  }

  Future<bool> resume() async {
    if (videoStatus == VideoStatus.PLAY) return true;
    if (videoStatus != VideoStatus.PAUSE) return false;
    var result = await app_player_channel.invokeMethod(
        "app_player_resume", this.textureId);
    if (result == true) {
      this.videoStatus = VideoStatus.PLAY;
    }
    return result;
  }

  ///进度回调
  Future<bool> setProgress(int duration,
      {bool timeLine = false, int channel = 2, int key = 0}) async {
    if (isCreated == false) return false;
    if (source == null) return false;
    if (videoStatus == VideoStatus.STOP) return false;
    if (duration >= totalSec && timeLine == false) return false;
    if (duration == playSec) return true;
    changedProgress = true;
    var result = await app_player_channel.invokeMethod(
        "app_player_progress", [this.textureId, duration, channel, key]);
    changedProgress = false;
    if (result == true) {
      playSec = duration;
    }
    return result;
  }

  ///截图
  Future<bool> screenshot(String filePath, {String imageSize = "0"}) async {
    if (isCreated == false) return false;
    if (source == null) return false;
    return await app_player_channel.invokeMethod(
        "app_player_screenshot", [this.textureId, filePath, imageSize]);
  }

  Future<bool> setSoundTouch(SoundTouchType touchType) async {
    if (isCreated == false) return false;
    if (source == null) return false;
    var result = await app_player_channel.invokeMethod(
        "app_player_soundTouch", [this.textureId, touchType.index]);
    if (result == true) {
      this.soundTouchType = touchType;
    }
    return result;
  }

  double playSpeed = 0.0;

  ///设置播放速率
  Future<bool> setSpeed(double speed) async {
    if (isCreated == false) return false;
    if (source == null) return false;
    if (source is LiveVideoSource) {
      return false;
    }
    if (speed != 1.0) await stopVoice();
    var result = await app_player_channel
        .invokeMethod("app_player_speed", [this.textureId, speed]);
    if (result == true) {
      this.playSpeed = speed;
    }
    return result;
  }

  Future<int> save(String filePath,
      {int start = 0, int end = 0xFFFFFFFF}) async {
    if (isCreated == false) return -1;
    if (source == null) return -1;
    return await app_player_channel.invokeMethod(
        "app_player_save", [this.textureId, filePath, start, end]);
  }

  Future<bool> startDown(String filePath) async {
    if (isCreated == false) return false;
    if (source == null) return false;
    return await app_player_channel
        .invokeMethod("app_player_start_down", [this.textureId, filePath]);
  }

  Future<bool> stopDown() async {
    if (isCreated == false) return false;
    if (source == null) return false;
    return await app_player_channel
        .invokeMethod("app_player_stop_down", [this.textureId]);
  }

  ///录像保存
  static Future<bool> saveMP4(String srcPath, String destPath,
      {int enableSub = 0, int destWidth = 0, int destHeight = 0}) async {
    if (Platform.isAndroid) {
      destWidth = 0;
      destHeight = 0;
    }
    return await app_player_channel.invokeMethod("app_player_save_mp4",
        [srcPath, destPath, enableSub, destWidth, destHeight]);
  }

  static Future<bool> saveWAVE(String srcPath, String destPath,
      {int channel = 1, int fmt = 16, int rate = 8000}) async {
    return await app_player_channel.invokeMethod(
        "app_player_save_wave", [srcPath, destPath, channel, fmt, rate]);
  }

  void dispose() async {
    if (isCreated == false) return;
    isCreated = false;
    progressCallbacks.clear();
    focalCallbacks.clear();
    // if (_subscription != null) _subscription.cancel();
    AppDart().rmvListener(progressListener);
    await app_player_channel.invokeMethod("app_player_stop", this.textureId);
    await app_player_channel.invokeMethod("app_player_destroy", this.textureId);
  }
}

class AppPlayerView extends StatelessWidget {
  const AppPlayerView({super.key, required this.controller});

  final AppPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      double width = constraints.constrainWidth();
      double height = constraints.constrainHeight();
      width = width * window.devicePixelRatio;
      height = height * window.devicePixelRatio;
      if (controller.isCreated == false) {
        return FutureBuilder(
          builder: (context, asyncSnapshot) {
            if (asyncSnapshot.connectionState == ConnectionState.done) {
              if (asyncSnapshot.data == true) {
                return Container(
                  color: Colors.black,
                  child: Texture(textureId: controller.textureId),
                );
              }
            }
            return Container();
          },
          future: controller.create(),
        );
      }
      // controller.changeSize(width, height);
      return Container(
        color: Colors.black,
        child: Texture(textureId: controller.textureId),
      );
    });
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != AppPlayerView) {
      return false;
    }
    if (other is AppPlayerView) {
      return controller == other.controller;
    }
    return false;
  }

  @override
  int get hashCode => hashValues(this, controller);
}
