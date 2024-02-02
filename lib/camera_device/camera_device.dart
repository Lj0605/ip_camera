import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:vsdk/p2p_device/p2p_command.dart';
import 'package:vsdk/p2p_device/p2p_connect.dart';
import 'package:vsdk/p2p_device/p2p_device.dart';

import '../app_p2p_api.dart';
import '../device_wakeup_server.dart';
import 'commands/ai_command.dart';
import 'commands/alarm_command.dart';
import 'commands/camera_command.dart';
import 'commands/card_command.dart';
import 'commands/param_command.dart';
import 'commands/plan_command.dart';
import 'commands/record_command.dart';
import 'commands/status_command.dart';
import 'commands/video_command.dart';
import 'commands/voice_command.dart';
import 'commands/wakeup_command.dart';

enum CameraConnectState {
  connecting, //连接中
  logging, //登录中
  connected, //在线
  timeout, //连接超时
  disconnect, //连接中断
  password, //密码错误
  maxUser, //观看人数过多
  offline, //离线
  illegal, //非法的
  none,
}

typedef CameraConnectChanged = void Function(
    CameraDevice device, CameraConnectState connectState);

typedef CameraVerifyListener = Future<bool> Function(CameraDevice device);

typedef CameraConnectTypeChanged = void Function(
    CameraDevice device, int connectType, String password);

