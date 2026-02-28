import 'package:uuid/uuid.dart';

class Music {
  String id = Uuid().v4(); // uid
  String name = "";
  String bv = "";
  int page = 1; // 分p视频
  int volume = 0; // offset, valid range: [-80,20]

  Music(this.name, this.bv, this.page, this.volume);
  Music.empty();

  Music.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    name = json["name"];
    bv = json["bv"];
    page = json["page"];
    volume = json["volume"];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = <String, dynamic>{};
    data["id"] = id;
    data["name"] = name;
    data["bv"] = bv;
    data["page"] = page;
    data["volume"] = volume;

    return data;
  }
}
