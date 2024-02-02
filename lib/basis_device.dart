import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:path_provider/path_provider.dart';

abstract class ListenEvent extends Equatable {
  @override
  bool get stringify => true;

  @override
  List<Object?> get props => [];
}

class AddListenEvent<T> extends ListenEvent {
  final T listener;

  AddListenEvent(this.listener);

  @override
  List<Object?> get props => [listener];
}

class RemoveListenEvent<T> extends ListenEvent {
  final T listener;

  RemoveListenEvent(this.listener);

  @override
  List<Object?> get props => [listener];
}

class ActionListenEvent extends ListenEvent {
  final Function callback;
  final Type type;

  ActionListenEvent(this.callback, this.type);

  @override
  List<Object> get props => [callback, type];
}

///基础设备
abstract class BasisDevice {
  late StreamController<ListenEvent> _controller;

  BasisDevice(this.id, this.name, this.model) {
    _controller = StreamController<ListenEvent>();
    _controller.stream.asyncMap(_funcListen).listen((event) {});
  }

  _funcListen(ListenEvent event) {
    if (event is AddListenEvent) {
      _listeners.add(event.listener);
    } else if (event is RemoveListenEvent) {
      _listeners.remove(event.listener);
    } else if (event is ActionListenEvent) {
      for (var func in _listeners) {
        if (func.runtimeType == event.type) {
          Function.apply(event.callback, [func]);
        }
      }
    }
    return event;
  }

  List _listeners = [];

  void addListener<T>(T listener) {
    if (!_controller.isClosed) _controller.add(AddListenEvent<T>(listener));
  }

  void removeListener<T>(T listener) {
    if (!_controller.isClosed) _controller.add(RemoveListenEvent<T>(listener));
  }

  void notifyListeners<T>(void Function(T listener) callback) {
    if (!_controller.isClosed) _controller.add(ActionListenEvent(callback, T));
    // _listeners.forEach((func) {
    //   if (func is T) {
    //     callback(func);
    //   }
    // });
  }

  void cleanListener() {
    _controller.close();
    _listeners.clear();
  }

  ///设备名称
  final String name;

  ///设备ID
  final String id;

  /// 设备型号
  final String model;

  Future<Directory> getDeviceDirectory() async {
    // return null;
    Directory dir = await getApplicationDocumentsDirectory();
    dir = Directory("${dir.path}/$id");
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }
}
