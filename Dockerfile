# Based on https://github.com/cardoe/docker-yocto and
# https://github.com/kylemanna/docker-aosp

FROM phusion/baseimage:0.9.22

MAINTAINER Will Abele <will.abele@starlab.io>

# We don't have an interactive prompt don't fail
ENV DEBIAN_FRONTEND noninteractive

# Use baseimage-docker's init
# https://blog.phusion.nl/2015/01/20/docker-and-the-pid-1-zombie-reaping-problem/
ENTRYPOINT ["/sbin/my_init", "--"]

# Where we build
RUN mkdir -p /var/build
WORKDIR /var/build
# workaround HOME ignore. see https://github.com/phusion/baseimage-docker/issues/119
RUN echo /var/build > /etc/container_environment/HOME

# utilize my_init from the baseimage to create the user for us
# the reason this is dynamic is so that the caller of the container
# gets the UID:GID they need/want made for them
RUN mkdir -p /etc/my_init.d
ADD create-user.sh /etc/my_init.d/create-user.sh

RUN echo "dash dash/sh boolean false" | debconf-set-selections && \
dpkg-reconfigure -p critical dash

# ensure our rebuilds remain stable
ENV APT_GET_UPDATE 2017-12-22

RUN apt-get --quiet --yes update && \
    apt-get --quiet --yes install gawk wget git-core diffstat unzip \
    texinfo gcc-multilib build-essential chrpath socat cpio python \
    python3-pip python3-pexpect xz-utils debianutils iputils-ping \
    libsdl1.2-dev xterm sudo curl libssl-dev tmux strace ltrace \
    openjdk-8-jdk git-core gnupg flex bison gperf build-essential \
    zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 \
    lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z-dev ccache \
    libgl1-mesa-dev libxml2-utils xsltproc unzip cmake \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN cd /opt && wget --quiet \
    https://dl.google.com/android/repository/android-ndk-r16b-linux-x86_64.zip\
    && unzip android-ndk-r16b-linux-x86_64.zip \
    && mv android-ndk-r16b ndk \
    && rm android-ndk-r16b-linux-x86_64.zip \
    && /opt/ndk/build/tools/make_standalone_toolchain.py --arch arm64 \
       --api 26 --install-dir /opt/android-toolchain
