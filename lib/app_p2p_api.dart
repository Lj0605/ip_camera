import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'dart:async';

enum ClientConnectState {
  CONNECT_STATUS_INVALID_CLIENT,
  /* client is no create*/
  CONNECT_STATUS_CONNECTING,
  /* connecting */
  CONNECT_STATUS_INITIALING,
  /* initialing */
  CONNECT_STATUS_ONLINE,
  /* on line */
  CONNECT_STATUS_CONNECT_FAILED,
  /* connect failed */
  CONNECT_STATUS_DISCONNECT,
  /*connect is off*/
  CONNECT_STATUS_INVALID_ID,
  /* invalid id */
  CONNECT_STATUS_OFFLINE,
  /* off line */
  CONNECT_STATUS_CONNECT_TIMEOUT,
  /* connect timeout */
  CONNECT_STATUS_MAX_SESSION,
  /* connect max session */
  CONNECT_STATUS_MAX
}

enum ClientConnectMode {
  CONNECT_MODE_NONE, //未知模式
  CONNECT_MODE_P2P, //穿透模式
  CONNECT_MODE_RELAY, //转发模式
  CONNECT_MODE_SOCK //转发模式
}

class ClientChannelType {
  //指令通道
  static ClientChannelType P2P_CMD_CHANNEL = ClientChannelType(0);

  //视频通道
  static ClientChannelType P2P_VIDEO_CHANNEL = ClientChannelType(1);

  //语音接收通道
  static ClientChannelType P2P_AUDIO_CHANNEL = ClientChannelType(2);

  //语音发送通道
  static ClientChannelType P2P_TALKCHANNEL = ClientChannelType(3);

  //回放通道
  static ClientChannelType P2P_PLAYBACK = ClientChannelType(4);

  //报警通道
  static ClientChannelType P2P_SENSORALARM = ClientChannelType(5);

  //Socket 指令通道
  static ClientChannelType SOCK_CMD_CHANNEL = ClientChannelType(0);

  // Socket 媒体通道
  static ClientChannelType SOCK_MEDIA_CHANNEL = ClientChannelType(1);

  // Socket 数据通道
  static ClientChannelType SOCK_DATA_CHANNEL = ClientChannelType(2);

  ClientChannelType(this.index);

  final int index;
}

class ClientCheckBufferResult {
  ClientCheckBufferResult(this.result, this.writeLen, this.readLen);

  ///0      * – P2P_SUCCESSFUL
  ///-5     * - P2P_INVALID_PARAMETER
  ///-1     * – P2P_NOT_INITIALIZED
  ///-11    * – P2P_INVALIED_SESSION_HANDLE
  ///-12    * – P2P_SESSION_CLOSED_REMOTE
  ///-13    * – P2P_SESSION_CLOSED_TIMEOUT
  int result;
  int writeLen;
  int readLen;
}

class ClientCheckModeResult {
  ClientCheckModeResult(this.result, this.mode);

  bool result;
  ClientConnectMode mode;
}

class ClientReadResult {
  ClientReadResult(this.result, this.buffer);

  /// > 0 读取成功,返回值为读取长度
  /// -1 客户端未连接
  /// -3 接收超时
  /// -5 无效参数
  /// -11 连接已失效
  /// -12 远程关闭连接
  /// -13 连接超时关闭
  int result;

  Uint8List buffer;
}

class ClientCommandResult {
  late int cmd;
  late Uint8List data;
}

typedef void ConnectListener(ClientConnectState state);
typedef void CommandListener(int cmd, Uint8List data);

class AppP2PApi {
  /// 单例
  static AppP2PApi? _instance;

  /// 将构造函数指向单例
  factory AppP2PApi() => getInstance();

  ///获取单例
  static AppP2PApi getInstance() {
    //如果单例为空则创建单例
    if (_instance == null) {
      _instance = new AppP2PApi._internal();
    }
    return _instance!;
  }

  bool _isNullOrZero(int value) {
    return value == null || value == 0;
  }

