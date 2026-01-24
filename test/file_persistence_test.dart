import "package:listen_b/model/music.dart";
import "package:listen_b/model/music_list.dart";
import "package:test/test.dart";

void main() {
  test("Test file persistence.", () async {
    List<Music> listIns = [];
    listIns.add(Music("music name 1", "url 1", 1, 0));
    listIns.add(Music("music name 2", "url 2", 1, 0));

    await write(listIns, true);

    listIns = [];
    expect(listIns.length, 0);
    listIns = await read(true);
    expect(listIns.length, 2);
  });
}
