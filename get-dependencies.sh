#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm patchelf libnss_nis nss-mdns nss

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano ffmpeg-mini

# Comment this out if you need an AUR package
# make-aur-package

echo "Getting binary..."
echo "---------------------------------------------------------------"
case "$ARCH" in
	x86_64)  farch=amd64;;
	aarch64) farch=arm64;;
esac
link=https://github.com/anomalyco/opencode/releases/latest/download/opencode-linux-$farch.tar.gz
if ! wget --retry-connrefused --tries=30 "$link" -O /tmp/tmp.tar.gz 2>/tmp/download.log; then
	cat /tmp/download.log
	exit 1
fi
mkdir -p ./AppDir/bin
tar -xvf /tmp/tmp.tar.gz  -C ./AppDir/bin/
mv ./AppDir/bin/opencode ./AppDir/bin/opencode-cli
rm -f /tmp/tmp.tar.gz

cp -v ./opencode-cli.desktop ./AppDir
cp -v ./opencode-cli.png ./AppDir

echo "---------------------------------------------------------------"
ls -lart ./AppDir/bin/
ls -lart ./AppDir

awk -F'/' '/Location:/{print $(NF-1); exit}' /tmp/download.log > ~/version
