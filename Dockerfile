# This Dockerfile is used to build an headles vnc image based on Ubuntu
ARG UBUNTU_IMAGE=ubuntu:18.04
FROM $UBUNTU_IMAGE

LABEL io.k8s.description="Headless VNC Container with Xfce window manager, firefox and chromium" \
      io.k8s.display-name="Headless VNC Container based on Ubuntu" \
      io.openshift.expose-services="6901:http,5901:xvnc" \
      io.openshift.tags="vnc, ubuntu, xfce" \
      io.openshift.non-scalable=true

ARG UBUNTU_MIRROR
RUN if [ "x$UBUNTU_MIRROR" != "x" ]; then sed -i 's#http://archive.ubuntu.com/#http://'$UBUNTU_MIRROR'.archive.ubuntu.com/#' /etc/apt/sources.list; fi

### Envrionment config
ARG HOST_USER=default
ARG HOST_PASSWORD=ubuntu
ARG HOST_USER_UID=1000
ARG HOST_USER_GID=1000


ENV HOME=/headless \
    HOST_USER=$HOST_USER \
    HOST_USER_UID=$HOST_USER_UID \
    HOST_USER_GID=$HOST_USER_GID \
    TERM=xterm \
    STARTUPDIR=/dockerstartup \
    INST_SCRIPTS=$HOME/install \
    DEBIAN_FRONTEND=noninteractive 

WORKDIR $HOME

### Add all install scripts for further steps
ADD ./src/common/install/ $INST_SCRIPTS/
ADD ./src/ubuntu/install/ $INST_SCRIPTS/
RUN find $INST_SCRIPTS -name '*.sh' -exec chmod a+x {} +

### Install some common tools
RUN $INST_SCRIPTS/tools.sh
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

### Install custom fonts
# RUN $INST_SCRIPTS/install_custom_fonts.sh

### Install xvnc-server & noVNC - HTML5 based VNC viewer
## Connection ports for controlling the UI:
# VNC port:5901
# noVNC webport, connect via http://IP:6901/?password=vncpassword
ARG NOVNC_VERSION=1.0.0
ARG WEBSOCKIFY_VERSION=0.8.0
ARG TIGERVNC_VERSION=1.9.0

ENV DISPLAY=:1 \
    VNC_PORT=5901 \
    NO_VNC_PORT=6901 \
    NO_VNC_HOME=$HOME/noVNC \
    VNC_COL_DEPTH=24 \
    VNC_RESOLUTION=1280x1024 \
    VNC_PW=password \
    VNC_VIEW_ONLY=false \
    NOVNC_VERSION=$NOVNC_VERSION \
    WEBSOCKIFY_VERSION=$WEBSOCKIFY_VERSION \
    TIGERVNC_VERSION=$TIGERVNC_VERSION 


RUN $INST_SCRIPTS/tigervnc.sh
RUN $INST_SCRIPTS/no_vnc.sh

### Install xfce UI
RUN $INST_SCRIPTS/xfce_ui.sh
ADD ./src/common/xfce/ $HOME/

### Install firefox and chrome browser
# ARG FIREFOX_VERSION=63.0
# RUN $INST_SCRIPTS/firefox.sh $FIREFOX_VERSION
RUN $INST_SCRIPTS/chrome.sh

### configure startup
RUN $INST_SCRIPTS/libnss_wrapper.sh
ADD ./src/common/scripts $STARTUPDIR
RUN $INST_SCRIPTS/set_user_permission.sh $STARTUPDIR $HOME

#install Raven
ARG RAVEN_VERSION=2.1.3
RUN wget -qO- "https://github.com/RavenProject/Ravencoin/releases/download/v$RAVEN_VERSION/raven-$RAVEN_VERSION.0-x86_64-linux-gnu.tar.gz" \
    | tar xz --strip 1 -C /usr/local --strip-components=1 --no-same-owner

#install Paper Wallet
RUN wget -qO- "https://github.com/MSFTserver/Ravencoin-paperwallet/archive/1.0.tar.gz" \
    | tar xz --strip 1 --one-top-level=Paper-Wallet -C $HOME --strip-components=1 --no-same-owner


USER ${HOST_USER_UID:-1000}

EXPOSE $VNC_PORT $NO_VNC_PORT 8766 18766 8767 18770


ENTRYPOINT ["/dockerstartup/vnc_startup.sh"]
CMD ["--wait"]
