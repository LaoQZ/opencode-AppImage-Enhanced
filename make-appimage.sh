#!/bin/sh

set -eu

ARCH=$(uname -m)
export ARCH
export OUTPATH=./dist
export ADD_HOOKS="self-updater.bg.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export DEPLOY_OPENGL=1

# Deploy dependencies
quick-sharun \
	./AppDir/bin/*          \
	/usr/lib/libnss_nis.so* \
	/usr/lib/libnsl.so*     \
	/usr/lib/libnss_mdns*_minimal.so*

# Turn AppDir into AppImage
quick-sharun --make-appimage
