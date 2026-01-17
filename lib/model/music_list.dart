import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'music.dart';

class MusicList extends ChangeNotifier {
  // 为了保证使用`MusicList()`可以调用到同一实例，以及watch的时候能正确监听到实例的变化
  static final MusicList _instance = MusicList._privateInit();

  MusicList._privateInit(); // 具名构造函数

  factory MusicList() {
    return _instance;
  }

  List<Music> list = [];
  int currentIndex = 0;

  Future<void> initialize() async {
    list = await read();
    if (list.isNotEmpty) {
      currentIndex = 0;

      notifyListeners();
    }
  }

  Music currentMusic() {
    return list[currentIndex];
  }

  void playMusic(int index) {
    if (!(0 <= index && index < list.length)) {
      throw "invalid index.";
    }

    currentIndex = index;

    notifyListeners();
  }

  void nextMusic() {
    if (list.isEmpty) {
      throw "no data.";
    }

    currentIndex++;
    if (currentIndex >= list.length) {
      currentIndex = 0;
    }

    notifyListeners();
  }

  Future<void> create(Music? musicIns, {bool atFirst = true}) async {
    if (musicIns != null) {
      if (atFirst) {
        list.insert(0, musicIns);
      } else {
        list.add(musicIns);
      }
    }

    await write(list);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    if (list.length == 1) {
      throw "list should have at least 1 item.";
    }

    int index = _getIndex(id);
    if (index < 0) {
      return; // target 'id' not exist
    }

    list.removeAt(index);

    await write(list);
    notifyListeners();
  }

  Future<void> reOrder(String id, int wantedIndex) async {
    if (!(0 <= wantedIndex && wantedIndex <= list.length)) {
      throw "无效的目标索引位置"; // use 'insert' as 'push' is ok
    }

    int index = _getIndex(id);
    if (index < 0 || wantedIndex == index) {
      return; // target 'key' not exist / no-reorder
    }

    Music musicIns = list[index];
    list.insert(wantedIndex, musicIns);
    list.removeAt(index > wantedIndex ? index + 1 : index);

    await write(list);
    notifyListeners();
  }

  // for dev
  String display() {
    String res = "> Music List Length: ${list.length}\n";
    for (var i = 0; i < list.length; i++) {
      res +=
          "> item $i: \n"
          "  id: ${list[i].id},\n"
          "  name: ${list[i].name},\n"
          "  url: ${list[i].bv},\n"
          "  volume: ${list[i].volume},\n";
    }

    return res;
  }

  // _getIndex return index of target 'id' in this.list,
  // if target 'id' is NOT exist, return -1
  int _getIndex(String id) {
    int index = 0;
    for (; index < list.length; index++) {
      if (list[index].id == id) {
        break;
      }
    }

    if (index >= list.length) {
      index = -1;
    }

    return index;
  }
}

Future<List<Music>> read([bool? isTestMod]) async {
  List<Music> listIns = [];
  String fileStr = "";

  try {
    File fileIns = await _openFile(isTestMod);
    fileStr = await fileIns.readAsString();
  } catch (err) {
    return listIns;
  }

  for (var value in jsonDecode(fileStr)) {
    listIns.add(Music.fromJson(value));
  }

  return listIns;
}

Future<void> write(List<Music> l, [bool? isTestMod]) async {
  File fileIns = await _openFile(isTestMod);
  await fileIns.writeAsString(jsonEncode(l));
}

Future<File> _openFile([bool? isTestMod]) async {
  String fileName = "music_list.json";

  if (isTestMod != null && isTestMod) {
    return File("./$fileName");
  }

  final directory = await getApplicationDocumentsDirectory();
  final path = directory.path;

  return File("$path/$fileName");
}
