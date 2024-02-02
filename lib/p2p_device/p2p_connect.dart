import 'dart:async';

import '../app_p2p_api.dart';
import 'p2p_device.dart';

typedef void P2PConnectStateChanged(
    P2PBasisDevice sender, ClientConnectState state);

/// P2P连接功能
mixin P2PConnect on P2PBasisDevice {
  /// 连接状态
  ClientConnectState _p2pConnectState = ClientConnectState.CONNECT_STATUS_MAX;

  ClientConnectState get p2pConnectState => _p2pConnectState;

  set p2pConnectState(ClientConnectState value) {
    if (value != _p2pConnectState) {
      _p2pConnectState = value;
      notifyListeners<P2PConnectStateChanged>((P2PConnectStateChanged func) {
        func(this, _p2pConnectState);
      });
    }
  }

  /// 连接状态回调
  /// 但读取数据失败时,触发回调[ClientConnectState.CONNECT_STATUS_DISCONNECT]
  void _onConnectListener(ClientConnectState state) async {
    p2pConnectState = state;
    if (state == ClientConnectState.CONNECT_STATUS_DISCONNECT) {
      int clientPtr = await getClientPtr();
      await AppP2PApi().clientDisconnect(clientPtr);
      if (_disconnectCompleter != null) {
        _disconnectCompleter!.complete(true);
        _disconnectCompleter = null;
      }
    }
  }

  Completer<bool>? _connectCompleter;

  /// 等待设备连接中断
  Future<bool> _waitConnected() async {
    if (_connectCompleter != null) {
      bool bl = await _connectCompleter!.future
          .timeout(Duration(seconds: 10), onTimeout: () => false);
      _connectCompleter = null;
      return bl;
    }
    return false;
  }

  int _connectByTimeTimeout(int clientPtr) {
    return -3;
  }

  Future<int> connectByTime(
      {required int clientPtr,
      required bool lanScan,
      required int reConnectCount,
      required int connectType}) async {
    String serverParam = await getServiceParam();
    int time = await AppP2PApi()
        .clientCheckTimeout(clientPtr, lanScan, serverParam,
            connectType: connectType)
        .timeout(Duration(seconds: 15),
            onTimeout: () => _connectByTimeTimeout(clientPtr));

    return time;
  }

  ClientConnectState _beginConnectTimeout(int clientPtr) {
    return ClientConnectState.CONNECT_STATUS_CONNECT_TIMEOUT;
  }

  Future<ClientConnectState> _beginConnect(int clientPtr, String serverParam,
      bool lanScan, int reConnectCount, int connectType) async {
    _connectCompleter = Completer();
    p2pConnectState = ClientConnectState.CONNECT_STATUS_CONNECTING;
    _isDisconnect = false;
    ClientConnectState state = ClientConnectState.CONNECT_STATUS_DISCONNECT;
    do {
      state = await AppP2PApi()
          .clientConnect(clientPtr, lanScan, serverParam,
              connectType: connectType)
          .onError((error, stackTrace) =>
              ClientConnectState.CONNECT_STATUS_DISCONNECT)
          .timeout(Duration(seconds: 20),
              onTimeout: () => _beginConnectTimeout(clientPtr));
      reConnectCount -= 1;
    } while (state == ClientConnectState.CONNECT_STATUS_CONNECT_TIMEOUT &&
        reConnectCount > 0 &&
        !_isDisconnect);
    if (_isDisconnect) {
      state = ClientConnectState.CONNECT_STATUS_DISCONNECT;
    }
    if (_connectCompleter!.isCompleted == false)
      _connectCompleter!.complete(true);
    return state;
  }

  /// 进行连接
  /// @param [lanScan] 是否进行局域网搜索
  /// @param [recount] 重连次数
  ///
  /// @return true 调用成功
  ///         false 调用失败
  Future<ClientConnectState> p2pConnect(
      {bool lanScan = true,
      int reConnectCount = 2,
      required int connectType}) async {
    if (p2pConnectState == ClientConnectState.CONNECT_STATUS_CONNECTING) {
      return p2pConnectState;
    }

    p2pConnectState = ClientConnectState.CONNECT_STATUS_CONNECTING;

    int clientPtr = await getClientPtr();

    if (clientPtr == null || clientPtr == 0) {
      p2pConnectState = ClientConnectState.CONNECT_STATUS_INVALID_CLIENT;

      return p2pConnectState;
    }

    String serverParam = await getServiceParam();
    if (serverParam == null) {
      p2pConnectState = ClientConnectState.CONNECT_STATUS_INVALID_CLIENT;

      return p2pConnectState;
    }

    ClientConnectState state = await _beginConnect(
        clientPtr, serverParam, lanScan, reConnectCount, connectType);

    if (state == ClientConnectState.CONNECT_STATUS_ONLINE) {
      _disconnectCompleter = Completer();
      AppP2PApi().setConnectListener(clientPtr, _onConnectListener);
    } else {}

    p2pConnectState = state;

    return p2pConnectState;
  }

  bool _isDisconnect = false;

  Completer<bool>? _disconnectCompleter;

  /// 等待连接断开
  /// 如果设备已经连接处于ONLINE 状态,需要等待设备回调DISCONNECT
  /// 才能确定设备已经完全断开了
  Future<bool> _waitDisconnected() async {
    if (_disconnectCompleter != null) {
      bool bl = await _disconnectCompleter!.future
          .timeout(Duration(seconds: 10), onTimeout: () async {
        return false;
      });
      _disconnectCompleter = null;
      return bl;
    }
    return true;
  }

  /// 断开连接
  /// 如果设备正处于连接状态,需要等待设备退出连接后再调用
  /// `bool ret = await AppP2PApi().clientDisconnect(clientPtr);`
  /// 调用`clientDisconnect`如果返回true,则说明设备曾经连接成功,
  /// 需要等待设备回调disconnect才能确保设备已经完全断开连接
  /// 需要调用`await _waitDisconnected()`来确认设备已经完全断开
  ///
  /// @return true 连接已断开
  ///         false 断开失败
  ///
  Future<bool> disconnect() async {
    int clientPtr = await getClientPtr();
    AppP2PApi().clientConnectBreak(clientPtr);

    bool ret = await _waitConnected();

    ret = await AppP2PApi().clientDisconnect(clientPtr);
    if (ret) {
      ret = await _waitDisconnected();
      AppP2PApi().removeConnectListener(clientPtr);
    }

    return ret;
  }
}
