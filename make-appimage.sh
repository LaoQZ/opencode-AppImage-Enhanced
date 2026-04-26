#!/bin/sh

set -eu

ARCH=$(uname -m)
export ARCH
export OUTPATH=./dist
export ADD_HOOKS="self-updater.bg.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export DEPLOY_OPENGL=1


mkdir -p ./AppDir/bin/
tar -xvf /tmp/tmp.tar.gz  -C ./AppDir/bin/
mv ./AppDir/bin/opencode ./AppDir/bin/opencode-cli
chmod +x ./AppDir/bin/opencode-cli
cp -v ./opencode-cli.desktop ./AppDir
cp -v ./opencode-cli.png ./AppDir

# Deploy dependencies
quick-sharun \
	./AppDir/bin/*          \
	/usr/lib/libnss_nis.so* \
	/usr/lib/libnsl.so*     \
	/usr/lib/libnss_mdns*_minimal.so*

tar -xvf /tmp/tmp.tar.gz  -C ./AppDir/bin/
mv ./AppDir/bin/opencode ./AppDir/bin/opencode-cli
chmod +x ./AppDir/bin/opencode-cli

# Turn AppDir into AppImage
quick-sharun --make-appimage
