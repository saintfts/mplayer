build-linux version:
    echo "Building for linux..."
    flutter build linux --release
    tar -cvf ../builds_mplayer/2026-02-28/mplayer-linux-{{version}}.tar -C ./build/linux/x64/release/bundle/  .
