# 代码评审：问题清单与优化方向

评审范围：`lib/`（1174 行，16 个文件）、`android/` 配置、`test/`、`doc/`、工程与版本管理。
评审依据：源码通读 + `provider 6.1.5+1` / `Flutter 3.47.2` SDK 源码交叉验证 + 已构建 APK 的 manifest 合并报告。

---

## 一、结论概览

工程整体是「WebView 承载 B 站外链播放器 + 单一 `ChangeNotifier` 歌单状态」的小型单页应用，分层意图清晰（`model` / `pages` / `widgets` / `dart`），`Result` 密封类、主题语义约定、`README` 里的环境管理经验都是很好的基础。

但当前存在 **1 个必修的发布阻断缺陷**、**若干必然触发的状态一致性缺陷**，以及较明显的**分层缺失与测试空白**。下面按优先级排列，每条都标注了文件与行号，可直接定位修改。

| 级别 | 数量 | 说明 |
| --- | --- | --- |
| P0 | 3 | release 包功能不可用；状态变更后 UI 与落盘不一致；错误状态无法恢复 |
| P1 | 6 | 单例被 dispose、GlobalKey 建在 build 内、越界/异步安全、写盘非原子等 |
| P2 | 11 | 分层、常量、硬编码、WebView 生命周期、可变状态外泄、可访问性 |
| P3 | 5 | 工程卫生、文档、i18n、测试 |

---

## 二、P0：必修缺陷

### 1. release APK 缺少 `INTERNET` 权限，WebView 无法加载任何页面

- 位置：`android/app/src/main/AndroidManifest.xml`（`<manifest>` 内无 `<uses-permission>`）

已通过构建产物的合并报告确认：`INTERNET` 权限**仅来自** `android/app/src/debug/AndroidManifest.xml:6`，该文件不会参与 release 构建。

```
build/app/intermediates/manifest_merge_blame_file/debug/processDebugMainManifest/manifest-merger-blame-debug-report.txt
  -->/home/dev0319/document/code/listen_bilibili/android/app/src/debug/AndroidManifest.xml:6:5-66
```

也就是说：`flutter run`（debug）一切正常，一旦 `flutter build apk --split-per-abi` 出包，`WebViewController.loadRequest` 将直接失败，App 退化成「只有歌单列表、播放不出声」。

修复：在 main manifest 中显式声明

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### 2. 状态变更后（落盘失败回滚时）不通知 UI，内存与磁盘不一致

- 位置：`lib/model/playlist.dart:111-121`

```dart
Future<Result<void>> synchronized(void Function() revert) async {
  var res = await write(list);
  switch (res) {
    case Success():
      notifyListeners();
    case Failure():
      revert();          // 回滚了内存，但没有 notifyListeners()
  }
  return res;
}
```

调用方 `playlist_manage.dart:37` 的排序流程已经先改了 `dataState.list`，如果 `write` 失败，`revert()` 把内存改回去了，但**没有任何通知**，界面仍显示新顺序，而磁盘是旧顺序——用户下次启动才发现「我的排序丢了」。

同类问题：`create()`（`playlist.dart:76-84`）检测到重复时 `return Failure`，而第 78 行的 `list.insert(0, m)` **已经执行且没有回滚**，同样不通知 UI。

修复：`Failure` 分支也 `notifyListeners()`；或把变更-回滚-通知统一收敛到一处（见第 18 条与第 10 条的分层建议）。

### 3. `err` 全局错误状态设置后永不复位，首页会永久卡在错误页

- 位置：`lib/model/playlist.dart:19,48`、`lib/pages/home.dart:25-26`

```dart
// playlist.dart:24 只在 initialize() 开头清空一次
err = "";
...
// playlist.dart:48 异常时写入
err = e.toString();
// home.dart:25 只要有值就整页替换成一行红字
child: dataState.err.isNotEmpty ? Text(dataState.err) : Column(...)
```