class CameraDevice extends P2PBasisDevice
    with
        P2PConnect,
        P2PCommand,
        StatusCommand,
        CameraCommand,
        ParamsCommand,
        VideoCommand,
        VoiceCommand,
        WakeupCommand,
        AICommand,
        AlarmCommand,
        PlanCommand,
        CardCommand,
        RecordCommand,
        WidgetsBindingObserver {
  CameraDevice(
      String id, String name, String username, String password, String model,
      {String? clientId, this.editPassword = true, this.connectType = 126})
      : super(id, username, password, name, model, clientId: clientId) {
    WidgetsBinding.instance.addObserver(this);
    this.addListener<WakeupStateChanged>(_wakeupStateListener);

    wakeupTimer = Timer.periodic(Duration(seconds: 3), _requestStatusTimer);
  }

  bool editPassword = true;

  int connectType = 126;

  int userid = 0;
  Timer? wakeupTimer;

  ///旧密码（认证失败才会使用）

  CameraConnectState _connectState = CameraConnectState.none;

  CameraConnectState get connectState => _connectState;

  set connectState(CameraConnectState value) {
    if (_connectState == CameraConnectState.maxUser &&
        value == CameraConnectState.disconnect) {
    } else {
      if (value != _connectState) {
        _connectState = value;
        notifyListeners<CameraConnectChanged>((CameraConnectChanged func) {
          func(this, _connectState);
        });
      }
    }
  }

  CameraVerifyListener? verifyListener;

  //
  // @Deprecated('不使用"p2pConnect"进行连接处理,调用函数connect')
  // Future<ClientConnectState> p2pConnect(
  //     {bool lanScan = true, int reConnectCount = 2, required int connectType}) {
  //   print(
  //       "id:$id lanScan:$lanScan reConnectCount:$reConnectCount connectType:$connectType start");
  //   if (_destroyFlag == true) {
  //     print("id:$id isDestroy:$_destroyFlag error");
  //     return Future.value(ClientConnectState.CONNECT_STATUS_DISCONNECT);
  //   }
  //   return super.p2pConnect(
  //       lanScan: lanScan,
  //       reConnectCount: reConnectCount,
  //       connectType: connectType);
  // }

  @override
  Future<bool> writeCgi(String cgi,
      {int timeout = 5, bool needLogin = true}) async {
    if (_destroyFlag == true) {
      return false;
    }
    if (needLogin == true && connectState != CameraConnectState.connected) {
      return false;
    }
    return super.writeCgi(cgi, timeout: timeout);
  }

  AppLifecycleState? _lifecycleState;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    _lifecycleState = state;
    if (state == AppLifecycleState.paused) {
      print("id:$id state:$state");
      isBack = true;
      sirenCommand?.controlSiren(false); //进入后台停止警笛

      disconnect();
    } else if (state == AppLifecycleState.resumed) {
      isBack = false;
      verifyOffline = false;
      if (connectState != CameraConnectState.connected) {
        connect();
      }
    }
  }

  Future<int> _checkConnectType(
      int count, String clientId, int clientPtr) async {
    if (_destroyFlag == true) {
      print("id:$id isDestroy:$_destroyFlag error");
      return Future.value(connectType);
    }

    var cType = connectType;
    if (cType == 63) {
      bool deviceAp = await super.checkDeviceAp(id);
      if (!deviceAp) {
        cType = 126;
        await changeClientId();
      }
    }
    if (isVirtualId == false) {
      cType = 126;
    } else {
      if (clientId.startsWith('VSGG') || clientId.startsWith('VSGM')) {
        cType = 0x7B;
      }
      if (cType != 63) {
        if (clientId == null) {
          cType = 126;
          return cType;
        }
      }
    }
    print("id:$id cType:$cType end");
    return cType;
  }

  Future<bool> _checkOffline(
      bool lanScan, String clientId, int clientPtr) async {
    if (_destroyFlag == true) {
      print("id:$id isDestroy:$_destroyFlag error");
      return Future.value(false);
    }

    int timeout = await super.connectByTime(
        clientPtr: clientPtr,
        lanScan: lanScan,
        reConnectCount: 1,
        connectType: 0x79);

    if (timeout > 300) {
      verifyOffline = true;
      connectState = CameraConnectState.offline;
    }
    print("id:$id timeout:$timeout connectState:$connectState end");
    return timeout > 300;
  }

  Future<int> offlineSeconds() async {
    int clientPtr = await getClientPtr();
    int timeout = await super.connectByTime(
        clientPtr: clientPtr,
        lanScan: true,
        reConnectCount: 1,
        connectType: 0x79);

    return timeout;
  }

  Future<StatusResult?> _login(int count, String pwd) async {
    StatusResult? result;
    int i = 0;
    String admin = 'admin';

    while (i < count && !_connectExitFlag && !_destroyFlag) {
      result = await login(admin, pwd, timeout: 30);
      i += 1;
      if (result == null || result.isSuccess == false)
        continue;
      else
        break;
    }
    return result;
  }

  Future<CameraConnectState> connect(
      {bool lanScan = true, int connectCount = 3}) async {
    if (_destroyFlag == true) {
      print("id:$id isDestroy:$_destroyFlag error");
      return CameraConnectState.disconnect;
    }
    if (isBack || isRemoteClose) {
      print(
          "id:$id CameraConnectState.disconnect error isBack:$isBack isRemoteClose:$isRemoteClose");
      return CameraConnectState.disconnect;
    }

    if (connectState == CameraConnectState.connecting ||
        connectState == CameraConnectState.logging ||
        connectState == CameraConnectState.connected) {
      return connectState;
    }

    connectState = CameraConnectState.connecting;
    _connectExitFlag = false;

    var clientId = await getClientId();
    int clientPtr = await getClientPtr();

    print('id:$id clientId:$clientId clientPtr:$clientPtr');
    if (clientPtr == null || clientPtr == 0) {
      connectState = CameraConnectState.offline;
      return CameraConnectState.offline;
    }
    if (verifyOffline) {
      var offline = await _checkOffline(lanScan, clientId, clientPtr);
      if (offline == true) {
        print("id:$id CameraConnectState.offline end");
        connectState = CameraConnectState.offline;
        return connectState;
      }
    }

    // this.statusResult?.batteryRate = null;
    // this.statusResult?.isCharge = null;
    this.statusResult = this.statusResult;
    late ClientConnectState p2pState;
    this.removeListener<P2PConnectStateChanged>(_connectStateListener);
    var cType = connectType;
    for (int i = 0; i < connectCount && !_connectExitFlag; i++) {
      /// 检测连接类型
      requestWakeup();
      cType = await _checkConnectType(i, clientId, clientPtr);

      p2pState = await super
          .p2pConnect(lanScan: lanScan, reConnectCount: 1, connectType: cType);

      if (p2pState != ClientConnectState.CONNECT_STATUS_ONLINE) {
        if (i == 0 && (cType == 0x7B || cType == 95)) {
          print("id:$id cType:$cType 转发连接失败后,检查设备离线时间");
          var offline = await _checkOffline(lanScan, clientId, clientPtr);
          if (offline == true) {
            print("id:$id CameraConnectState.offline end");
            return CameraConnectState.offline;
          }
        } else if (i == 1 && cType != 63) {
          print("id:$id cType:$cType 转发连接失败后,检查设备离线时间");
          var offline = await _checkOffline(lanScan, clientId, clientPtr);
          if (offline == true) {
            print("id:$id CameraConnectState.offline end");
            return CameraConnectState.offline;
          }
        }
      }

      if (p2pState == ClientConnectState.CONNECT_STATUS_ONLINE) {
        if (connectType == 63 && await super.checkDeviceAp(id)) {
          cType = 63;
        }
        break;
      }
    }

    if (p2pState != ClientConnectState.CONNECT_STATUS_ONLINE) {
      connectState = _getConnectState();
      print("id:$id $connectState end");
      return connectState;
    }

    this.addListener<P2PConnectStateChanged>(_connectStateListener);
    await this.setCommandListener();
    connectState = CameraConnectState.logging;

    StatusResult? result = await _login(connectCount, password);

    if (result == null || result.isSuccess != true) {
      connectState = CameraConnectState.timeout;
      print("id:$id $connectState end");
      return connectState;
    }

    if (result.result == "-4") {
      connectState = CameraConnectState.illegal;
      print("id:$id $connectState end");
      return connectState;
    }

    if (result.result == "-1" ||
        result.result == "-2" ||
        result.result == "-3") {
      connectState = CameraConnectState.password;
      print("id:$id $connectState end");
      return connectState;
    }

    var realDeviceId = result.realdeviceid;

    int currentUsers = int.tryParse(result.current_users ?? "") ?? 0;
    int maxSupportUsers = int.tryParse(result.max_support_users ?? "") ?? 0;
    if (currentUsers > maxSupportUsers) {
      connectState = CameraConnectState.maxUser;
      print(
          "id:$id currentUsers:$currentUsers maxUsers:$maxSupportUsers $connectState end");
      return connectState;
    }

    if (isVirtualId == true && realDeviceId != null && id != realDeviceId) {
      connectState = CameraConnectState.password;
      print("id:$id vuid:$realDeviceId $connectState end");
      return connectState;
    }

    String? dual = result.DualAuthentication;
    if (dual != null && dual != "0" && verifyListener != null) {
      bool verify = await verifyListener!(this);
      if (verify == false) {
        await disconnect();
        connectState = CameraConnectState.disconnect;
        print("id:$id dualVerify:$verify $connectState end");
        return connectState;
      }
    }

    connectState = CameraConnectState.connected;
    print("id:$id $connectState end ");
    keepAlive(time: 10);
    getStatus(cache: true);
    updateDateTime();

    return connectState;
  }

  @override
  Future<bool> disconnect() {
    _connectExitFlag = true;
    if (_destroyFlag == true) return Future.value(true);
    return super.disconnect();
  }

  bool _destroyFlag = false;

  @override
  Future<void> deviceDestroy() async {
    if (_destroyFlag == true) return;
    _destroyFlag = true;
    WidgetsBinding.instance.removeObserver(this);
    await disconnect();
    this.removeListener<P2PConnectStateChanged>(_connectStateListener);
    removeCommandListener();
    super.deviceDestroy();
  }

  bool _connectExitFlag = false;

  ///前后台标签
  bool isBack = false;

  bool isRemoteClose = false;

  bool verifyOffline = false;

  void _connectStateListener(
      P2PBasisDevice sender, ClientConnectState connectState) async {
    this.connectState = _getConnectState();
    if (_lifecycleState == AppLifecycleState.resumed) {
      if (connectState == ClientConnectState.CONNECT_STATUS_DISCONNECT) {
        connect();
      }
    }
  }

  void _requestStatusTimer(timer) {
    requestWakeupStatus();
  }

  void _wakeupStateListener(
      P2PBasisDevice device, DeviceWakeupState? wakeupState) {
    print("id:${device.id} wakeupState:$wakeupState");
    if (wakeupState == null) return;
    if (wakeupState == DeviceWakeupState.online) {
      wakeupTimer?.cancel();
      wakeupTimer = Timer.periodic(Duration(seconds: 45), _requestStatusTimer);
      if (this.connectState != CameraConnectState.connected) {
        connect();
      }
    } else if (wakeupState == DeviceWakeupState.offline) {
      wakeupTimer?.cancel();
      wakeupTimer = Timer.periodic(Duration(seconds: 3), _requestStatusTimer);
    }
    if (this.connectState == CameraConnectState.disconnect ||
        this.connectState == CameraConnectState.offline) {
      if (wakeupState == DeviceWakeupState.online) connect();
    }
  }

  CameraConnectState _getConnectState() {
    switch (p2pConnectState) {
      case ClientConnectState.CONNECT_STATUS_INVALID_ID:
      case ClientConnectState.CONNECT_STATUS_INVALID_CLIENT:
      case ClientConnectState.CONNECT_STATUS_OFFLINE:
      case ClientConnectState.CONNECT_STATUS_MAX:
        return CameraConnectState.offline;
      case ClientConnectState.CONNECT_STATUS_CONNECTING:
      case ClientConnectState.CONNECT_STATUS_INITIALING:
      case ClientConnectState.CONNECT_STATUS_ONLINE:
        return CameraConnectState.connecting;
      case ClientConnectState.CONNECT_STATUS_MAX_SESSION:
        return CameraConnectState.maxUser;
      case ClientConnectState.CONNECT_STATUS_CONNECT_TIMEOUT:
        return CameraConnectState.timeout;
      case ClientConnectState.CONNECT_STATUS_CONNECT_FAILED:
      case ClientConnectState.CONNECT_STATUS_DISCONNECT:
        return CameraConnectState.disconnect;
    }
    return CameraConnectState.none;
  }
}
