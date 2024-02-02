import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fast_gbk/fast_gbk.dart';

import '../app_p2p_api.dart';
import 'p2p_connect.dart';
import 'p2p_device.dart';

typedef bool CommandFilterFunc(int cmd, Uint8List data);
typedef void CommandCallbackFunc(int cmd, CommandResult result);

class CommandCondition {
  final CommandFilterFunc filter;
  Completer<CommandResult> completer;

  CommandCondition(this.filter, this.completer);
}

class UTF8Check {
  int _getUtf8charByteNum(int ch) {
    int byteNum = 0;

    if (ch >= 0xFC && ch < 0xFE)
      byteNum = 6;
    else if (ch >= 0xF8)
      byteNum = 5;
    else if (ch >= 0xF0)
      byteNum = 4;
    else if (ch >= 0xE0)
      byteNum = 3;
    else if (ch >= 0xC0)
      byteNum = 2;
    else if (0 == (ch & 0x80)) byteNum = 1;

    return byteNum;
  }

  bool isUtf8Format(List<int> buffer) {
    if (buffer == null || buffer.length == 0) return false;
    int byteNum = 0;
    int ch = 0;
    int off = 0;

    do {
      ch = buffer[off];
      if (byteNum == 0) {
        if (0 == (byteNum = _getUtf8charByteNum(ch))) return false;
      } else {
        if ((ch & 0xC0) != 0x80) return false;
      }
      byteNum--;
      off++;
    } while (off < buffer.length);

    if (byteNum > 0) return false;

    return true;
  }
}

class CommandResult {
  final bool isSuccess;
  final int cmd;
  final Uint8List? data;
  static UTF8Check utf8check = UTF8Check();

  CommandResult(this.isSuccess, this.cmd, this.data);

  String getString() {
    if (data == null) {
      return "";
    }
    try {
      return utf8.decode(data!);
    } catch (e) {
      return gbk.decode(data!);
    }
  }

  String getString2(List<int> buffer) {
    if (buffer == null) {
      return "";
    }
    if (utf8check.isUtf8Format(buffer)) {
      try {
        return utf8.decode(buffer, allowMalformed: true);
      } catch (e) {
        return String.fromCharCodes(buffer);
      }
    } else {
      try {
        return gbk.decode(buffer, allowMalformed: true);
      } catch (e) {
        return String.fromCharCodes(buffer);
      }
    }
  }

  List<int> _replaceAll(Map<int, int> replace) {
    var newData = data?.toList() ?? [];
    List<int> removeList = [];
    for (int i = 0; i < newData.length; i++) {
      var item = newData[i];
      if (replace.containsKey(item)) {
        var value = replace[item];
        if (value == 0) {
          removeList.add(i);
        } else {
          newData[i] = value!;
        }
      }
    }
    var removeLen = 0;
    removeList.forEach((element) {
      newData.removeAt(element - removeLen);
      removeLen += 1;
    });
    return newData;
  }

  List<List<int>> _split(List<int> data, int sp) {
    List<List<int>> splitBuffer = [];
    int index = 0;
    int start = 0;
    while (index >= 0) {
      index = data.indexOf(sp, start);
      if (index > 0) {
        var spBuffer = data.getRange(start, index).toList();
        splitBuffer.add(spBuffer);
        start = index + 1;
      }
    }
    return splitBuffer;
  }

  Map getMap() {
    if (data == null || data!.length == 0) return {};
    var newData = _replaceAll({'\r'.codeUnitAt(0): 0, '\n'.codeUnitAt(0): 0});
    var lines = _split(newData, ';'.codeUnitAt(0));
    Map maps = Map();
    lines.forEach((buffer) {
      var line = getString2(buffer);
      if (line.contains("=")) {
        List<String> keyValue = line.split("=");
        if (keyValue.length >= 2) {
          if (keyValue[0].trim().replaceAll("var ", "") == 'AiCfg') {
            var value = keyValue[1].trim().replaceFirst('"', '');
            int lastIndex = value.lastIndexOf('"');
            value = value.substring(0, lastIndex);
            maps.putIfAbsent(
                keyValue[0].trim().replaceAll("var ", ""), () => value.trim());
          } else {
            maps.putIfAbsent(keyValue[0].trim().replaceAll("var ", ""),
                () => keyValue[1].trim().replaceAll('"', ""));
          }
        }
      }
    });

    return maps;
  }
}

mixin P2PCommand on P2PBasisDevice, P2PConnect {
  List<CommandCondition> _commandFilters = [];
  Map<int, CommandCallbackFunc> _callbackMaps = Map();

  void _onCommandListener(int cmd, Uint8List data) {
    List<CommandCondition> _remove = [];
    for (var item in _commandFilters) {
      if (item.filter != null && item.filter(cmd, data)) {
        _remove.add(item);
        if (item.completer != null && !item.completer.isCompleted) {
          item.completer.complete(CommandResult(true, cmd, data));
        }
        break;
      } else {}
    }
    if (_remove.length == 0) {
      if (_callbackMaps.containsKey(cmd)) {
        _callbackMaps[cmd]!(cmd, CommandResult(true, cmd, data));
      }
    }
    _remove.forEach((item) {
      _commandFilters.remove(item);
    });
  }

  void addCallback(int cmd, CommandCallbackFunc func) {
    _callbackMaps[cmd] = func;
  }

  void removeCallback(int cmd) {
    _callbackMaps.remove(cmd);
  }

  ///数据发送,用于发送原始数据
  Future<bool> write(
      ClientChannelType channel, Uint8List buffer, int timeout) async {
    if (p2pConnectState != ClientConnectState.CONNECT_STATUS_ONLINE) {
      return false;
    }
    int clientPtr = await getClientPtr();
    int ret =
        await AppP2PApi().clientWrite(clientPtr, channel, buffer, timeout);
    return ret == buffer.length;
  }

  /// 发送CGI指令
  /// 底层封装CGI数据格式
  Future<bool> writeCgi(String cgi,
      {int timeout = 5, bool needLogin = true}) async {
    if (p2pConnectState != ClientConnectState.CONNECT_STATUS_ONLINE) {
      return false;
    }
    int clientPtr = await getClientPtr();
    bool bl =
        await AppP2PApi().clientWriteCgi(clientPtr, cgi, timeout: timeout);
    if (bl != true) {
      bl = await AppP2PApi().clientWriteCgi(clientPtr, cgi, timeout: timeout);
    }

    return bl;
  }

  ///等待指令返回
  ///@param [filterFunc] 指令筛选条件
  ///@param [timeout] 等待时间 秒为单位
  ///
  ///@return [CommandResult]
  Future<CommandResult> waitCommandResult(
      CommandFilterFunc filterFunc, int timeout) async {
    Completer<CommandResult> completer = Completer();
    CommandCondition condition = CommandCondition(filterFunc, completer);
    Future.delayed(Duration(seconds: timeout), () {
      _commandFilters.remove(condition);
      if (!completer.isCompleted) {
        completer.complete(CommandResult(false, 0, null));
      }
    });
    _commandFilters.add(condition);
    return completer.future;
  }

  /// 设置指令监听
  Future<void> setCommandListener() async {
    int clientPtr = await getClientPtr();
    AppP2PApi().setCommandListener(clientPtr, _onCommandListener);
  }

  /// 移除指令监听
  void removeCommandListener() async {
    int clientPtr = await getClientPtr();
    AppP2PApi().removeCommandListener(clientPtr);
  }
}