`err` 只在 `initialize()` 开头被清空。一旦初始化失败（比如歌单文件被手改成非法 JSON、或存在重复项），首页永远是那行英文错误文本，**用户在任何界面都没有恢复入口**——而错误信息恰恰是「Has Duplicated Item(s)」这种需要用户去改文件的场景（设计文档也确认歌单只能改文件后重启）。

修复：错误改为一次性事件/落地到可操作的错误页，提供「重置为默认歌单」「复制文件路径」等按钮。

---

## 三、P1：高优先级问题

### 4. `Playlist` 单例被 `ChangeNotifierProvider` dispose，热重载即崩

- 位置：`lib/model/playlist.dart:11-15`、`lib/main.dart:9,19`

```dart
static final Playlist _instance = Playlist._privateInit();
factory Playlist() => _instance;              // 全局单例
```

`main.dart:18-19` 用 `ChangeNotifierProvider(create: (context) => Playlist())`，而 `create` 返回的对象**由 Provider 负责 dispose**（已在 `provider-6.1.5+1/lib/src/change_notifier_provider.dart:113,132-133` 确认：`dispose: _dispose` → `notifier?.dispose()`）。

结果：Provider 卸载（热重载、整体重建）时调用 `_instance.dispose()`，之后任何 `Playlist().create(...)` / `notifyListeners()` 都会抛 `A ChangeNotifier was used after being disposed`，且**不可恢复**（单例已死，永远返回同一个已销毁实例）。

顺带一提，`main.dart:9` 与 `main.dart:19` 是在同一个单例上操作，Provider 在这里除了「被 watch」没有任何实际作用，属于「引入了状态管理库但没真正用上」。

修复：二选一——去掉单例、改由 Provider 持有唯一实例（推荐）；或改用 `ChangeNotifierProvider.value(value: Playlist())` 明确不由 Provider 管理生命周期。

### 5. `GlobalKey` 建在 `build` 方法内，WebView 会被反复重建

- 位置：`lib/pages/home.dart:20`

```dart
Widget build(BuildContext context) {
  final videoKey = GlobalKey<VideoState>();   // 每次 build 都是新 key
  ...
  Video(key: videoKey),
```

`build` 每次执行都新建 `GlobalKey`，Flutter 会认为「旧 key 的子树消失、新 key 的子树出现」，从而销毁并重建 `VideoState`——WebView 重新创建、`loadRequest` 重新发起、视频从头开始。`Playlist.notifyListeners()` 每次播放/切歌都会触发 build，因此这是必现问题。

修复：提升为 `State` 字段（`final _videoKey = GlobalKey<VideoState>();`）。

### 6. `Video` 不监听歌单，存在索引越界与「视频/音频不同步」风险

- 位置：`lib/widgets/webview_video.dart:20-22,44-45,54,64-69`

几个相互关联的问题：

1. `VideoState` 完全不监听 `Playlist`。切歌**只能**靠 `home.dart:70` 手动 `videoKey.currentState?.play()`；一旦有别的入口调用 `Playlist().play(index)`（例如后续把「播放」按钮搬到别处），WebView 不会跟着切，界面显示「当前播放 A」而实际在播 B。
2. `play()` 无任何返回值/状态检查，`currentState` 为 null 时静默无操作。
3. `onPageFinished`（第 54 行）和 `_loadVideo()`（第 65 行）都直接取 `Playlist().currentMusic()`，而 `currentMusic()`（`playlist.dart:21`）是 `list[currentIndex]` 裸索引。`currentIndex` 初值为 `-1`，只要 `initialize()` 走了失败分支（第 47-50 行提前返回，**不会**调用 `next()`），而后续任何路径触发 `_loadVideo()`，就是 `RangeError`。
4. 设计文档「问题 1：视频暂停但音频正常播放，原因不明」很可能与此相关：`Video` 没有页面可见性/生命周期处理，**离开首页时（push 到「关于」页）WebView 不会被暂停**，音频会继续播；同时 `Video` 也没有 `pause`/`dispose` 逻辑，Android platform view 泄漏。

