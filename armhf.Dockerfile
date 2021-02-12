FROM multiarch/debian-debootstrap:armhf-buster as builder
#定义环境变量
WORKDIR /opt

# 安装编译libtorrent-rasterbar环境
RUN apt -y update \
&&  apt -y install build-essential zlib1g-dev pkg-config automake libtool libboost-dev libboost-system-dev libboost-chrono-dev libboost-random-dev libssl-dev libgeoip-dev qtbase5-dev qttools5-dev-tools libqt5svg5-dev  \
&&  apt -y install ruby ruby-dev rubygems build-essential apt-transport-https ca-certificates wget git \
&&  gem sources --add http://mirrors.tuna.tsinghua.edu.cn/rubygems/ --remove https://rubygems.org/  \
&&  gem install fpm

# 编译libtorrent-rasterbar
RUN wget https://github.com/arvidn/libtorrent/releases/download/v1.2.12/libtorrent-rasterbar-1.2.12.tar.gz \
&&  tar -xzvf libtorrent-rasterbar-1.2.12.tar.gz \
&&  cd libtorrent-rasterbar-1.2.12/  \
&&  ./configure --enable-encryption --disable-debug CXXFLAGS="-std=c++17" --with-boost-libdir=/usr/lib/arm-linux-gnueabihf  \
&&  make -j$(nproc) \
&&  mkdir -p /tmp/libtorrent-rasterbar \
&&  make install DESTDIR=/tmp/libtorrent-rasterbar

## 创建libtorrent-rasterbar deb 安装包
RUN fpm -s dir -t deb \
    -C /tmp/libtorrent-rasterbar \
    -m "xixka <xka@live>" \
    --url "xixka.github.io" \
    --description "Development files for libtorrent-rasterbar" \
    --vendor "xixka" \
    -n libtorrent-rasterbar \
    -v 1.2.12 \
    -p libtorrent-rasterbar_1.2.12_armhf.deb \
    usr/local
#安装libtorrent-rasterbar
RUN cd /opt &&  dpkg -i libtorrent-rasterbar_1.2.12_armhf.deb

#构建qBittorrent
RUN wget https://github.com/c0re100/qBittorrent-Enhanced-Edition/archive/release-4.3.3.10.tar.gz \
&&  tar -xzvf release-4.3.3.10.tar.gz \
&&  cd qBittorrent-Enhanced-Edition-release-4.3.3.10/ \
&&  ./configure --prefix=/usr --disable-gui CXXFLAGS="-std=c++17"  --with-boost-libdir=/usr/lib/arm-linux-gnueabihf \
&&  make -j$(nproc)  \
&&  mkdir -p /tmp/qbittorrent-nox  \
&&  make install INSTALL_ROOT=/tmp/qbittorrent-nox

# 打包qBittorrent deb
RUN fpm -s dir -t deb \
    -C /tmp/qbittorrent-nox \
    -m "xixka <xka@live.com>" \
    --url "xixka.github.io" \
    --description "bittorrent client based on libtorrent-rasterbar (without X support)" \
    --vendor "xixka" \
    -n qbittorrent-nox \
    -v 4.3.3.10 \
    -p qbittorrent-enhanced-nox_4.3.3.10_armhf.deb \
    -d "libtorrent-rasterbar >= 1.2.12" \
    -d "zlib1g-dev >= 1:1.2.0" \
    -d "libstdc++6 >= 5.2" \
    -d "libqt5xml5 >= 5.2.0" \
    -d "libqt5network5 >= 5.9.0~beta" \
    -d "libqt5core5a >= 5.11.0~rc1" \
    -d "libboost-system1.67.0" \
    usr/

FROM debian:10
WORKDIR /opt
COPY --from=builder /opt/libtorrent-rasterbar_1.2.12_armhf.deb /opt/libtorrent-rasterbar_1.2.12_armhf.deb
COPY --from=builder /opt/qbittorrent-enhanced-nox_4.3.3.10_armhf.deb /opt/qbittorrent-enhanced-nox_4.3.3.10_armhf.deb
