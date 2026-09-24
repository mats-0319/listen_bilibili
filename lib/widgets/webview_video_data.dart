String jsScript(double volume) =>
    '''
      // js: 自动播放 + 设置音量 + 播完通知
      (() => {
        if (window.__flutterBiliWatcherInstalled) {
          return;
        }

        window.__flutterBiliWatcherInstalled = true;

        let video = null; // 提取出来，方便后续扩展更多功能，例如暂停/继续播放等
        
        var attempts = 0;
        var timer = setInterval(() => {
          if (attempts > 20) { // 最多尝试10秒
            clearInterval(timer);
            return;
          }
        
          const v = document.querySelector('video');
          if (!v || v === video) {
            return;
          }
          
          video = v

          video.volume = $volume; // 设置初始音量
          video.play().catch(() => {}); // 自动播放
          
          // 播放结束
          video.addEventListener('ended', () => {
            FlutterPlayer.postMessage(JSON.stringify({ event: 'ended' }));
          });
          
          clearInterval(timer);
        }, 500);

        // Dart -> JS
        window.flutterSetVolume = function(volume) { // 暂未调用
          volume = Number(volume);

          if (Number.isNaN(volume)) {
            return;
          }

          if (volume < 0) {
            volume = 0;
          } else if (volume > 1) {
            volume = 1;
          }

          if (video) {
            video.volume = volume;
            video.muted = volume === 0;
          }
        };
        
        window.flutterPause = function() {
          if (video) {
            video.pause();
          }
        };
        
        window.flutterPlay = function() {
          if (video) {
            video.play().catch(() => {});
          }
        };
      })();
    ''';
