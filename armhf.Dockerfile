FROM multiarch/debian-debootstrap:armhf-buster
#定义环境变量

# 安装编译libtorrent-rasterbar环境
RUN apt -y update \
&&  apt -y install build-essential zlib1g-dev pkg-config automake libtool libboost-dev libboost-system-dev libboost-chrono-dev libboost-random-dev libssl-dev libgeoip-dev qtbase5-dev qttools5-dev-tools libqt5svg5-dev  \
&&  apt -y install ruby ruby-dev rubygems build-essential apt-transport-https ca-certificates wget \
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