修复：`VideoState` 订阅 `Playlist`（`addListener`）并在 `didUpdateWidget`/`dispose` 中正确解绑；`currentMusic()` 改为返回 `Music?` 或 `Result<Music>`；离开页面时暂停播放并释放 resource。

### 7. 写盘非原子，且整表重写

- 位置：`lib/model/playlist.dart:131-140`

```dart
await file.writeAsString(fileStr);   // 直接覆盖目标文件
```

若写入过程中进程被杀（Android 后台回收极常见），`playlist.json` 会变成截断的半截 JSON。由于第 2、3 条缺陷，这会让 App 永久进入错误页且用户难以理解原因。

修复：写临时文件 + `rename` 原子替换；读取失败时保留 `.bak` 并回退默认歌单。

### 8. `openFile()` 在 `getExternalStorageDirectory()` 返回 null 时路径非法

- 位置：`lib/model/playlist.dart:142-150`

```dart
final directory = await getExternalStorageDirectory();
final file = File("${directory?.path}/playlist.json");   // null -> "null/playlist.json"
```

`directory` 为空时不会抛错，而是生成相对路径 `null/playlist.json`，`create` 大概率抛 `FileSystemException`，错误信息对用户毫无意义。应显式判空并给出明确失败原因；同时 `playlist.json` 用的是应用专属外部存储根目录，建议收进 `getApplicationDocumentsDirectory()` 或子目录，避免污染根目录。

修复：`if (directory == null) throw StateError('外部存储不可用')`。

### 9. `create()` 的插入/回滚位置硬编码为 0

- 位置：`lib/model/playlist.dart:76-84`

```dart
list.insert(0, m);
if (hasDuplicate()) return Failure(...);   // 未回滚
return await synchronized(() => list.removeAt(0));  // 写盘失败时移除的"必然是刚插的那首"仅因插入位置也是 0
```

「插入位置」与「回滚位置」是两处独立的字面量 `0`，只是碰巧一致。一旦把新歌改成追加到末尾（或支持排序后插入），回滚就会删掉**别人的**一首歌。应让 `create` 内部记住插入索引，或统一走「快照-变更-失败整体还原」的模式。

---

## 四、P2：架构与可维护性

### 10. `Playlist` 一个类承担了四种职责

`lib/model/playlist.dart` 同时是：领域模型（`List<Music>` + `currentIndex`）、持久化层（`write`/`openFile`/`jsonEncode`）、业务规则（重复检测）、UI 通知（`ChangeNotifier`）。这直接导致了第 2、3、7、9 条的耦合型缺陷。

建议拆为：`PlaylistRepository`（文件读写，返回 `Result`）→ `PlaylistStore`（业务规则 + 通知）→ UI。`write`/`openFile`（第 131-151 行）是顶层函数却只服务这个类，也应移入仓储层。

### 11. `Result` 只携带 `String err`，丢失异常类型与堆栈

- 位置：`lib/dart/result.dart:11-14`、`playlist.dart:48,138`

`err = e.toString()` 把 `FileSystemException`、`TypeError`、业务错误（"Empty Playlist"）压成同一个字符串，调用方无法区分「可重试的 IO 错误」和「用户输入非法」。当前 UI 也只是把字符串丢给 `AlertDialog`（`dialog_music_item_components.dart:89`）。

建议 `Failure` 携带 `Object error` + `StackTrace?`，或引入错误码枚举；`catch (e)` 改为 `catch (e, st)`。

### 12. `Result` 返回值几乎全部被忽略，契约形同虚设

全项目 3 处显式 `// todo: res check`（`home.dart:69`、`webview_video.dart:44`），以及：

- `playlist.dart:46` `next();` —— 返回值丢弃，初始化失败时静默
- `playlist.dart:37-39` `await synchronized(() {});` —— 写默认歌单失败无提示
- `playlist_manage.dart:155` `await Playlist().deleteHard(m);` —— 删除失败（含 IO 失败与「未找到」，`playlist.dart:102` 直接把「没找到」当 `Success`）无任何反馈

