import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equatable/equatable.dart';

int _byte4Int(List<int> bytes) {
  int value = 0;
  for (int i = 0; i < 4; i++) {
    value |= (bytes[i] & 0xFF) << (8 * (3 - i));
  }
  return value;
}

List<int> _int4byte(int value) {
  List<int> bytes = [];
  for (int i = 0; i < 4; i++) {
    bytes.add((value >> 8 * (3 - i)) & 0xFF);
  }
  return bytes;
}

Map _encryptionMap(Map data) {
  var secretKey = '9QDU2DZ3gulyXnze';
  data['AccessKey'] = '2LZaRSu4ND5f7wJ5';
  data['timestamp'] =
      (DateTime.now().toUtc().millisecondsSinceEpoch / 1000).floor();
  data['sign'] = Random().nextInt(9999);
  data['signature'] = _encryption(secretKey, data);
  return data;
}

String _encryption(String secretKey, Map data) {
  List<String> headers = [];
  for (String key in data.keys) {
    if (key != 'signature') {
      headers.add(key);
    }
  }
  //字典排序
  headers.sort((a, b) {
    return a.compareTo(b);
  });
  var parameter = "";
  for (var i = 0; i < headers.length; i++) {
    var name = headers[i];
    parameter = '$parameter$name${data[name]}';
  }
  String str = base64Encode(
      Hmac(sha1, utf8.encode(secretKey)).convert(utf8.encode(parameter)).bytes);
  return str;
}

List<int> _socketBuffer(List<int> bytes) {
  List<int> lenBytes = _int4byte(bytes.length);
  List<int> buffer = [];
  buffer.insertAll(0, lenBytes);
  buffer.insertAll(4, bytes);
  return buffer;
}

class SocketData {
  List<int> _bufferPool = [];

  int? _dataLength;

  String? push(List<int> buffer) {
    _bufferPool.addAll(buffer);
    if (_bufferPool.length >= 4 && _dataLength == null) {
      _dataLength = _byte4Int(_bufferPool.sublist(0, 4));
    }
    if (_dataLength != null && _bufferPool.length >= _dataLength! + 4) {
      String? result;
      if (_dataLength! > 0)
        result = utf8.decode(_bufferPool.sublist(4, _dataLength! + 4));
      _bufferPool.removeRange(0, _dataLength! + 4);
      _dataLength = null;
      return result;
    }
    return null;
  }

  void clean() {
    _bufferPool.clear();
  }
}

abstract class SocketEvent extends Equatable {
  final String debugMsg;

  SocketEvent(this.debugMsg);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [];
}

class ConnectEvent extends SocketEvent {
  ConnectEvent({String debugMsg = ""}) : super(debugMsg);

  @override
  List<Object> get props => [super.debugMsg];
}

class SendEvent extends SocketEvent {
  final List<int> data;

  SendEvent(this.data, {String debugMsg = ""}) : super(debugMsg);

  @override
  List<Object> get props => data;
}

class CloseEvent extends SocketEvent {
  CloseEvent({String debugMsg = ""}) : super(debugMsg);

  @override
  List<Object> get props => [debugMsg];
}

class SocketServer {
  late final String ip;
  late final int port;
  final void Function(String data)? dataListener;
  final int keepTime;
  late StreamController<SocketEvent> _controller;
  Socket? _socket;
  late DateTime lastTime;
  SocketData _socketData = SocketData();
  Timer? _timer;

  SocketServer(this.ip, this.port, this.dataListener, {this.keepTime = 5}) {
    lastTime = DateTime.now();
    _controller = StreamController<SocketEvent>();
    _controller.stream
        .asyncMap(_eventListen)
        .listen(_eventDone, onError: _eventError)
        .onError(_eventError);
    lastTime = DateTime.now();
    _timer = Timer.periodic(Duration(seconds: keepTime), (timer) {
      Duration duration = DateTime.now().difference(lastTime);
      if (duration.inSeconds > keepTime) {
        _controller.add(CloseEvent(debugMsg: "close timeout"));
      }
    });
    _controller.add(ConnectEvent(debugMsg: "connect init"));
  }

