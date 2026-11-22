# syntax=docker/dockerfile:1
# 精简版 MPD：关掉 ffmpeg，只保留 alsa 输出 + mad/flac/vorbis/id3tag 解码。
# 上游 Alpine/Debian 的 mpd 包硬依赖 ffmpeg 全家，经 libplacebo -> vulkan -> mesa
# 拉进 libLLVM（约 168 MB），镜像因此常年 400 MB 上下。这里自编译后约 17 MB。
#
# 用法：docker build -t mpd:local .
# 国内构建可传 --build-arg APK_MIRROR=mirrors.huaweicloud.com

FROM alpine:3.24 AS build
ARG MPD_VERSION=0.24.4
ARG APK_MIRROR=dl-cdn.alpinelinux.org
RUN sed -i "s|dl-cdn.alpinelinux.org|$APK_MIRROR|g" /etc/apk/repositories \
 && apk add --no-cache build-base meson ninja pkgconf linux-headers \
      alsa-lib-dev libmad-dev flac-dev libvorbis-dev libogg-dev libid3tag-dev zlib-dev
RUN wget -q --timeout=60 https://www.musicpd.org/download/mpd/0.24/mpd-$MPD_VERSION.tar.xz -O /tmp/mpd.tar.xz \
 && tar -xf /tmp/mpd.tar.xz -C /tmp
WORKDIR /tmp/mpd-$MPD_VERSION
RUN meson setup build --buildtype=release -Db_lto=false -Dstrip=true -Dmanpages=false \
      -Dalsa=enabled -Dmad=enabled -Dflac=enabled -Dvorbis=enabled -Did3tag=enabled -Ddsd=true \
      -Dffmpeg=disabled -Dmpg123=disabled -Dopus=disabled -Dfaad=disabled -Dsndfile=disabled \
      -Dwavpack=disabled -Daudiofile=disabled -Dmpcdec=disabled -Dgme=disabled -Dmikmod=disabled \
      -Dmodplug=disabled -Dopenmpt=disabled -Dsidplay=disabled -Dadplug=disabled -Dwildmidi=disabled \
      -Dfluidsynth=disabled -Dchromaprint=disabled -Dzzip=disabled \
      -Dvorbisenc=disabled -Dlame=disabled -Dtwolame=disabled -Dshine=disabled -Dwave_encoder=false \
      -Dlibsamplerate=disabled -Dsoxr=disabled \
      -Dpulse=disabled -Dpipewire=disabled -Djack=disabled -Dao=disabled -Doss=disabled \
      -Dopenal=disabled -Dsndio=disabled -Dsnapcast=false -Dshout=disabled -Drecorder=false \
      -Dfifo=false -Dhttpd=false -Dsolaris_output=disabled \
      -Dcurl=disabled -Dwebdav=disabled -Dnfs=disabled -Dsmbclient=disabled -Dupnp=disabled \
      -Dudisks=disabled -Dqobuz=disabled -Dmms=disabled -Dcue=false -Dcdio_paranoia=disabled \
      -Dbzip2=disabled -Diso9660=disabled -Dsqlite=disabled -Ddbus=disabled -Dzeroconf=disabled \
      -Dicu=disabled -Dexpat=disabled -Dnlohmann_json=disabled -Dpcre=disabled -Dlibmpdclient=disabled \
 && ninja -C build && meson install -C build --destdir /stage

FROM alpine:3.24
ARG MPD_VERSION=0.24.4
ARG APK_MIRROR=dl-cdn.alpinelinux.org
LABEL org.opencontainers.image.title="mpd" \
      org.opencontainers.image.description="Minimal MPD: alsa output + mad/flac/vorbis/id3tag, no ffmpeg" \
      org.opencontainers.image.version="$MPD_VERSION" \
      org.opencontainers.image.source="https://github.com/uglyboy-tl/mpd-docker" \
      org.opencontainers.image.licenses="MIT"
RUN sed -i "s|dl-cdn.alpinelinux.org|$APK_MIRROR|g" /etc/apk/repositories \
 && apk add --no-cache alsa-lib libmad flac libvorbis libogg libid3tag zlib libstdc++
COPY --from=build /stage/usr/local/bin/mpd /usr/local/bin/mpd
RUN mkdir -p /var/lib/mpd /music && mpd --version | head -1
EXPOSE 6600
CMD ["/usr/local/bin/mpd", "--no-daemon", "--stdout", "/etc/mpd.conf"]