要么让 `Result` 强制被消费（analyzer 无法强制，需要 review 习惯或调用处 `switch`），要么对「不可恢复」错误直接抛异常。

### 13. 命令式导航 + 预构建页面实例

- 位置：`lib/widgets/new_page.dart:3`、`app_bar.dart:12`、`about.dart:28,66-69`

```dart
VoidCallback? newPage(BuildContext context, Widget page) => () => Navigator.of(context).push(...)
```

页面 Widget 在**按钮构建时**就被实例化并捕获进闭包（`PlaylistManagePage()`、`DocPage(doc: doc)`）。目前这些页面无状态所以没暴露问题，但这是隐性约束：一旦给它们加构造参数或希望「每次进入都是新实例」，行为会与直觉不符。另外没有路由表，`PageRouteBuilder` 动画手写在 `new_page.dart`，`VoidCallback?` 的返回类型也可为 non-null。

建议：改用 `MaterialApp.routes` / `onGenerateRoute`，传 `WidgetBuilder` 而非 `Widget`。

### 14. WebView 生命周期缺失

- 位置：`lib/widgets/webview_video.dart`（无 `dispose`、无 `WidgetsBindingObserver`）

`initState` 创建了 `WebViewController` 并注册 JS channel，但没有对称的释放；App 退到后台、页面被覆盖时都不会暂停播放。这与设计文档记录的「音频异常继续播放」现象一致，也是耗电与「退出后还有声音」的来源。

同时 `webview_video_data.dart:54` 的 `setInterval(findVideo, 500)` **永不清理**，配合第 44-51 行对整棵 DOM 的 `MutationObserver`，属于持续性能开销；`findVideo` 每 500ms 查询一次 `document.querySelector('video')`。

### 15. 硬编码与魔法值

| 位置 | 内容 |
| --- | --- |
| `about.dart:24` | `"v1.0.0"` 与 `pubspec.yaml` 的 `version: 1.0.0+1` 重复，无任何机制保证一致 |
| `home.dart:58` / `playlist_manage.dart:101` | 固定宽度 `200` / `180` 与 `Spacer` + 按钮并存，窄屏（≤360dp）下有 overflow 风险；应用 `Flexible`/`Expanded` |
| `webview_video.dart:73` | 播放器高度写死 `200` |
| `webview_video.dart:87` / `music.dart:5` | 基准音量 `0.8` 与 `[-80, 20]` 的取值范围分散在两处，语义未共享 |
| `about.dart:37` | 仓库地址硬编码在 UI 里 |

修复：版本号用 `package_info_plus`；维度用 `LayoutBuilder`/`MediaQuery`；业务常量集中到常量文件。

### 16. 主题角色命名与赋值语义不符

- 位置：`lib/theme.dart:6-7,28-36`

```dart
const Color _textColor = Colors.black;   // 主文字
...
primary: _textColor,                     // 把"文字色"喂给了 primary
```

顶部注释定义了清晰的角色语义（这点很好），但 `_textColor`/`_mutedTextColor` 这两个**用途命名**的常量被赋给 `primary`/`onSurfaceVariant` 这类**角色**字段，后续改主题时容易改错地方。另外 `onSurfaceVariant: Colors.grey` 在浅色卡片上对比度偏低（`#808080` on `#F0F0DC` ≈ 3.2:1，低于 4.5:1），输入框 label、版权文字的可读性受影响。

### 17. 输入校验缺失，错误输入被静默吞掉

- 位置：`lib/widgets/dialog_music_item.dart:72-82`

```dart
onChanged: (String v) => setState(() => mc.page = int.tryParse(v) ?? 1),
onChanged: (String v) => setState(() => mc.volume = int.tryParse(v) ?? 0),
```

清空输入框、输入 `abc`、输入 `-5` 都会静默变成 `1`/`0`，用户无从察觉；`bv` 字段没有任何格式校验（空串也能入库，`music.dart:2` 默认即 `""`），而 `bv` 是构造播放 URL 的唯一依据（`webview_video.dart:77-84`）。`volume` 超出 `[-80, 20]` 也被 `_calcVolume` 静默截断。

