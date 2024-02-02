import 'dart:typed_data';

import 'package:vsdk/p2p_device/p2p_command.dart';
import 'package:vsdk/p2p_device/p2p_connect.dart';

import '../../app_p2p_api.dart';

class LoginResult {
  bool? isSuccess;
  int? cmd;

  String? result;

  // ignore: non_constant_identifier_names
  String? current_users;

  // ignore: non_constant_identifier_names
  String? max_support_users;

  LoginResult.form(CommandResult commandResult) {
    isSuccess = false;
    if (commandResult != null && commandResult.isSuccess == true) {
      isSuccess = true;
      cmd = commandResult.cmd;
      try {
        Map data = commandResult.getMap();
        result = data["result"];
        current_users = data["current_users"];
        max_support_users = data["max_support_users"];
      } catch (Exception) {}
    }
  }

  @override
  String toString() {
    return "cmd:$cmd success:$isSuccess {result:$result,current_users:$current_users,max_support_users:$max_support_users}";
  }
}

mixin LoginCommand on P2PCommand {
  /// 登录指令
  Future<LoginResult?> login(String username, String password,
      {int timeout = 5}) async {
    if (p2pConnectState != ClientConnectState.CONNECT_STATUS_ONLINE) {
      return null;
    }
    int clientPtr = await getClientPtr();
    bool ret = await AppP2PApi().clientLogin(clientPtr, username, password);
    if (ret == true) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24736 || cmd == 24577;
      }, timeout);
      if (result.isSuccess) {
        return LoginResult.form(result);
      }
    }

    return null;
  }
}
