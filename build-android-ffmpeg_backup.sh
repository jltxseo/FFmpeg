#!/bin/bash

# ndk环境    
export NDK=/mnt/f/ffmpegLearn/android-ndk-r17c

CPU=armv7-a
ARCH=arm
API=19
PLATFORM=arm-linux-androideabi

export SYSROOT=$NDK/platforms/android-$API/arch-arm
export TOOLCHAIN=$NDK/toolchains/$PLATFORM-4.9/prebuilt/linux-x86_64


#android-ndk-r16b之前版本的头文件位于{NDK_HOME}/platforms/{android-21}/{arch-arm}/usr/include，
# r16b及之后的版本头文件位于{NDK_HOME}/sysroot/usr/include
ISYSROOT=$NDK/sysroot
ASM=$ISYSROOT/usr/include/$PLATFORM


# 要保存动态库的目录，这里保存在源码根目录下的android/armv7-a
export PREFIX=$(pwd)/android/$CPU
ADDI_CFLAGS="-marm"

function build_android
{
    echo "start build ffmpeg"

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
        --disable-doc \
        --disable-symver \
        # 禁用全部的编码
        --disable-encoders \
        # 启用几个常用的编码
        # 启用 x264 这个库
        --enable-libx264 \
        # 启用 x264 编码
        --enable-encoder=libx264 \
        --enable-encoder=mpeg4 \
        --enable-encoder=libfdk_aac \
        # 这两个是链接 x264 静态库需要
        --enable-gpl \
        --enable-yasm \
        # 启用几个图片编码，由于生成视频预览
        --enable-encoder=mjpeg \
        --enable-encoder=png \
        # 启用 aac 音频编码
        --enable-encoder=aac \
        --enable-nonfree \

        --enable-muxers \
        --enable-muxer=mov \
        --enable-muxer=mp4 \
        --enable-muxer=h264 \
        --enable-muxer=avi \

        --disable-demuxers \
        --enable-demuxer=image2 \
        --enable-demuxer=h264 \
        --enable-demuxer=aac \
        --enable-demuxer=avi \
        --enable-demuxer=mpc \
        --enable-demuxer=mpegts \
        --enable-demuxer=mov \

        # 禁用全部的解码器
        --disable-decoders \
        # 启用几个常用的解码
        --enable-decoder=aac \
        --enable-decoder=aac_latm \
        --enable-decoder=h264 \
        --enable-decoder=mpeg4 \
        --enable-decoder=mjpeg \
        --enable-decoder=png \

        --disable-parsers \
        --enable-parser=aac \
        --enable-parser=ac3 \
        --enable-parser=h264 \

        --cross-prefix=$TOOLCHAIN/bin/$PLATFORM- \
        --arch=$ARCH \
        --cpu=$CPU \
        --sysroot=$SYSROOT \
        --extra-cflags="-I$ASM -isysroot $ISYSROOT -D__ANDROID_API__=$API -U_FILE_OFFSET_BITS -Os -fPIC -DANDROID -Wno-deprecated -mfloat-abi=softfp -marm" \
        --extra-ldflags="$ADDI_LDFLAGS" \
        $ADDITIONAL_CONFIGURE_FLAG

    make clean

    make -j16
    make install

    # 打包
    $TOOLCHAIN/bin/arm-linux-androideabi-ld \
        -rpath-link=$SYSROOT/usr/lib \
        -L$SYSROOT/usr/lib \
        -L$PREFIX/lib \
        -soname libffmpeg.so -shared -nostdlib -Bsymbolic --whole-archive --no-undefined -o \
        $PREFIX/libffmpeg.so \
        libavcodec/libavcodec.a \
        libavfilter/libavfilter.a \
        libavformat/libavformat.a \
        libavutil/libavutil.a \
        libswresample/libswresample.a \
        libswscale/libswscale.a \
        -lc -lm -lz -ldl -llog --dynamic-linker=/system/bin/linker \
        $TOOLCHAIN/lib/gcc/arm-linux-androideabi/4.9.x/libgcc.a

    # strip 精简文件
    $TOOLCHAIN/bin/arm-linux-androideabi-strip  $PREFIX/libffmpeg.so

    echo "end build ffmpeg"
}

build_android