建议：表单校验 + `Form`/`TextFormField`，非法输入禁用确认按钮。</br>
顺带：`_nameInput`/`_bvInput`/`_pageInput`/`_volumeInput` 四个方法体结构完全一样（仅 label 与解析器不同），可参数化成一个方法，减少重复。

### 18. 状态变更方式混用

`playlist_manage.dart:31-40` 里 `setState` 包住了对共享 `Playlist.list` 的原地修改：

```dart
setState(() {
  final item = dataState.list.removeAt(oldIndex);   // 修改的是 Playlist 的内部状态
  dataState.list.insert(newIndex, item);
});
await Playlist().synchronized(...);
```

`onReorderItem` 回调里必须先改内存（否则拖拽结果无法反映到 `children`），所以这里的 `setState` 有其必要性；问题在于**同一份可变状态被两套机制驱动**：`Playlist.list` 既由 `notifyListeners` 驱动重建，又由调用方的 `setState` 驱动重建，且 `setState` 只包住了前半段（变更），后半段 `synchronized` 的失败回滚则依赖 `notifyListeners`（而它恰恰漏了，见 P0-2）。此外 `Playlist` 暴露 **可变 `public` 字段** `list`（`playlist.dart:17`），任何 widget 都能绕过业务规则直接改歌单——`hasDuplicate` 这道防线只在特定方法里检查，形同建议。建议改为 `List<Music> get list => List.unmodifiable(_list);` 并把变更入口收敛到 `Playlist` 内部方法（如 `Future<Result<void>> reorder(int oldIndex, int newIndex)`）。

### 19. 默认歌单是共享的可变全局列表

- 位置：`lib/model/default_playlist.dart:3`、`playlist.dart:38`

```dart
final List<Music> defaultPlaylist = [ Music(...), ... ];   // 顶层可变全局列表
...
list = defaultPlaylist;   // 直接把全局列表的引用赋给了 Playlist.list
```

`list = defaultPlaylist` 是引用赋值而非拷贝，于是「重置为默认歌单」后第一次排序/删除，实际改的就是那个全局常量。虽然目前只有重置路径会走到，但它使 `defaultPlaylist` 不再可复用（例如将来加「恢复默认」按钮会拿到被改过的数据）。建议改为 `List<Music> buildDefaultPlaylist() => [...]`（每次返回新列表）。

### 20. 其它细节

- `lib/pages/doc.dart:18`：`rootBundle.loadString` 放在 `build` 里创建 Future，每次重建都会重新发起加载。应放进 `State` 的 `initState` 或 `FutureBuilder` 外部缓存。
- `lib/pages/doc.dart:34`：`MarkdownWidget(data: snapshot.data)` 依赖 `snapshot.data` 的动态类型，可显式 `as String` 提升可读性。
- `lib/pages/home.dart:11`：`State<StatefulWidget>` 应写 `State<HomePage>`（`dialog_music_item.dart:23` 同样），虽然能编译，但丢失了 `widget` 的静态类型。
- `lib/widgets/dialog_music_item_components.dart:84`：用 `throw res.err`（抛 `String`）来跳出流程，再在 86 行 `catch` 回来——异常被当作控制流，丢失堆栈，语义绕。
- `lib/pages/about.dart:79-92`：`_ButtonToNewPage` 用 `ElevatedButton` 却套 `OutlinedButton.styleFrom`，样式来源与控件类型不一致。
- `lib/pages/about.dart:87`：`newPage(context, page)` 在 `build` 中直接调用并返回闭包，`VoidCallback?` 可空类型多余。
- `README.md:33`：安装命令的注意事项（不指定架构会装成示例代码）属于「已知坑」，建议同时写入 `doc/manual.md`，而 `doc/manual.md` 目前仅是「测试 md 格式文档的展示效果」的草稿，`doc/tech.md` 全文只有 `todo`（3 行），却已被 `pubspec.yaml:32-33` 打包进 App。
- 错误文案中英混杂："Has Duplicated Item(s)"、"Empty Playlist"、"Invalid Playlist Index" 与 UI 上的中文标签并存，且会直接展示给用户。
- `lib/model/playlist.dart:47`、`138`：`catch (e)` 未捕获堆栈（`catch (e, st)`），`e.toString()` 后又只留字符串，线上问题无法定位。
- `lib/theme.dart:78-97`：`TextTheme` 全部用绝对 `fontSize`（12–36）覆盖，未考虑 `MediaQuery.textScaler`；系统字号调大后 40px 页边距 + 200px 固定宽度的布局会更容易溢出。建议用 `textScaler` 或至少验证 1.3x/2.0x 字号下的表现。
- `lib/pages/home.dart:47`：列表项用 `ListTile` 作为容器却未使用 `onTap`/`leading`，内部又自绘 `Container`，`ListTile` 的点击波纹与水波区域实际覆盖不到内层卡片，建议直接换成 `InkWell` + `Padding`。

