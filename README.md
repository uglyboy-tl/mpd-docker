# mpd-docker

精简版 Music Player Daemon 镜像，约 19 MB。用官方 Alpine 包构建出来是 400 MB 上下。

## 为什么要自编译

Alpine 和 Debian 的 mpd 包都编译了 ffmpeg 解码器，依赖链是：

    mpd -> libavcodec/libavfilter/libavformat -> libplacebo -> vulkan -> mesa -> libLLVM.so (168 MB)

一个只听 mp3/flac 的播放器因此背上 400 MB 镜像。这里用源码编译，关掉 ffmpeg，只保留：

| 项 | 内容 |
|---|---|
| 输出 | alsa（另有 null / pipe） |
| 解码 | mad（mp3/mp2）、flac、vorbis（ogg）、sndfile（wav/aiff）、pcm |
| 标签 | id3tag |
| 数据库 | simple |

镜像里没有 DSD、opus、aac、wma、HTTP 流、SMB/NFS 等；需要的话改 Dockerfile 里的 meson 开关。

## 用法

    services:
      mpd:
        image: ghcr.io/uglyboy-tl/mpd:latest
        container_name: mpd
        restart: unless-stopped
        devices:
          - /dev/snd
        volumes:
          - ./mpd.conf:/etc/mpd.conf
          - mpd:/var/lib/mpd
          - /path/to/music:/music:ro
        ports:
          - 6600:6600

mpd.conf 最小示例：

    music_directory    "/music"
    playlist_directory "/var/lib/mpd/playlists"
    db_file            "/var/lib/mpd/database"
    state_file         "/var/lib/mpd/state"
    user               "root"
    bind_to_address    "0.0.0.0"
    port               "6600"
    audio_output {
      type          "alsa"
      name          "Alsa Device"
      device        "default"
      mixer_type    "hardware"
      mixer_device  "default"
      mixer_control "PCM"
    }

国内拉取：镜像名换成 ghcr.nju.edu.cn/uglyboy-tl/mpd:latest。

## 构建

GitHub Actions 在原生 arm64 / amd64 runner 上各构建一次，推到 ghcr.io。本地构建：

    docker build -t mpd:local .
    # 国内加速：--build-arg APK_MIRROR=mirrors.huaweicloud.com

mpd 版本由 Dockerfile 顶部的 MPD_VERSION 控制。4 核 ARM 上全量构建约 20 分钟。

## License

MIT
