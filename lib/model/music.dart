import 'package:uuid/uuid.dart';

class Music {
  String id = Uuid().v4(); // uid
  String name = "";
  String bv = "";
  int volume = 0; // offset

  Music(this.name, this.bv, this.volume);
  Music.empty();

  Music.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    name = json["name"];
    bv = json["bv"];
    volume = json["volume"];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = <String, dynamic>{};
    data["id"] = id;
    data["name"] = name;
    data["bv"] = bv;
    data["volume"] = volume;

    return data;
  }
}