  void close() {
    _timer?.cancel();
    _controller.close();
    _socket?.close();
  }

  void _eventError(error) {
    _controller.add(CloseEvent(debugMsg: "event Error $error"));
  }

  void _eventDone(SocketEvent event) {
    // VPLog.debug("$ip:$port ${event.runtimeType} end:${event.debugMsg}",
    //     tag: "WAKE");
  }

  Future<SocketEvent> _eventListen(SocketEvent event) async {
    if (event is ConnectEvent) {
      if (_socket == null) {
        _socket = await _connectServer();
        return event;
      }
    } else if (event is SendEvent) {
      if (_socket == null) {
        return event;
      }
      try {
        _socket?.add(event.data);
      } catch (e) {
        _controller.add(CloseEvent(debugMsg: "send Error $e"));
        _controller.add(ConnectEvent(debugMsg: "send Error reConnect"));
        _controller.add(SendEvent(event.data, debugMsg: "send Error reSend"));
      }
    } else if (event is CloseEvent) {
      if (_socket != null) {
        _socket?.close();
        _socket?.destroy();
        _socket = null;
      }
    }
    return event;
  }

  void _dataListen(List<int> buffer) {
    lastTime = DateTime.now();
    String? data = _socketData?.push(buffer);

    while (data != null && data.isNotEmpty) {
      if (dataListener != null) {
        dataListener!(data);
      }
      data = _socketData.push([]);
    }
  }

  void _dataErrorListen(error) async {
    _controller.add(CloseEvent(debugMsg: "readServer Error $error"));
  }

  Future<Socket> _connectServer() async {
    // ignore: close_sinks
    lastTime = DateTime.now();
    Socket socket =
        await Socket.connect(ip, port, timeout: Duration(seconds: 5))
            .catchError((error) {
      _controller.add(CloseEvent(debugMsg: "connectServer Error $error"));
    });
    if (socket == null) {
      return socket;
    }
    socket.done.onError((error, stackTrace) {
      _controller.add(CloseEvent(debugMsg: "connectServer Error $error"));
    });
    lastTime = DateTime.now();
    _socketData.clean();
    var stream = socket.handleError(_dataErrorListen);
    stream
        .listen(_dataListen, onError: _dataErrorListen, cancelOnError: true)
        .onError(_dataErrorListen);
    return socket;
  }

  void send(List<int> data) async {
    if (_socket == null) {
      _controller.add(ConnectEvent(debugMsg: "send connect"));
    }
    _controller.add(SendEvent(data, debugMsg: "send"));
  }
}

enum DeviceWakeupState {
  offline,
  deepSleep,
  sleep,
  online,
  poweroff,
  microPower, //微功耗模式
  lowPowerOff, //低电关机
}

typedef DeviceWakeupStateChanged = void Function(
    String did, DeviceWakeupState state);
typedef WakeupServerStateChanged = void Function(
    String did, String server, DeviceWakeupState state);

class WakeupServer {
  late final String host;
  late final int port;
  late final keepTime;
  late final String shareKey;
  late final WakeupServerStateChanged listener;
  late SocketServer _socketServer;

  WakeupServer(
      this.host, this.port, this.keepTime, this.shareKey, this.listener) {
    _socketServer = SocketServer(this.host, this.port, _dataListen,
        keepTime: this.keepTime);
  }

  HashMap<String, NodeClient> _clientNodes = HashMap();
  HashMap<String, NodeClient> _deviceNodes = HashMap();

  NodeClient _getOrAddNode(String did, String ip, int port) {
    String nodeKey = '$ip:$port';
    NodeClient? nodeClient = _clientNodes[nodeKey];
    if (nodeClient == null) {
      nodeClient = NodeClient(ip, port, _stateListener);
      _clientNodes[nodeKey] = nodeClient;
    }
    if (_deviceNodes[did] == null || _deviceNodes[did]!.ip != ip)
      _deviceNodes[did] = nodeClient;
    if (_autoWakeupMap.containsKey(did)) {
      String dip = _autoWakeupMap[did]["ip"];
      int dport = _autoWakeupMap[did]["port"];
      if (dip != ip || dport != port) {
        saveAutoWakeup(did);
      }
    }
    return nodeClient;
  }

