class Music {
  String name = "";
  String bv = "";
  int page = 1; // 分p视频
  int volume = 0; // 音量修正，有效范围: [-80, 20]，超出范围的部分不予处理

  String get id => "$bv$page";

  Music(this.name, this.bv, [this.page = 1, this.volume = 0]);

  Music.empty();

  Music.deepCopy(Music m) {
    name = m.name;
    bv = m.bv;
    page = m.page;
    volume = m.volume;
  }

  Music.fromJson(Map<String, dynamic> json) {
    name = json["name"] as String? ?? "";
    bv = json["bv"] as String? ?? "";
    page = json["page"] as int? ?? 1;
    volume = json["volume"] as int? ?? 0;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      "name": name,
      "bv": bv,
      "page": page,
      "volume": volume,
    };
  }
}

void copyBack(Music origin, Music newIns) {
  origin.name = newIns.name;
  origin.bv = newIns.bv;
  origin.page = newIns.page;
  origin.volume = newIns.volume;
}
