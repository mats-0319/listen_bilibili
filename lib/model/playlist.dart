import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:listen_b/dart/result.dart';
import 'package:listen_b/model/default_playlist.dart';
import 'package:listen_b/model/music.dart';
import 'package:path_provider/path_provider.dart';

const String playlistFileName = "playlist.json";

class Playlist extends ChangeNotifier {
  static final Playlist _instance = Playlist._privateInit();

  Playlist._privateInit();

  factory Playlist() => _instance;

  List<Music> list = [];
  int currentIndex = 0;

  Music currentMusic() => list[currentIndex];

  Future<Result<void>> initialize() async {
    Result<File> resFile = await _openFile(playlistFileName);
    if (resFile is Failure) {
      return resFile;
    }

    try {
      final file = (resFile as Success<File>).data;
      String fileStr = await file.readAsString();

      if (fileStr.isNotEmpty) {
        // 空文件decode会报错
        for (var item in jsonDecode(fileStr)) {
          list.add(Music.fromJson(item));
        }
      }
      if (list.isEmpty) {
        // 加载歌单文件成功但是文件为空时，设置默认歌单列表并同步写入歌单文件
        list = defaultPlaylist.toList();
        await synchronized(() {});
      }

      final res = _hasDuplicate();
      if (res is Failure) {
        return res;
      }

      return play(0);
    } catch (e) {
      notifyListeners();
      return Failure(err: e.toString());
    }
  }

  Result<void> next() {
    if (list.isEmpty) {
      return Failure(err: "Empty Playlist");
    }

    currentIndex = (currentIndex + 1) % list.length;
    notifyListeners();

    return Success(data: null);
  }

  Result<void> play(int index) {
    if (!(0 <= index && index < list.length)) {
      return Failure(err: "Invalid index: $index in length: ${list.length}");
    }

    currentIndex = index;
    notifyListeners();

    return Success(data: null);
  }

  Future<Result<void>> create(Music m) async {
    list.insert(0, m);

    final res = _hasDuplicate();
    if (res is Failure) {
      list.removeAt(0);
      return res;
    }

    return await synchronized(() => list.removeAt(0));
  }

  Future<Result<void>> update() async {
    final res = _hasDuplicate();
    if (res is Failure) {
      return res;
    }

    return await synchronized(() {});
  }

  Future<Result<void>> deleteHard(Music m) async {
    List<Music> backup = list.toList();

    list.remove(m);

    return await synchronized(() => list = backup);
  }

  Future<Result<void>> reorder(int oldIndex, int newIndex) async {
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    return await Playlist().synchronized(() {
      final item = list.removeAt(newIndex);
      list.insert(oldIndex, item);
    });
  }

  Future<Result<void>> synchronized(void Function() revert) async {
    var res = await _write(list);
    if (res is Failure) {
      revert();
    }

    notifyListeners();

    return res;
  }

  Result<void> _hasDuplicate() {
    // 因为要使用id('bv'+'page')作为Music.key，用在listView等场景，
    // 所以每次编辑时检查有没有重复项
    final idSet = list.map((e) => e.id).toSet();
    return idSet.length == list.length
        ? Success(data: null)
        : Failure(err: "Has Duplicated Item(s)");
  }
}

Future<Result<void>> _write(List<Music> l) async {
  String fileStr = "";
  try {
    fileStr = jsonEncode(l);
  } catch (e) {
    return Failure(err: e.toString());
  }

  return _rename(playlistFileName, fileStr);
}

Future<Result<void>> _rename(String fileName, String data) async {
  final Directory? directory = await getExternalStorageDirectory();
  if (directory == null) {
    return Failure(err: "Get External Storage Failed");
  }

  try {
    final tempFile = File("${directory.path}/$fileName.temp");
    if (!await tempFile.exists()) {
      await tempFile.create(recursive: true);
    }

    await tempFile.writeAsString(data);
    await tempFile.rename("${directory.path}/$fileName");

    return Success(data: null);
  } catch (e) {
    return Failure(err: e.toString());
  }
}

Future<Result<File>> _openFile(String fileName) async {
  final Directory? directory = await getExternalStorageDirectory();
  if (directory == null) {
    return Failure(err: "Get External Storage Failed");
  }

  final file = File("${directory.path}/$fileName");
  if (!await file.exists()) {
    await file.create(recursive: true);
  }

  return Success(data: file);
}