  late MethodChannel _channel;
  late EventChannel _connectChannel;
  late EventChannel _commandChannel;
  late Stream _connectStream;
  late Stream _commandStream;
  HashMap<int, ConnectListener> _connectListeners = HashMap();
  HashMap<int, CommandListener> _commandListeners = HashMap();

  AppP2PApi._internal() {
    _channel = MethodChannel("app_p2p_api_channel");
    _connectChannel = EventChannel("app_p2p_api_event_channel/connect");
    _commandChannel = EventChannel("app_p2p_api_event_channel/command");
    _connectStream = _connectChannel.receiveBroadcastStream("connect");
    _commandStream = _commandChannel.receiveBroadcastStream("command");
    _connectStream.listen(_onConnectListener);
    _commandStream.listen(_onCommandListener);
  }

  void _onConnectListener(dynamic data) {
    int clientPtr = data[0];
    int state = data[1];
    var listener = _connectListeners[clientPtr];
    if (listener != null) {
      listener(ClientConnectState.values[state]);
    }
  }

  void _onCommandListener(dynamic data) {
    int clientPtr = data[0];
    int cmd = data[1];
    Uint8List buffer = data[2];
    var list = Uint8List.fromList(buffer.toList());
    var listener = _commandListeners[clientPtr];
    if (listener != null) {
      listener(cmd, list);
    }
  }

  ///添加连接状态监听
  void setConnectListener(int clientPtr, ConnectListener listener) {
    if (_isNullOrZero(clientPtr)) return;
    _connectListeners[clientPtr] = listener;
  }

  ///添加设备指令监听
  void setCommandListener(int clientPtr, CommandListener listener) {
    if (_isNullOrZero(clientPtr)) return;
    _commandListeners[clientPtr] = listener;
  }

  ///移除连接状态监听
  void removeConnectListener(int clientPtr) {
    if (_isNullOrZero(clientPtr)) return;
    _connectListeners.remove(clientPtr);
  }

  ///移除设备指令监听
  void removeCommandListener(int clientPtr) {
    if (_isNullOrZero(clientPtr)) return;
    _commandListeners.remove(clientPtr);
  }

  ///创建P2P客户端
  ///@param [did] 设备ID
  ///@return 客户端指针
  Future<int?> clientCreate(String did) async {
    if (did == null) return 0;
    var result = await _channel.invokeMethod<int>("client_create", [did]);
    return result;
  }

  ///修改P2P客户端ID
  ///@param [did] 设备ID
  ///@return 客户端指针
  Future<bool> clientChangeId(int clientPtr, String did) async {
    if (did == null || _isNullOrZero(clientPtr)) return false;
    var result =
        await _channel.invokeMethod<bool>("client_change_id", [clientPtr, did]);
    return result ?? false;
  }

  ///客户端连接
  ///@param [clientPtr] 客户端指针
  ///@param [lanScan] 是否进行局域网搜索
  ///@param [serverParam] 服务器连接参数
  ///@return 连接状态 @see [ClientConnectState]
  Future<ClientConnectState> clientConnect(
      int clientPtr, bool lanScan, String serverParam,
      {required int connectType}) async {
    if (_isNullOrZero(clientPtr))
      return ClientConnectState.CONNECT_STATUS_INVALID_CLIENT;
    int? result = await _channel.invokeMethod<int>(
        "client_connect", [clientPtr, lanScan, serverParam, connectType]);
    return ClientConnectState.values[result ?? 0];
  }

  ///检测客户端超时时间
  ///@param [clientPtr] 客户端指针
  ///@param [lanScan] 是否进行局域网搜索
  ///@param [serverParam] 服务器连接参数
  ///@return 超时时间
  Future<int> clientCheckTimeout(
      int clientPtr, bool lanScan, String serverParam,
      {required int connectType}) async {
    if (_isNullOrZero(clientPtr)) return 0;
    int? result = await _channel.invokeMethod<int>(
        "client_connect", [clientPtr, lanScan, serverParam, connectType]);
    return result ?? 0;
  }

