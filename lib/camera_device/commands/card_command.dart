import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';

import '../../p2p_device/p2p_command.dart';
import 'camera_command.dart';

class RecordFile {
  // ignore: non_constant_identifier_names
  String? record_name;

  // 0 实时录像
  // 1 报警录像
  // ignore: non_constant_identifier_names
  int? record_alarm;

  // ignore: non_constant_identifier_names
  int record_size = 0;

  // ignore: non_constant_identifier_names
  int record_cache_size = 0;

  // ignore: non_constant_identifier_names
  DateTime? record_time;

  // ignore: non_constant_identifier_names
  bool? record_head;

  RecordTimeLineFile? lineFile;

  RecordFile.fromData(int i, bool recordHead, Map data,
      {bool isTypeSearch = false}) {
    this.record_head = recordHead;
    if (isTypeSearch == true) {
      this.record_name = data["record_name[$i]"];
      this.record_size = int.tryParse(data["record_size[$i]"] ?? "0")!;
    } else {
      this.record_name = data["record_name0[$i]"];
      this.record_size = int.tryParse(data["record_size0[$i]"] ?? "0")!;
    }
    record_alarm = 0;
    record_time = DateTime.now();
    List<String> splits = this.record_name?.split("_") ?? [];
    if (splits.length > 1 && splits[1].contains("010")) {
      record_alarm = 1;
    } else if (splits.length > 1 && splits[1].contains("011")) {
      record_alarm = 2;
    } else if (splits.length > 1 && splits[1].contains("012")) {
      record_alarm = 3;
    } else if (splits.length > 1 && splits[1].contains("013")) {
      record_alarm = 4;
    } else if (splits.length > 1 && splits[1].contains("014")) {
      //区域入侵
      record_alarm = 5;
    } else if (splits.length > 1 && splits[1].contains("015")) {
      //人逗留
      record_alarm = 6;
    } else if (splits.length > 1 && splits[1].contains("016")) {
      //车违停
      record_alarm = 7;
    } else if (splits.length > 1 && splits[1].contains("017")) {
      //越线检测
      record_alarm = 8;
    } else if (splits.length > 1 && splits[1].contains("018")) {
      //离岗检测
      record_alarm = 9;
    } else if (splits.length > 1 && splits[1].contains("019")) {
      //车辆逆行
      record_alarm = 10;
    } else if (splits.length > 1 && splits[1].contains("020")) {
      //包裹
      record_alarm = 11;
    }
    String date = splits[0];
    if (date != null) {
      int? year = int.tryParse(date.substring(0, 4));
      int? month = int.tryParse(date.substring(4, 6));
      int? day = int.tryParse(date.substring(6, 8));
      int? hour = int.tryParse(date.substring(8, 10));
      int? minute = int.tryParse(date.substring(10, 12));
      int? second = int.tryParse(date.substring(12, 14));
      if (year == null ||
          month == null ||
          day == null ||
          hour == null ||
          minute == null ||
          second == null) {
        return;
      }
      record_time = DateTime(year, month, day, hour, minute, second);
    }
  }

  String toString() {
    return ("record_alarm:$record_alarm "
        "record_name:$record_name "
        "record_size:$record_size "
        "record_time:$record_time");
  }

  @override
  bool operator ==(Object other) {
    if (super == other) {
      return true;
    }
    if (other is RecordFile) {
      return other.record_name == this.record_name;
    }
    return false;
  }
}

class RecordTimeLineFrame {
  /// 关键帧时间戳
  DateTime? timestamp;

  /// 关键帧序号
  // ignore: non_constant_identifier_names
  int? frame_no;

  /// 帧间隔
  // ignore: non_constant_identifier_names
  int? frame_gop;

  String toString() {
    return ("timestamp:$timestamp "
        "frame_no:$frame_no "
        "frame_gop:$frame_gop ");
  }
}

class RecordTimeLineData {
  ByteData? bytes;
  Uint8List? data;
  int? bytesOffset;
  int? offset;

  RecordTimeLineData(Uint8List data, int offset) {
    this.bytes = ByteData.view(data.buffer, offset);
    this.data = data;
    this.bytesOffset = offset;
    this.offset = 0;
  }
}

class RecordTimeLineFile {
  // ignore: non_constant_identifier_names
  String record_name = "";

