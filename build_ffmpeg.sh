#!/usr/bin/env bash

ARCH=$1
source config.sh $ARCH

PLATFORM=$ANDROID_NDK_ROOT/platforms/$AOSP_API/$AOSP_ARCH
TOOLCHAIN=$ANDROID_NDK_ROOT/toolchains/$TOOLCHAIN_BASE-$AOSP_TOOLCHAIN_SUFFIX/prebuilt/linux-x86_64
#android-ndk-r16b之前版本的头文件位于{NDK_HOME}/platforms/{android-21}/{arch-arm}/usr/include，
# r16b及之后的版本头文件位于{NDK_HOME}/sysroot/usr/include
ISYSROOT=$ANDROID_NDK_ROOT/sysroot
ASM=$ISYSROOT/usr/include/$TOOLCHAIN_BASE

PREFIX=$(pwd)/android/$AOSP_ABI

echo "start build ffmpeg"
echo "PLATFORM="$PLATFORM
echo "TOOLCHAIN="$TOOLCHAIN
echo "ISYSROOT="$ISYSROOT
echo "ASM="$ASM
echo "PREFIX="$PREFIX

./configure \
--target-os=linux \
--prefix=$PREFIX \
--enable-cross-compile \
--enable-gpl \
--enable-shared \
--disable-static \
--disable-doc \
--disable-ffmpeg \
--disable-ffplay \
--disable-ffprobe \
--disable-avdevice \
--disable-postproc \
--disable-doc \
--disable-symver \
--enable-encoders \
--enable-nonfree \
--enable-muxers \
--enable-muxer=mov \
--enable-muxer=mp4 \
--enable-muxer=avi \
--disable-demuxers \
--enable-demuxer=image2 \
--enable-demuxer=aac \
--enable-demuxer=avi \
--enable-demuxer=mpc \
--enable-demuxer=mpegts \
--enable-demuxer=mov \
--enable-decoders \
--enable-decoder=aac \
--enable-decoder=aac_latm \
--enable-decoder=mpeg4 \
--enable-decoder=mjpeg \
--enable-decoder=png \
--disable-parsers \
--enable-parser=aac \
--enable-parser=ac3 \
--cc=$TOOLCHAIN/bin/$TOOLNAME_BASE-gcc \
--cross-prefix=$TOOLCHAIN/bin/$TOOLNAME_BASE- \
--disable-runtime-cpudetect \
-disable-stripping \
--disable-asm \
--arch=$AOSP_ABI \
--sysroot=$PLATFORM \
--nm=$TOOLCHAIN/bin/$TOOLNAME_BASE-nm \
--extra-cflags="-I$ASM -isysroot $ISYSROOT -D__ANDROID_API__=$API -U_FILE_OFFSET_BITS $FF_EXTRA_CFLAGS  $FF_CFLAGS" \
--extra-ldflags="$ADDI_LDFLAGS" \
$ADDITIONAL_CONFIGURE_FLAG

echo "-I$ASM -isysroot $ISYSROOT -D__ANDROID_API__=$API -U_FILE_OFFSET_BITS $FF_EXTRA_CFLAGS  $FF_CFLAGS"

make clean

make -j16
make install
echo "end build ffmpeg"