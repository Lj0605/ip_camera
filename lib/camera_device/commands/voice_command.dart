import 'camera_command.dart';

mixin VoiceCommand on CameraCommand {
  Future<bool> _startSoundCgi(bool bSupportg711a, {int count = 0}) async {
    bool ret = false;
    if (bSupportg711a) {
      ret = await writeCgi("audiostream.cgi?streamid=7&");
    } else {
      ret = await writeCgi("audiostream.cgi?streamid=1&adpcm_ver=1&");
    }
    if (ret == true) {
      waitCommandResult((cmd, data) {
        return cmd == 24625;
      }, 3)
          .then((value) {
        if (!value.isSuccess && count < 3) {
          _startSoundCgi(bSupportg711a, count: count + 1);
        }
      });
      return ret;
    }
    return ret;
  }

  Future<bool> _stopSoundCgi({int count = 0}) async {
    bool ret = await writeCgi("audiostream.cgi?streamid=16&");
    if (ret == true) {
      waitCommandResult((cmd, data) {
        return cmd == 24625;
      }, 3)
          .then((value) {
        if (!value.isSuccess && count < 3) {
          _stopSoundCgi(count: count + 1);
        }
      });
      return ret;
    }
    return ret;
  }

  bool supportG711() {
    return statusResult!.support_audio_g711a != null &&
        statusResult!.support_audio_g711a != "0";
  }

  bool supportbothWay() {
    return statusResult!.EchoCancellationVer != null &&
        statusResult!.EchoCancellationVer != "0";
  }

  Future<bool> startSoundStream() async {
    return await _startSoundCgi(supportG711());
  }

  Future<bool> stopSoundStream() async {
    return await _stopSoundCgi();
  }

  @override
  Future<void> deviceDestroy() async {
    super.deviceDestroy();
  }
}