  void _dataListen(String data) {
    if (data != null) {
      Map map = json.decode(data);
      if (map["event"] == "getDeviceInfo" && map["ret"] == 1) {
        String ip = map["node_ip"];
        int port = map["node_port"];
        String did = map["did"];
        DeviceWakeUpServer().addHasNode(did);
        NodeClient nodeClient = _getOrAddNode(did, ip, port);
        if (_wakeupMap.containsKey(did)) {
          nodeClient.wakeUp(did);
          _wakeupMap.remove(did);
        }
        if (_statusMap.containsKey(did)) {
          nodeClient.getStatus(did);
          _statusMap.remove(did);
        }
      } else if (map["event"] == "getDeviceInfo" && map["ret"] == 0) {
        String did = map["did"];
        DeviceWakeUpServer().addNotNode(port, did);
      }
    }
  }

  void _requestNode(String did) {
    String str = json.encode(_encryptionMap({
      "event": "getDeviceInfo",
      'did': did,
    }));
    List<int> bytes = utf8.encode(str);
    var buffer = _socketBuffer(bytes);
    _socketServer.send(buffer);
  }

  Map<String, DeviceWakeupState> _deviceState = Map();

  void _stateListener(String did, DeviceWakeupState state) {
    if (_deviceState[did] != state) {
      _deviceState[did] = state;
      if (listener != null) {
        listener(did, shareKey, state);
      }
    }
  }

  Map _wakeupMap = Map();

  void wakeup(String did) {
    _requestNode(did);
    if (_deviceNodes.containsKey(did)) {
      _deviceNodes[did]!.wakeUp(did);
    }
    _wakeupMap[did] = true;
  }

  Map _statusMap = Map();

  void getStatus(String did) {
    if (DeviceWakeUpServer().hasNotNode(port, did) == true) return;
    _requestNode(did);
    if (_deviceNodes.containsKey(did)) {
      _deviceNodes[did]!.getStatus(did);
    } else {
      _statusMap[did] = true;
    }
  }

  Map<dynamic, dynamic> _autoWakeupMap = Map();

  Future<void> autoWakeup() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    String? str = sp.getString(shareKey);
    if (str != null) {
      _autoWakeupMap = json.decode(str);
      _autoWakeupMap.forEach((key, value) {
        _requestNode(key);
        if (value.isNotEmpty) {
          NodeClient client = _getOrAddNode(key, value["ip"], value["port"]);
          client.wakeUp(key);
        }
      });
    }
  }

  Future<bool> checkAutoWakeup(String did) async {
    if (_autoWakeupMap.isEmpty) {
      await autoWakeup();
    }
    return _autoWakeupMap.containsKey(did);
  }

  Future<void> saveAutoWakeup(String did) async {
    if (_deviceNodes.containsKey(did)) {
      NodeClient client = _deviceNodes[did]!;
      _autoWakeupMap[did] = {"ip": client.ip, "port": client.port};
      SharedPreferences sp = await SharedPreferences.getInstance();
      await sp.setString(shareKey, json.encode(_autoWakeupMap));
    } else {
      _autoWakeupMap[did] = {};
      _requestNode(did);
    }
  }

  Future<void> removeAutoWakeup(String did) async {
    if (_autoWakeupMap.containsKey(did)) {
      SharedPreferences sp = await SharedPreferences.getInstance();
      _autoWakeupMap.remove(did);
      await sp.setString(shareKey, json.encode(_autoWakeupMap));
    }
  }

  void close() {
    _deviceState.clear();
    if (_clientNodes != null && _clientNodes.isNotEmpty) {
      _clientNodes.forEach((key, value) {
        value.close();
      });
      _clientNodes.clear();
    }
    _deviceNodes.clear();
  }
}

