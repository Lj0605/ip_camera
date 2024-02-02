import 'dart:async';
import 'dart:convert';

import 'package:vsdk/p2p_device/p2p_command.dart';
import 'package:vsdk/p2p_device/p2p_device.dart';

import '../../device_wakeup_server.dart';
import 'camera_command.dart';

typedef WakeupStateChanged = void Function(
    P2PBasisDevice device, DeviceWakeupState? wakeupState);

mixin WakeupCommand on CameraCommand {
  DeviceWakeupState? _wakeupState;

  DeviceWakeupState? get wakeupState => _wakeupState;

  set wakeupState(DeviceWakeupState? value) {
    if (value != _wakeupState) {
      _wakeupState = value;
      notifyListeners<WakeupStateChanged>((WakeupStateChanged func) {
        func(this, _wakeupState);
      });
    }
  }

  void _wakeupListener(String did, DeviceWakeupState state) {
    if (state != _wakeupState) {
      wakeupState = state;
    }
  }

  Timer? keepAliveTimer;

  Future<bool> _keepAliveCgi(int time) async {
    bool ret = await writeCgi(
        "trans_cmd_string.cgi?cmd=2131&command=1&DevActiveTime=$time&",
        timeout: (time / 2).floor());
    if (ret == true) {
      CommandResult result = await waitCommandResult((cmd, data) {
        return cmd == 24785 && utf8.decode(data).contains("cmd=2131;");
      }, (time / 2).floor());
      Map map = result.getMap();
      if (map != null && map.containsKey("DevActiveTime")) {
        return true;
      } else {
        return false;
      }
    }
    return ret;
  }

  void keepAlive({int time = 10}) async {
    keepAliveTimer?.cancel();
    keepAliveTimer =
        Timer.periodic(Duration(seconds: (time / 2).floor()), (timer) {
      _keepAliveCgi(time);
    });
  }

  void cancelKeepAlive() {
    keepAliveTimer?.cancel();
  }

  void addListener<T>(T listener) async {
    if (listener != null &&
        listener is WakeupStateChanged &&
        _addListener == false) {
      DeviceWakeUpServer().removeListener(id, _wakeupListener);
      DeviceWakeUpServer().addListener(id, _wakeupListener);
    }
    super.addListener(listener);
  }

  bool _addListener = false;

  void requestWakeup() {
    DeviceWakeUpServer().wakeup(id);
    Timer(Duration(seconds: 3), () {
      DeviceWakeUpServer().wakeup(id);
    });
  }

  void requestWakeupOnce() {
    DeviceWakeUpServer().wakeup(id);
  }

  void requestWakeupStatus() {
    var bl = DeviceWakeUpServer().checkNotNode(id);
    if (bl) return;
    DeviceWakeUpServer().getStatus(id);
  }

  @override
  Future<void> deviceDestroy() async {
    cancelKeepAlive();
    DeviceWakeUpServer().removeListener(id, _wakeupListener);
    DeviceWakeUpServer().removeAutoWakeup(id);
    super.deviceDestroy();
  }
}
