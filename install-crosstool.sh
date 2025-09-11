#!/bin/bash -e
CROSSTOOL_SRC=https://github.com/crosstool-ng/crosstool-ng/releases/download/crosstool-ng-1.27.0/crosstool-ng-1.27.0.tar.xz

WORKDIR=$(mktemp -d)
cleanup() {
  echo "Cleaning up..."
  rm -rf "$WORKDIR"
}
trap cleanup EXIT

cd "$WORKDIR"
curl -sL "$CROSSTOOL_SRC" | tar -xJ --strip-components=1
./configure "$@"
make
make install
