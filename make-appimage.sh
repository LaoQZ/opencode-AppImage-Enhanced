#!/bin/sh

set -eu

ARCH=$(uname -m)
export ARCH
export OUTPATH=./dist
export ADD_HOOKS="self-updater.bg.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export DEPLOY_OPENGL=1

# 1. 准备必要的目录
mkdir -p ./AppDir/bin
mkdir -p ./AppDir/usr/lib
cp -v ./opencode-cli.desktop ./AppDir
cp -v ./opencode-cli.png ./AppDir





# ==========================================
# 2. 核心魔法：用诱饵骗取 glibc 依赖
# ==========================================
# 我们故意让 quick-sharun 去打包 /bin/pwd 这个毫无用处的系统命令。
# 它的目的仅仅是逼迫 quick-sharun 提取出全套的 glibc 和你需要的网络库！
quick-sharun \
	/bin/pwd \
	/usr/lib/libnss_nis.so* \
	/usr/lib/libnsl.so* \
	/usr/lib/libnss_mdns*_minimal.so*

# ==========================================
# 3. 保护核心：放入原味、无损的 Bun 二进制文件
# ==========================================
# 这时候库已经提取完了。我们把你编译好的、140MB 的程序放进 AppDir。
# ⚠️⚠️⚠️ 注意：请将下面的 ./dist/opencode-cli 替换为你 Action 实际编译产物的路径！

tar -xvf /tmp/tmp.tar.gz  -C ./AppDir/bin/
mv ./AppDir/bin/opencode ./AppDir/bin/opencode-cli
chmod +x ./AppDir/bin/opencode-cli


# ==========================================
# 4. 接管启动器：绕过系统 glibc 安全启动
# ==========================================
# 我们覆盖掉 quick-sharun 生成的错误启动文件，自己写一个最稳的 AppRun
cat > ./AppDir/AppRun << 'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"

# 找到 quick-sharun 提取出来的动态加载器 (ld-linux)
LOADER=$(find "${HERE}" -name "ld-linux-aarch64.so.1" | head -n 1)

# 定义 quick-sharun 存放库的目录
LIBS="${HERE}/lib:${HERE}/shared/lib"

if [ -n "$LOADER" ]; then
    # 【最安全的启动方式】
    # 用自带的加载器启动你的程序，不修改你的程序，也不依赖香橙派的 glibc！
    exec "$LOADER" --library-path "$LIBS" "${HERE}/bin/opencode-cli" "$@"
else
    # 兜底方案
    export LD_LIBRARY_PATH="${LIBS}:${LD_LIBRARY_PATH}"
    exec "${HERE}/bin/opencode-cli" "$@"
fi
EOF

chmod +x ./AppDir/AppRun

# ==========================================
# 5. 打包成 AppImage
# ==========================================
# 为了防止 quick-sharun --make-appimage 把我们写好的 AppRun 覆盖掉
# 我们直接下载最官方、最原生的 appimagetool 来完成最后一步打包
if [ ! -f ./appimagetool ]; then
    wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-$ARCH.AppImage -O appimagetool
    chmod +x appimagetool
fi

# 执行打包，输出到 dist 目录
./appimagetool ./AppDir $OUTPATH/opencode-cli-$ARCH.AppImage
