import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:listen_b/model/music_list.dart';
import 'package:listen_b/model/music.dart';

class BiliPlayer extends StatefulWidget {
  final Music musicIns;

  const BiliPlayer({super.key, required this.musicIns});

  @override
  State<BiliPlayer> createState() => _BiliPlayerState();
}

class _BiliPlayerState extends State<BiliPlayer> {
  InAppWebViewController? webViewController;

  void playNewVideo(Music musicIns) {
    if (webViewController != null) {
      webViewController!.loadUrl(urlRequest: genUrlRequest(musicIns));
    }
  }

  @override
  Widget build(BuildContext context) {
    playNewVideo(widget.musicIns);

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: InAppWebView(
            initialUrlRequest: genUrlRequest(widget.musicIns),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              mediaPlaybackRequiresUserGesture: false, // 允许非手势播放
              allowsInlineMediaPlayback: true,
              userAgent: pcUserAgent, // 伪装成 PC 端浏览器，PC 版播放器限制较少
            ),
            onWebViewCreated: (controller) {
              controller.addJavaScriptHandler(
                handlerName: 'onVideoEnd',
                callback: (args) {
                  MusicList().nextMusic();
                },
              );

              webViewController = controller;
            },
            onLoadStop: (controller, url) async {
              double volume = calcVolume();
              // 页面加载完成后，注入 JS 脚本自动播放
              // 这里循环检测视频元素，直到播放成功
              await controller.evaluateJavascript(
                source:
                    """
                  (function() {
                    var checkExist = setInterval(function() {
                       var video = document.querySelector('video');
                       if (video) {
                          video.muted = false; // 尝试取消静音
                          video.volume = $volume
                          video.play();
                          // 尝试点击 B 站自带的巨大播放按钮
                          var btn = document.querySelector('.bilibili-player-video-wrap');
                          if(btn) btn.click();
                          
                          // 核心逻辑：监听播放结束
                          video.onended = function() {
                            window.flutter_inappwebview.callHandler('onVideoEnd');
                          };
                          
                          clearInterval(checkExist);
                       }
                    }, 500);
                  })();
                """,
              );
            },
          ),
        ),
      ],
    );
  }
}

URLRequest genUrlRequest(Music musicIns) {
  String bv = musicIns.bv;
  int page = musicIns.page;

  return URLRequest(
    url: WebUri(
      "https://player.bilibili.com/player.html?bvid=$bv&page=$page&autoplay=1&muted=0",
    ),
    headers: {
      'Referer': 'https://www.bilibili.com/',
    }, // 每次切换视频都必须带上这个 Header，否则会加载失败
  );
}

const pcUserAgent =
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

double calcVolume() {
  double volume = 0.8 + MusicList().currentMusic().volume / 100.0;

  if (volume < 0.0) {
    volume = 0.0;
  } else if (volume > 1.0) {
    volume = 1.0;
  }

  return volume;
}