---

## 五、P3：工程卫生与测试

### 21. 测试目录为空，`pubspec.yaml` 仍声明 `flutter_test`

```
$ ls test/
（空）   # git status 显示 test/file_persistence_test.dart 已被删除
```

历史提交里曾有 `test/file_persistence_test.dart`，恰好覆盖的是**文件持久化**——也就是本文档 P0/P1 缺陷最集中的模块。建议优先补回：

- `Playlist` 的增删改查 + 重复检测 + 写盘失败回滚（可用 `path_provider` 的 mock 或注入目录路径）
- `Playlist.initialize()` 对「空文件 / 非法 JSON / 重复项」三种输入的行为
- `_calcVolume` 的边界（`-80`、`20`、越界）
- Widget 测试：首页错误态、歌单管理的排序与删除

要可测，第 10 条的仓储层拆分是前提（当前 `openFile()` 直接调用 `getExternalStorageDirectory()`，无法在测试中替换）。

### 22. 大量工作区改动未提交

```
$ git status --short | wc -l   # 数十项
?? lib/dart/  ?? lib/model/playlist.dart  ?? lib/pages/about.dart ...
 D lib/widgets/video.dart  → RM lib/widgets/webview_video.dart
 D test/file_persistence_test.dart
 M pubspec.yaml  M android/app/build.gradle.kts  M AndroidManifest.xml ...
```

`lib/` 下半数以上文件处于未跟踪状态（`?? token`），`doc/lb_design.png` 也未跟踪。当前仓库的「最新状态」只存在于工作区，一旦误操作（`git checkout .` / `git clean`）会直接丢失。建议按主题拆成若干次提交（重命名 `video.dart`→`webview_video.dart`、新增页面、Android 配置、文档）。

另外 `.gitignore` 处于已修改状态但内容看起来是标准模板，`build/` 与 `.dart_tool/` 均被正确忽略（`git ls-files | grep -c '^build/'` = 0），这点是好的。

### 23. 工程配置与平台

- `android/app/build.gradle.kts:43`：release 仍使用 debug 签名（模板默认），无法上架/分发，也容易误以为是正式包。
- `android/app/build.gradle.kts:14,26`：`applicationId = "com.mario.listen_bilibili"` 与 `namespace` 一致但 `TODO` 未处理；包名、`android:label="listen_bilibili"`（应用名带下划线），与 App 内展示的「ListenB」不一致。
- 仅支持 Android（无 `ios/`、`web/` 目录），符合设计文档的技术路线（依赖 Android WebView 特权），但建议在 README 明确「仅 Android」。
- `analysis_options.yaml` 仍是最小模板（`flutter_lints` 默认集），未启用 `strict-casts` / `strict-raw-types`，也没有 `avoid_print`、`prefer_const_constructors` 之外的额外约束；开启 `strict-casts` 能提前暴露 `jsonDecode` 结果的动态类型问题（见下条）。

