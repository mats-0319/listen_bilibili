import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:listen_b/dart/global.dart';
import 'package:listen_b/dart/result.dart';
import 'package:listen_b/model/music.dart';
import 'package:listen_b/model/playlist.dart';
import 'package:listen_b/widgets/webview_video_data.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class Video extends StatefulWidget {
  const Video({super.key, required this.music});

  final Music? music; // 应该播放的歌曲，为空表示停止播放

  @override
  State<Video> createState() => VideoState();
}

class VideoState extends State<Video> with WidgetsBindingObserver {
  late final WebViewController _controller;
  bool _disposed = false;
  bool _tickerEnabled = true;

  String? _loadedID;

  Future<void> _pause() => _runJS("window.flutterPause?.();");

  Future<void> _resume() => _runJS("window.flutterPlay?.();");

  @override
  void didUpdateWidget(covariant Video oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.music?.id == widget.music?.id) return;
    _handleMusic();
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
          final res = Playlist().next();
          if (res is Failure) setError(res.err);
        }
      },
    );

    // dart -> js
    _controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (url) {
          if (_disposed) return; // 防止销毁阶段的调用触发脚本

          final m = Playlist().currentItem;
          if (m == null) return;

          _runJS(jsScript(_calcVolume(m.volume)));
        },
      ),
    );

    _handleMusic();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 被别的页面覆盖时 TickerMode 会被关闭 -> 立刻停播
    final enabled = TickerMode.valuesOf(context).enabled;
    if (enabled == _tickerEnabled) return;
    _tickerEnabled = enabled;
    if (_tickerEnabled) {
      _handleMusic();
      _resume(); // 回到首页时继续播放
    } else {
      _pause(); // 离开时暂停
    }
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
    unawaited(_release());
    super.dispose();
  }

  Future<void> _handleMusic() async {
    if (_disposed) return;

    final m = widget.music;

    if (_loadedID == m?.id) return; // 重复请求
    if (m == null) {
      await _release();
      return;
    }

    if (!_tickerEnabled) return;

    _loadedID = m.id;
    _controller.loadRequest(_newVideoUrl(m.bv, m.page));

    return;
  }

  Future<void> _release() async {
    try {
      await _pause();
      await _controller.loadRequest(Uri.parse("about:blank"));
    } catch (_) {}
  }

  Future<void> _runJS(String script) async {
    if (_disposed) return;

    try {
      await _controller.runJavaScript(script);
    } catch (_) {}
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