class DeviceWakeUpServer {
  // ignore: non_constant_identifier_names
  static String SP_KEY = "wakeup_device";

  /// 单例
  static DeviceWakeUpServer? _instance;

  /// 将构造函数指向单例
  factory DeviceWakeUpServer() => getInstance();

  ///获取单例
  static DeviceWakeUpServer getInstance() {
    if (_instance == null) {
      _instance = new DeviceWakeUpServer._internal();
    }
    return _instance!;
  }

  late WakeupServer _mobileServer;
  late WakeupServer _wifiServer;

  void reloadAagin() {
    _instance = null;
    _instance = new DeviceWakeUpServer._internal();
  }

  String lowPath = 'liteos-master.eye4.cn';

  DeviceWakeUpServer._internal() {
    _wifiServer =
        WakeupServer(lowPath, 32320, 5, "WIFI_WAKE_KEY", _stateListener);
    _mobileServer =
        WakeupServer(lowPath, 12320, 5, "MOBILE_WAKE_KEY", _stateListener);
  }

  HashMap<String, List<DeviceWakeupStateChanged>> _listeners = HashMap();

  Map<String, DeviceWakeupState> _deviceState = Map();
  Map _deviceLastServer = Map();
  HashMap<String, bool> _notWifiNodes = HashMap();
  HashMap<String, bool> _notMobileNodes = HashMap();
  HashMap<String, bool> _hasNodes = HashMap();

  void addHasNode(String did) {
    _hasNodes[did] = true;
  }

  void addNotNode(int port, String did) {
    if (port == 32320)
      _notWifiNodes[did] = true;
    else
      _notMobileNodes[did] = true;
  }

  bool hasNotNode(int port, String did) {
    if (port == 32320)
      return _notWifiNodes[did] ?? true;
    else
      return _notMobileNodes[did] ?? true;
  }

  bool checkNotNode(String did) {
    if (_notWifiNodes[did] == true && _notMobileNodes[did] == true) return true;
    return false;
  }

  void removeNotNode(int port, String did) {
    if (port == 32320)
      _notWifiNodes.remove(did);
    else
      _notMobileNodes.remove(did);
  }

  void _stateListener(String did, String serverKey, DeviceWakeupState state) {
    if (_listeners.containsKey(did) && _deviceState[did] != state) {
      if (_deviceLastServer.containsKey(did) && _deviceState.containsKey(did)) {
        if (_deviceLastServer[did] != serverKey) {
          if (state.index < _deviceState[did]!.index) {
            return;
          }
        }
      }
      _deviceState[did] = state;
      _deviceLastServer[did] = serverKey;
      List<DeviceWakeupStateChanged>? listeners = _listeners[did];
      if (listeners != null) {
        for (DeviceWakeupStateChanged item in listeners) {
          item(did, state);
        }
      }
    }
  }

  void removeListener(String did, DeviceWakeupStateChanged listener) {
    List<DeviceWakeupStateChanged>? listeners = _listeners[did];
    if (listeners != null) {
      listeners.remove(listener);
    }
  }

  void addListener(String did, DeviceWakeupStateChanged listener) {
    List<DeviceWakeupStateChanged>? listeners = _listeners[did];
    if (listeners == null) {
      listeners = [];
      _listeners[did] = listeners;
    }
    if (_deviceState.containsKey(did)) listener(did, _deviceState[did]!);
    listeners.add(listener);
  }

  void wakeup(String did) {
    _wifiServer.wakeup(did);
    _mobileServer.wakeup(did);
  }

  void getStatus(String did) {
    _wifiServer.getStatus(did);
    _mobileServer.getStatus(did);
  }

  Future<void> autoWakeup() async {
    await _wifiServer.autoWakeup();
    await _mobileServer.autoWakeup();
  }

  Future<bool> checkAutoWakeup(String did) async {
    return await _wifiServer.checkAutoWakeup(did);
  }