  // ignore: non_constant_identifier_names
  int record_time = 0;

  // 0 实时录像
  // 1 报警录像
  // 2 人形报警
  // ignore: non_constant_identifier_names
  int record_alarm = 0;

  /// 录像开始时间
  // ignore: non_constant_identifier_names
  DateTime? record_start;

  /// 录像结束时间
  // ignore: non_constant_identifier_names
  DateTime? record_end;

  ///录像时长
  // ignore: non_constant_identifier_names
  int record_duration = 0;

  // ignore: non_constant_identifier_names
  int frame_len = 0;

  // ignore: non_constant_identifier_names
  int frame_interval = 0;

  List<RecordTimeLineFrame> frames = [];

  static String _fourDigits(int n) {
    int absN = n.abs();
    String sign = n < 0 ? "-" : "";
    if (absN >= 1000) return "$n";
    if (absN >= 100) return "${sign}0$absN";
    if (absN >= 10) return "${sign}00$absN";
    return "${sign}000$absN";
  }

  static String _twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  static String _eventName(int type) {
    switch (type) {
      case 0:
        return "100";
      case 1:
        return "010";
      case 2:
        return "011";
      case 3:
        return "012";
      case 4:
        return "013";
      case 5:
        return "014"; //区域入侵
      case 6:
        return "015"; //人逗留
      case 7:
        return "016"; //车违停
      case 8:
        return "017"; //越线检测
      case 9:
        return "018"; //离岗检测
      case 10:
        return "019"; //车辆逆行
      case 11:
        return "020"; //包裹
    }
    return "";
  }

  static String dateString(DateTime dateTime) {
    return '${_fourDigits(dateTime.year)}${_twoDigits(dateTime.month)}${_twoDigits(dateTime.day)}';
  }

  static String dateTimeString(DateTime dateTime) {
    return '${_fourDigits(dateTime.year)}${_twoDigits(dateTime.month)}${_twoDigits(dateTime.day)}'
        '${_twoDigits(dateTime.hour)}${_twoDigits(dateTime.minute)}${_twoDigits(dateTime.second)}';
  }

  static RecordTimeLineFile? fromData(RecordTimeLineData timeLineData) {
    var bytes = timeLineData.bytes!;
    int byteOffset = 0;
    int type = bytes.getUint8(byteOffset);
    byteOffset += 1;
    if ((type & 0x03) != 0x00) {
      timeLineData.offset = byteOffset;
      return null;
    }

    RecordTimeLineFile lineFile = RecordTimeLineFile();
    lineFile.record_alarm = (type & 0xFC) >> 2;
    var timestamp = bytes!.getUint32(byteOffset, Endian.little);
    byteOffset += 4;
    timeLineData.offset = byteOffset;
    var dateTime =
        DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true);
    lineFile.record_time = timestamp;
    lineFile.record_name =
        '${dateTimeString(dateTime)}_${_eventName(lineFile.record_alarm!)}.mp4';
    lineFile.frame_len = bytes.getUint16(byteOffset, Endian.little);
    byteOffset += 2;
    timeLineData.offset = byteOffset;
    lineFile.frame_interval = bytes.getUint8(byteOffset);
    byteOffset += 1;
    timeLineData.offset = byteOffset;
    for (int i = 0; i < lineFile.frame_len!; i++) {
      type = bytes.getInt8(byteOffset);
      byteOffset += 1;
      timeLineData.offset = byteOffset;
      if ((type & 0x03) != 0x01) continue;
      RecordTimeLineFrame lineFrame = RecordTimeLineFrame();
      timestamp = bytes.getUint32(byteOffset, Endian.little);
      byteOffset += 4;
      timeLineData.offset = byteOffset;
      lineFrame.timestamp =
          DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true);
      if (lineFile.record_start == null)
        lineFile.record_start = lineFrame.timestamp;
      lineFrame.frame_no = bytes.getUint16(byteOffset, Endian.little);
      byteOffset += 2;
      timeLineData.offset = byteOffset;
      lineFrame.frame_gop = bytes.getUint8(byteOffset);
      if (lineFrame.frame_gop == 45) lineFile.frame_interval = 3;
      byteOffset += 1;
      timeLineData.offset = byteOffset;
      lineFile.frames.add(lineFrame);
    }
    type = bytes.getInt8(byteOffset);
    byteOffset += 1;
    timeLineData.offset = byteOffset;
    if ((type & 0x03) != 0x02) {
      timeLineData.offset = byteOffset;
      return null;
    }
    timestamp = bytes.getUint32(byteOffset, Endian.little);
    byteOffset += 4;
    timeLineData.offset = byteOffset;
    lineFile.record_end =
        DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true);
    lineFile.record_duration =
        lineFile.record_end?.difference(lineFile.record_start!).inSeconds ?? 0;
    lineFile.frame_len = bytes.getUint16(byteOffset, Endian.little);
    byteOffset += 2;
    timeLineData.offset = byteOffset;
    bytes.getUint8(byteOffset);
    byteOffset += 1;
    timeLineData.offset = byteOffset;
    return lineFile;
  }

  String toString() {
    return ("record_alarm:$record_alarm "
        "record_name:$record_name "
        "record_start:$record_start "
        "record_end:$record_end "
        "record_duration:$record_duration "
        "frame_len:$frame_len "
        "frame_interval:$frame_interval "
        "frames:$frames ");
  }

  @override
  bool operator ==(Object other) {
    if (super == other) {
      return true;
    }
    if (other is RecordTimeLineFile) {
      return other.record_name == this.record_name;
    }
    return false;
  }
}

