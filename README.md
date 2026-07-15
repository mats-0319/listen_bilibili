# listen_bilibili

一个听歌软件，使用B站作为音源。

[flutter doc](https://docs.flutter.dev/install/quick)

## 计划开发内容

- 查看歌曲信息对话框：使用文字显示，而非禁用的input
- 播放模式：增加单曲循环模式
- 修改list：导出到系统公共文件目录，以及导入歌单文件
- 使用手册：介绍应用功能
- 技术文档：介绍程序实现

## flutter开发

根据官方文档下载flutter并创建项目

- `flutter clean`
- `flutter pub get`
- `flutter run --release` 以release模式运行

- `flutter build apk --split-per-abi`
- `flutter install --use-application-binary=build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
  需要开启开发者模式-usb调试-允许usb安装

- `adb shell getprop | grep cpu` 查看手机cpu架构（需要手机开启usb调试）
