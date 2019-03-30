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