class RecordTimeLineDown {
  final String name;
  final int start;
  final int end;

  RecordTimeLineDown(this.name, this.start, this.end);

  Map getData() {
    return {"f": name, "s": start, "e": end};
  }
}

mixin CardCommand on CameraCommand {
  List<RecordFile> recordFileList = [];
  Map<String, List<RecordTimeLineFile>> _lineFileCache = Map();
  int pageCount = 1;

  void _setRecordInfo(List<RecordFile> files, Map data) {
    String result = data["result"];
    String supportRecordHead = data["support_record_head"] ?? "0";
    if (result == "0") {
      String recordNum = data["record_num0"] ?? "";
      pageCount = int.tryParse(data["PageCount"] ?? "0")!;
      int apNumber = int.tryParse(recordNum) ?? 0;
      for (int i = 0; i < apNumber; i++) {
        var recordName = data["record_name0[$i]"];
        if (recordName == null || recordName.toString().length < 14) {
          continue;
        }
        var recordFile = RecordFile.fromData(i, supportRecordHead == '1', data);
        // if(recordFile.record_time.difference(DateTime.now()).inDays > 0){
        //   //过滤文件时间错误
        //   continue;
        // }
        dynamic file = null;
        if (recordFileList.isNotEmpty) {
          file = recordFileList
              .firstWhereOrNull((element) => element == recordFile);
        }
        if (files.length > 0 && file == null) {
          file = files.firstWhereOrNull((element) => element == recordFile);
        }
        if (file == null)
          files.add(recordFile);
        else
          file.record_size = recordFile.record_size;
      }
    }
  }

  Future<List<RecordFile>> _getRecordFile(int pageSize, int pageIndex,
      {int timeout = 5}) async {
    List<RecordFile> files = [];
    if (pageIndex == 0) {
      var date = DateTime.now();
      var key = RecordTimeLineFile.dateString(date);
      await getRecordLineFile(key, cache: false);
    }
    bool ret = await writeCgi(
        "get_record_file.cgi?PageSize=$pageSize&PageIndex=$pageIndex&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24583;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        _setRecordInfo(files, data);
      }
    }
    List<RecordTimeLineFile> lines = [];
    for (var item in files) {
      var key = item.record_name!.substring(0, 8);
      if (_lineFileCache.containsKey(key)) {
        lines = _lineFileCache[key]!;
      } else {
        lines = await getRecordLineFile(key, cache: false);
      }
      var element = lines.firstWhereOrNull(
          (element) => element.record_name == item.record_name);
      item.lineFile = element;
    }
    return files;
  }

  void _setTypeSeachRecordInfo(List<RecordFile> files, Map data) {
    String result = data["result"];
    String supportRecordHead = data["support_record_head"];
    if (result == "0") {
      String recordNum = data["record_filenum"] ?? "0";
      int apNumber = int.tryParse(recordNum) ?? 0;
      for (int i = 0; i < apNumber; i++) {
        var recordName = data["record_name[$i]"];
        if (recordName == null || recordName.toString().length < 14) {
          continue;
        }
        var recordFile = RecordFile.fromData(i, supportRecordHead == '1', data,
            isTypeSearch: true);

        var file =
            recordFileList.firstWhereOrNull((element) => element == recordFile);
        if (file == null) {
          file = files.firstWhereOrNull((element) => element == recordFile);
        }
        if (file == null)
          files.add(recordFile);
        else
          file.record_size = recordFile.record_size;
      }
    }
  }

  ///当天所有录像文件 dirname=20230322&
  Future<List<RecordFile>> _getTypeSeachRecordFile(String dirname,
      {int timeout = 5}) async {
    List<RecordFile> files = [];
    String _twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    DateTime dateTime = DateTime.now();
    String year = dateTime.year.toString();
    String month = _twoDigits(dateTime.month);
    String day = _twoDigits(dateTime.day);
    String dateName = year + month + day;
    if (dirname == dateName) {
      var key = RecordTimeLineFile.dateString(dateTime);
      await getRecordLineFile(key, cache: false);
    }
    bool ret = await writeCgi(
        "get_record_file.cgi?GetType=file&dirname=$dirname&",
        timeout: timeout);
    if (ret) {
      CommandResult result;
      while (true) {
        result = await waitCommandResult((int cmd, Uint8List data) {
          return cmd == 24583;
        }, timeout);
        if (result.isSuccess) {
          Map data = result.getMap();
          _setTypeSeachRecordInfo(files, data);
          String currentPage = data["current_page"];
          String totolPage = data["totol_page"];
          if (currentPage == null ||
              totolPage == null ||
              currentPage == totolPage) {
            break;
          }
        } else {
          break;
        }
      }
    }
    List<RecordTimeLineFile> lines = [];
    for (var item in files) {
      var key = item.record_name!.substring(0, 8);
      if (_lineFileCache.containsKey(key)) {
        lines = _lineFileCache[key]!;
      } else {
        lines = await getRecordLineFile(key, cache: false);
      }
      var element = lines.firstWhereOrNull(
          (element) => element.record_name == item.record_name);
      item.lineFile = element;
    }
    return files;
  }

  List<RecordTimeLineFile> getAllLineFile() {
    List<RecordTimeLineFile> files = [];
    _lineFileCache.forEach((key, value) {
      files.addAll(value);
    });
    return files;
  }

  Future<bool> getRecordData(
      String date, List<int> data, int timeout, int offset) async {
    bool ret = await writeCgi("get_record_idx.cgi?dirname=$date&offset=$offset",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24833;
      }, timeout);

      if (result.isSuccess && result.data!.lengthInBytes > 12) {
        data.addAll(result.data!.getRange(12, result.data!.lengthInBytes));
        if (result.data!.lengthInBytes == 60000 + 12)
          return getRecordData(date, data, timeout, offset + 1);
      }
    } else {}
    return ret;
  }

  Future<List<RecordTimeLineFile>> getRecordLineFile(String date,
      {bool cache = true, int timeout = 5}) async {
    var timeLine = int.tryParse(statusResult?.support_time_line ?? "0") ?? 0;
    if (timeLine < 1) {
      _lineFileCache[date] = [];
      return [];
    }
    if (cache == true) {
      if (_lineFileCache.containsKey(date)) return _lineFileCache[date] ?? [];
    }
    List<RecordTimeLineFile> files = [];
    List<int> data = [];

    bool ret = await getRecordData(date, data, timeout, 0);
    if (ret) {
      var offset = 0;
      while (offset < data.length) {
        var lineData = RecordTimeLineData(Uint8List.fromList(data), offset);
        RecordTimeLineFile? item;
        try {
          item = RecordTimeLineFile.fromData(lineData);
        } catch (ex) {
          item = null;
        }
        if (item != null) {
          files.add(item);
        } else {
          if (lineData.offset == 0) break;
        }
        offset += lineData.offset ?? 0;
      }

      _lineFileCache[date] = files;
    }
    return files;
  }

  Future<List<RecordFile>> getRecordFile({
    int pageIndex = 0,
    int pageSize = 20,
    bool cache = true,
    bool supportRecordTypeSeach = false,
    String? dateName,
    int timeout = 5,
  }) async {
    if (supportRecordTypeSeach == true) {
      if (dateName != null) {
        List<RecordFile> files = await _getTypeSeachRecordFile(dateName);
        recordFileList.addAll(files);
        return recordFileList;
      } else if (cache == false) {
        recordFileList.clear();
        List<String> recordDatas = await getRecordTypeSearchDate();
        for (int i = 0; i < recordDatas.length; i++) {
          String dateName = recordDatas[i];
          List<RecordFile> files = await _getTypeSeachRecordFile(dateName);
          recordFileList.addAll(files);
        }
        return recordFileList;
      } else {
        return recordFileList;
      }
    } else {
      if (pageIndex == null) {
        if (cache == true) {
          return recordFileList;
        }
        pageIndex = 0;
        if (pageCount == 0) {
          pageCount = 1;
        }
        recordFileList.clear();
        while (pageIndex < pageCount) {
          List<RecordFile> files = await _getRecordFile(pageSize, pageIndex);
          pageIndex += 1;
          recordFileList.addAll(files);
        }
        return recordFileList;
      } else {
        if (pageIndex == 0) {
          List<RecordFile> files = await _getRecordFile(pageSize, pageIndex);
          recordFileList.addAll(files);

          ///首次获取数据，把files 添加到recordFileList
          return recordFileList;
        } else {
          if (recordFileList.length >= pageSize * pageIndex + pageSize) {
            return recordFileList;
          }
          List<RecordFile> files = await _getRecordFile(pageSize, pageIndex);
          recordFileList.addAll(files);
          return recordFileList;
        }
      }
    }
  }

  Future<bool> startRecordFile(String recordName, int offset,
      {int timeout = 5}) async {
    bool ret = await writeCgi(
        "livestream.cgi?streamid=4&filename=$recordName&offset=$offset&download=1&",
        timeout: timeout);
    if (ret) {
      //AppTFCardPlayerPlugin.clearTFCardVideoBuf(clientPtr);
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24631;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> startRecordLineFile(int timestamp, int event,
      {int timeout = 5, int channel = 4, int frameNo = 0, int key = 0}) async {
    bool ret = await writeCgi(
        "livestream.cgi?streamid=5&ntsamp=$timestamp&event=$event&framenum=$frameNo&recch=$channel&key=$key&",
        timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24631;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> startRecordLineFileDown(List<RecordTimeLineDown> files,
      {int timeout = 5}) async {
    Map data = Map();
    List download = files.map((e) => e.getData()).toList();

    data["download"] = download;
    var str = "record_fastplay.cgi?ctrl=1&playlist=${jsonEncode(data)}&";

    bool ret = await writeCgi(str, timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24837;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> stopRecordLineFileDown({int timeout = 5}) async {
    bool ret = await writeCgi("record_fastplay.cgi?ctrl=0&", timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24837;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> deleteRecordFile(String recordName, {int timeout = 5}) async {
    bool ret =
        await writeCgi("del_file.cgi?name=$recordName&", timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24606;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        if (data["result"] == "0") {
          recordFileList
              .removeWhere((element) => element.record_name == recordName);
        }
        return data["result"] == "0";
      }
    }
    return false;
  }

  Future<bool> stopRecordFile({int timeout = 5}) async {
    bool ret = await writeCgi("livestream.cgi?streamid=17&", timeout: timeout);
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24631;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        return data["result"] == "0";
      }
    }
    return false;
  }

  //日历摘要
  Future<List<String>> getRecordTypeSearchDate({int timeout = 5}) async {
    bool ret =
        await writeCgi("get_record_file.cgi?GetType=date&", timeout: timeout);
    List<String> recordDate = [];
    if (ret) {
      CommandResult result = await waitCommandResult((int cmd, Uint8List data) {
        return cmd == 24583;
      }, timeout);
      if (result.isSuccess) {
        Map data = result.getMap();
        int count = int.tryParse(data['record_datenum'] ?? '0') ?? 0;
        if (count != 0) {
          for (int i = 0; i < count; i++) {
            String record = data['record_date[$i]'];
            recordDate.add(record);
          }
        }
        return recordDate;
      }
    }
    return recordDate;
  }
}