### 24. JSON 反序列化未校验结构

- 位置：`lib/model/playlist.dart:32-34`

```dart
for (var item in jsonDecode(fileStr)) {   // 顶层不是 List 时抛 TypeError
  list.add(Music.fromJson(item));         // item 不是 Map 时抛 TypeError
}
```

`Music.fromJson`（`music.dart:20-25`）内部对字段做了 `as T?` + 默认值的防御，但**入口**没做任何结构校验。用户手改文件成 `{"a":1}` 就会得到 `type '_Map<String, dynamic>' is not a subtype of type 'Iterable<dynamic>'` 这种面向开发者的报错。

### 25. 性能相关的次要项

- `playlist.dart:111-121`：每次增删改都全量 `jsonEncode` + 写整个文件（当前 26 首规模无感，规模上千首时明显）。且所有文件 IO 都在主 isolate，`writeAsString` 会阻塞 UI 帧。
- `playlist.dart:123-128`：`hasDuplicate()` 每次 O(n) 建 Set，每次编辑都调用一次；单次开销可忽略，但可以用 `Set` 增量维护。
- `playlist_manage.dart:78-95`：`_displayMusicList` 每次 build 重建整个列表（`ReorderableListView` 一次性构建全部子项，非懒加载）。歌单长时建议改用 `ReorderableListView.builder`。
- `about.dart` / `home.dart`：多处 `SizedBox`、`EdgeInsets` 未加 `const`，可交给 `prefer_const_constructors` 自动修。

---

## 六、建议的推进顺序

**第 1 步（半天，解除阻断）**

1. `AndroidManifest.xml` 补 `INTERNET` 权限 —— 让 release 包真正可用（P0-1）
2. `home.dart:20` 的 `GlobalKey` 提升为 State 字段（P1-5）
3. `main.dart` 去掉单例、由 Provider 持有唯一实例（P1-4）

**第 2 步（1-2 天，修状态一致性）**

4. `synchronized` 的 `Failure` 分支补 `notifyListeners`，并把「快照-变更-失败还原」收敛到一处（P0-2、P1-9）
5. `err` 改为可恢复的错误态，首页提供「重置歌单」入口（P0-3）
6. 写盘改「临时文件 + rename」，读取失败回落备份（P1-7）
7. `openFile()` 判空 + 收紧到应用专属子目录（P1-8）

**第 3 步（2-3 天，补 WebView 生命周期与解耦）**

8. `VideoState` 订阅 `Playlist`，移除 `home.dart` 里的手动 `play()` 联动（P1-6）
9. 加 `WidgetsBindingObserver`，后台/离开页面暂停，`dispose` 释放 controller（P2-14）
10. 清理 `setInterval` / `MutationObserver`，`currentMusic()` 改为可空返回

**第 4 步（持续，提质量）**

11. 拆出 `PlaylistRepository`，让持久化可注入、可测（P2-10）
12. 补回 `test/`（持久化优先），CI 里跑 `flutter analyze` + `flutter test`（P3-21）
13. 按主题拆分并提交当前工作区改动（P3-22）
14. 收尾清理：`const`/硬编码/命名/表单校验/文档补全（P2-15~20、P3-23~25）

---

## 七、值得保留的做法

- `analysis_options.yaml` 排除 `build/**` 与 `android/**`，避免平台代码噪音。
- `theme.dart` 顶部明确写出「业务代码只认角色、不认具体颜色」的语义约定，这个约定本身很好，只需修正常量命名（P2-16）。
- `Result` 用 `sealed class` + 模式匹配（`switch (res) { case Success(): ... }`），方向正确，只是当前调用方没消费（P2-12）。
- `Music.fromJson` 对每个字段都做了空安全兜底与默认值。
- README 里「环境交给 flutter 统一管理，不单独升级某一环」的经验总结，对 Flutter 工程很有价值。
- `.gitignore` 覆盖完整，`build/` / `.dart_tool/` 未被误提交。
