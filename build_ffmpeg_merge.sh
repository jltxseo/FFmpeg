#!/usr/bin/env bash

ARCH=$1
source config.sh $ARCH

PLATFORM=$ANDROID_NDK_ROOT/platforms/$AOSP_API/$AOSP_ARCH
TOOLCHAIN=$ANDROID_NDK_ROOT/toolchains/$TOOLCHAIN_BASE-$AOSP_TOOLCHAIN_SUFFIX/prebuilt/linux-x86_64
#android-ndk-r16b之前版本的头文件位于{NDK_HOME}/platforms/{android-21}/{arch-arm}/usr/include，
# r16b及之后的版本头文件位于{NDK_HOME}/sysroot/usr/include
ISYSROOT=$ANDROID_NDK_ROOT/sysroot
ASM=$ISYSROOT/usr/include/$TOOLCHAIN_BASE

PREFIX=$(pwd)/android/single/libs/$AOSP_ABI

echo "start build ffmpeg"
echo "PLATFORM="$PLATFORM
echo "TOOLCHAIN="$TOOLCHAIN
echo "ISYSROOT="$ISYSROOT
echo "ASM="$ASM
echo "PREFIX="$PREFIX

rm ./config.h

./configure \
--target-os=linux \
--prefix=$PREFIX \
--enable-cross-compile \
--disable-shared \
--enable-static \
--disable-doc \
--disable-ffmpeg \
--disable-ffplay \
--disable-ffprobe \
--disable-avdevice \
--disable-postproc \
--disable-doc \
--disable-symver \
--cc=$TOOLCHAIN/bin/$TOOLNAME_BASE-gcc \
--cross-prefix=$TOOLCHAIN/bin/$TOOLNAME_BASE- \
--disable-runtime-cpudetect \
--arch=$AOSP_ABI \
--disable-asm \
--sysroot=$PLATFORM \
--nm=$TOOLCHAIN/bin/$TOOLNAME_BASE-nm \
--extra-cflags="-I$ASM -isysroot $ISYSROOT -D__ANDROID_API__=$API -U_FILE_OFFSET_BITS -fPIC -DANDROID -Wfatal-errors -Wno-deprecated $FF_EXTRA_CFLAGS  $FF_CFLAGS" \
--extra-ldflags="-L${PLATFORM}/usr/lib" \
$ADDITIONAL_CONFIGURE_FLAG

echo "-I$ASM -isysroot $ISYSROOT -D__ANDROID_API__=$API -U_FILE_OFFSET_BITS $FF_EXTRA_CFLAGS  $FF_CFLAGS"

make clean

make -j16
make install
#合并
$TOOLCHAIN/bin/$TOOLNAME_BASE-ld \
    -rpath-link=$PLATFORM/usr/lib \
    -L$PLATFORM/usr/lib \
    -L$PREFIX/lib \
    -soname libffmpeg.so -shared -nostdlib -Bsymbolic --whole-archive --no-undefined -o \
    $PREFIX/libffmpeg.so \
    libavcodec/libavcodec.a \
    libavfilter/libavfilter.a \
    libswresample/libswresample.a \
    libavformat/libavformat.a \
    libavutil/libavutil.a \
    libswscale/libswscale.a \
    -lc -lm -lz -ldl -llog --dynamic-linker=/system/bin/linker $TOOLCHAIN/lib/gcc/$TOOLNAME_BASE/4.9.x/libgcc.a

        # strip 精简文件
    $TOOLCHAIN/bin/$TOOLCHAIN_BASE-strip  $PREFIX/libffmpeg.so

echo "end build ffmpeg"