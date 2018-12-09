#!/usr/bin/env bash
set -e

echo "Install TigerVNC server"
wget -qO- https://dl.bintray.com/tigervnc/stable/tigervnc-${TIGERVNC_VERSION}.x86_64.tar.gz | tar xz --strip 1 -C /
