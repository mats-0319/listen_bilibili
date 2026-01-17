# listen_bilibili

一个听歌软件，使用B站作为音源。

## 目录

- android：android配置
- assets：资源文件
- doc
- lib：
    - dart
    - model：数据结构
    - widgets：组件
    - `*.dart`文件：主要页面

## dev

`flutter build apk --split-per-abi`
`flutter install --use-application-binary=build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

查看手机cpu架构：（需要手机开启usb调试）
`adb shell getprop | grep cpu`

## 计划开发内容

- 修改list：导出到系统公共文件目录，以及导入歌单文件
- 使用手册：介绍应用功能
- 技术文档：介绍程序实现