  ///查看客户端连接模式
  ///@param [clientPtr] 客户端指针
  ///@return [ClientCheckModeResult]
  Future<ClientCheckModeResult> clientCheckMode(int clientPtr) async {
    if (_isNullOrZero(clientPtr))
      return ClientCheckModeResult(false, ClientConnectMode.CONNECT_MODE_NONE);
    List result = await _channel.invokeMethod("client_check_mode", [clientPtr]);
    return ClientCheckModeResult(
        result[0], ClientConnectMode.values[result[1]]);
  }

  ///检查客户端buffer
  ///@param [clientPtr] 客户端指针
  ///@param [channelType] 要检查的通道ID @see [ClientChannelType]
  ///@return [ClientCheckBufferResult]
  Future<ClientCheckBufferResult> clientCheckBuffer(
      int clientPtr, ClientChannelType channelType) async {
    if (_isNullOrZero(clientPtr) || channelType == null)
      return ClientCheckBufferResult(-5, 0, 0);
    List result = await _channel
        .invokeMethod("client_check_buffer", [clientPtr, channelType.index]);

    return ClientCheckBufferResult(result[0], result[1], result[2]);
  }

  ///用户登录
  ///@param [clientPtr] 客户端指针
  ///@param [username] 用户名
  ///@param [password] 用户密码
  ///@return true 发送成功,false 发送失败
  Future<bool> clientLogin(
      int clientPtr, String username, String password) async {
    if (_isNullOrZero(clientPtr) ||
        username == null ||
        username.length == 0 ||
        password == null ||
        password.length == 0) {
      return false;
    }
    var result = await _channel
        .invokeMethod("client_login", [clientPtr, username, password]);
    return result;
  }

  ///发送CGI指令
  ///@param [clientPtr] 客户端指针
  ///@param [username] 用户名
  ///@param [password] 用户密码
  ///@return true 发送成功,false 发送失败
  Future<bool> clientWriteCgi(int clientPtr, String cgi,
      {int timeout = 5}) async {
    if (_isNullOrZero(clientPtr) || cgi == null || cgi.length == 0)
      return false;
    var result = await _channel
        .invokeMethod("client_write_cig", [clientPtr, cgi, timeout]);
    return result;
  }

  ///发送buffer
  ///@param [clientPtr] 客户端指针
  ///@param [channelType] 要读取的通道ID @see [ClientChannelType]
  ///@param [buffer] 发送buffer
  ///@param [timeout] 超时时间 秒为单位
  ///@return
  /// > 0 发送成功,返回值为发送长度
  /// -1 客户端未连接
  /// -3 发送超时
  /// -5 无效参数
  /// -11 连接已失效
  /// -12 远程关闭连接
  /// -13 连接超时关闭
  /// -15 远程接收buffer已满
  Future<int> clientWrite(int clientPtr, ClientChannelType channelType,
      Uint8List buffer, int timeout) async {
    if (_isNullOrZero(clientPtr) || channelType == null || buffer == null)
      return -5;
    var result = await _channel.invokeMethod(
        "client_write", [clientPtr, channelType.index, buffer, timeout]);
    return result;
  }

  ///断开P2P客户端连接
  ///@param [clientPtr] 客户端指针
  ///@return 客户端指针
  Future<bool> clientDisconnect(int clientPtr) async {
    if (_isNullOrZero(clientPtr)) return false;
    var result = await _channel.invokeMethod("client_disconnect", [clientPtr]);
    return result;
  }

  ///销毁P2P客户端
  Future<void> clientDestroy(int clientPtr) async {
    if (_isNullOrZero(clientPtr)) return;
    _connectListeners.remove(clientPtr);
    _commandListeners.remove(clientPtr);
    await _channel.invokeMethod("client_destroy", [clientPtr]);
    return;
  }

  ///销毁P2P客户端
  Future<void> clientConnectBreak(int clientPtr) async {
    if (_isNullOrZero(clientPtr)) return;
    await _channel.invokeMethod("client_connect_break", [clientPtr]);
    return;
  }
}
