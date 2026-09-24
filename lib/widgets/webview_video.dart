import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:listen_b/model/music.dart';
import 'package:listen_b/model/playlist.dart';
import 'package:listen_b/widgets/webview_video_data.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class Video extends StatefulWidget {
  const Video({super.key});

  @override
  State<Video> createState() => VideoState();
}

class VideoState extends State<Video> with WidgetsBindingObserver {
  late final WebViewController _controller;
  bool _disposed = false;
  bool _stopFlag = false;
  bool _tickerEnabled = true;

  void play() => _loadVideo();

  Future<void> _pause() =>
      _controller.runJavaScript("window.flutterPause?.();");

  Future<void> _resume() =>
      _controller.runJavaScript("window.flutterPlay?.();");

  // 彻底释放：把页面换成空白页，浏览器会停止 media session 并释放解码器。
  // 比单纯 pause 更彻底，且不受 JS 执行时机影响。
  Future<void> _stop() async {
    if (_stopFlag) {
      return;
    }

    _stopFlag = true;

    try {
      await _pause();
      await _controller.loadRequest(Uri.parse("about:blank"));
    } catch (_) {
      // 释放资源尽力尝试即可
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = WebViewController();
    _controller.setJavaScriptMode(JavaScriptMode.unrestricted);

    // android config
    final p = _controller.platform;
    if (p is AndroidWebViewController) {
      p.setMediaPlaybackRequiresUserGesture(false); // 不需要手势自动播放
    }

    // js -> dart
    _controller.addJavaScriptChannel(
      "FlutterPlayer",
      onMessageReceived: (JavaScriptMessage message) {
        final data = jsonDecode(message.message);

        if (data["event"] == "ended") {
          Playlist().next(); // todo: res check
          _loadVideo();
        }
      },
    );

    // dart -> js
    _controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (url) {
          if (_disposed) return; // 防止销毁阶段的调用触发脚本
          final volume = _calcVolume(Playlist().currentMusic().volume);
          // js: 自动播放 + 设置音量 + 播完通知
          _controller.runJavaScript(jsScript(volume));
        },
      ),
    );

    _loadVideo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 被别的页面覆盖时 TickerMode 会被关闭 -> 立刻停播
    final enabled = TickerMode.valuesOf(context).enabled;
    if (enabled == _tickerEnabled) return;
    _tickerEnabled = enabled;
    _tickerEnabled ? _resume() : _pause(); // 回到首页时继续播放，离开时暂停
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 退到后台也停
    switch (state) {
      case AppLifecycleState.inactive: // empty case falls through
      case AppLifecycleState.paused:
        _pause();
      case AppLifecycleState.resumed:
        if (_tickerEnabled) _resume();
      default:
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_stop());
    super.dispose();
  }

  void _loadVideo() {
    final Music m = Playlist().currentMusic();
    final url = _newVideoUrl(m.bv, m.page);

    _controller.loadRequest(url);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: WebViewWidget(controller: _controller),
    );
  }
}

Uri _newVideoUrl(String bv, int page) =>
    Uri.https("player.bilibili.com", "/player.html", {
      "bvid": bv,
      "p": "$page",
      "autoplay": "1",
      "muted": "0",
      "danmaku": "0", // 没效果
    });

double _calcVolume(int volumeOffset) {
  double volume = 0.8 + volumeOffset / 100.0;

  if (volume < 0.0) {
    volume = 0.0;
  } else if (volume > 1.0) {
    volume = 1.0;
  }

  return volume;
}
