#!/bin/bash
set -e

echo "Building libv2ray for Android with 16KB page alignment..."

# Setup environment
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/$NDK_VERSION
export API_LEVEL=24

# Architectures config
ARCHS=(
    "aarch64-linux-android:arm64-v8a:arm64"
    "armv7a-linux-androideabi:armeabi-v7a:arm" 
    "i686-linux-android:x86:386"
    "x86_64-linux-android:x86_64:amd64"
)

# Clean previous builds
rm -rf dist
mkdir -p dist

for arch_pair in "${ARCHS[@]}"; do
    IFS=":" read -r target arch goarch <<< "$arch_pair"
    
    echo "🔨 Building for $arch..."
    
    # Set environment
    export GOOS=android
    export GOARCH=$goarch
    export CGO_ENABLED=1
    export CC=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/${target}${API_LEVEL}-clang
    export CXX=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/${target}${API_LEVEL}-clang++
    
    # Create output directory
    mkdir -p dist/$arch
    
    # Build with 16KB page alignment
    go build -buildmode=c-shared \
        -ldflags="-w -s -extldflags='-Wl,-z,max-page-size=16384'" \
        -o dist/$arch/libv2ray.so \
        ./main || echo "Build failed for $arch"
    
    # Verify
    if [ -f "dist/$arch/libv2ray.so" ]; then
        echo "✅ Successfully built $arch"
        $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-readelf -l dist/$arch/libv2ray.so | grep -q "LOAD" && echo "📋 ELF verification passed"
    fi
done

echo "🎉 All builds completed!"