  Future<void> saveAutoWakeup(String did) async {
    await _wifiServer.saveAutoWakeup(did);
    await _mobileServer.saveAutoWakeup(did);
  }

  Future<void> removeAutoWakeup(String did) async {
    await _wifiServer.removeAutoWakeup(did);
    await _mobileServer.removeAutoWakeup(did);
  }

  void close() {
    _wifiServer.close();
    _mobileServer.close();
    _listeners.clear();
    _deviceLastServer.clear();
    _deviceState.clear();
  }
}

class NodeClient {
  final String ip;
  final int port;
  late SocketServer _socketServer;

  DeviceWakeupStateChanged? listener;

  NodeClient(this.ip, this.port, this.listener) {
    _socketServer = SocketServer(ip, port, _dataListen);
    _register();
  }

  void _register() {
    String str = json.encode(_encryptionMap({"event": "register"}));
    List<int> bytes = utf8.encode(str);
    var buffer = _socketBuffer(bytes);
    _socketServer.send(buffer);
  }

  void _callback(String did, DeviceWakeupState state) {
    if (listener != null) listener!(did, state);
  }

  Timer? _timer;

  void close() {
    _timer?.cancel();
    _socketServer.close();
  }

  void _dataListen(String data) {
    if (data != null) {
      Map map = json.decode(data);
      print("_dataListen map ${map}");
      if (map != null) {
        if (map["event"] == "register") {
          // _timer?.cancel();
          // _timer = Timer.periodic(Duration(seconds: 3), (timer) {
          //   if (DateTime
          //       .now()
          //       .millisecondsSinceEpoch - _lastTime > 3) {
          //     _socketServer.send([0, 0, 0, 0]);
          //   }
          // });
        } else if (map["event"] == "timeout") {
        } else if (map["event"] == "getStatus") {
          String did = map["did"];
          var status = map['status'];
          if (status == 'activation') {
            _callback(did, DeviceWakeupState.online);
          } else if (status == 'sleep') {
            _callback(did, DeviceWakeupState.sleep);
          } else if (status == 'offline') {
            _callback(did, DeviceWakeupState.offline);
          } else if (status == 'ULPC') {
            _callback(did, DeviceWakeupState.deepSleep);
          } else if (status == 'power_off') {
            _callback(did, DeviceWakeupState.poweroff);
          } else if (status == 'ULPC2') {
            _callback(did, DeviceWakeupState.microPower);
          } else if (status == 'LBS') {
            _callback(did, DeviceWakeupState.lowPowerOff);
          }
        } else if (map["event"] == "toDevice") {
        } else if (map["event"] == "sleep") {
          String did = map["did"];
          _callback(did, DeviceWakeupState.sleep);
        } else if (map["event"] == "online") {
          String did = map["did"];
          _callback(did, DeviceWakeupState.online);
        } else if (map["event"] == "offline") {
          String did = map["did"];
          _callback(did, DeviceWakeupState.offline);
        } else if (map["event"] == "ULPC") {
          String did = map["did"];
          _callback(did, DeviceWakeupState.deepSleep);
        } else if (map["event"] == "power_off") {
          String did = map["did"];
          _callback(did, DeviceWakeupState.poweroff);
        } else if (map["event"] == 'ULPC2') {
          String did = map["did"];
          _callback(did, DeviceWakeupState.microPower);
        } else if (map["event"] == 'LBS') {
          String did = map["did"];
          _callback(did, DeviceWakeupState.lowPowerOff);
        }
      }
    }
  }

  void getStatus(String did) {
    String str =
        json.encode(_encryptionMap({'event': 'getStatus', 'did': did}));
    List<int> bytes = utf8.encode(str);
    var buffer = _socketBuffer(bytes);
    _socketServer.send(buffer);
  }

  void wakeUp(String did) {
    String str = json.encode(
        _encryptionMap({"event": "toDevice", "did": did, "cmd": "wakeup"}));
    List<int> bytes = utf8.encode(str);
    var buffer = _socketBuffer(bytes);
    var now = DateTime.now();
    _socketServer.send(buffer);
  }
}
