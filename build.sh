#!/bin/bash

ARCHS_TO_BUILD="x86_64 arm64 armv7 armv7s i386"

# LIPO is used to combine static libraries
LIPO="xcrun -sdk iphoneos lipo"

# Need to include local path for gas-preprocessor.pl
PATH="$PATH:$(PWD)"
CPUS=$(sysctl -n hw.logicalcpu_max)

IOS_PLATFORM_BASE="/Applications/Xcode.app/Contents/Developer/Platforms"
IOS_SDK_VERSION=8.1
IOS_SDK_MIN_VERSION=5.1

################################################################################
IOS_PLATFORM_DIR=
IOS_GCC=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
ARCH=
IOS_CFLAGS=
CCASFLAGS=

function make_lib_for_arch() {
  # reset flags
  ARCH="$1"
  IOS_CFLAGS="-arch $ARCH"
  CCASFLAGS=
  EXTRA_BUILD_FLAGS=
  ARM32=
  ARM=

  if [ $ARCH == "i386" ] || [ $ARCH == "armv7" ] || [ $ARCH == "armv7s" ] ; then
    # 32-bit build
    IOS_CFLAGS="$IOS_CFLAGS -mfloat-abi=softfp"
    if [ $ARCH != "i386" ] ; then
      # ARM 32
      ARM32=1
    fi
  fi

  if [ $ARCH == "arm64" ] || [ $ARCH == "armv7" ] || [ $ARCH == "armv7s" ]
  then
    # device build
    ARM=1
    EXTRA_BUILD_FLAGS="--with-gas-preprocessor"
    PLATFORM=iPhoneOS
    MIN_VER_FLAG="-miphoneos-version-min=$IOS_SDK_MIN_VERSION"
    HOST=aarch64-apple-darwin
    if [ $ARCH != "arm64" ] ; then
      HOST=arm-apple-darwin10
    fi
  else
    # simulator build
    PLATFORM=iPhoneSimulator
    MIN_VER_FLAG="-mios-simulator-version-min=$IOS_SDK_MIN_VERSION"
    HOST=$ARCH-apple-darwin

    if [ $ARCH == "x86_64" ] ; then
      EXTRA_BUILD_FLAGS="NASM=/usr/local/bin/nasm"
    fi
  fi

  if [ "$ARM32" == "1" ] ; then
    CCASFLAGS="-no-integrated-as $IOS_CFLAGS"
  fi

  IOS_PLATFORM_DIR="$IOS_PLATFORM_BASE/$PLATFORM.platform"
  IOS_SYSROOT="$IOS_PLATFORM_DIR/Developer/SDKs/$PLATFORM$IOS_SDK_VERSION.sdk"

  ORIG_PATH=$(pwd)
  SRC_PATH="$ORIG_PATH/src"
  BUILD_PATH="build-$ARCH"

  cd $SRC_PATH
    autoreconf -fiv
  cd $ORIG_PATH
  rm -rf $BUILD_PATH
  mkdir -p $BUILD_PATH
  cd $BUILD_PATH

  if [ "$ARM32" == "1" ] ; then
    sh $SRC_PATH/configure --host $HOST \
      --enable-shared=no \
      $EXTRA_BUILD_FLAGS \
      CC="$IOS_GCC" LD="$IOS_GCC" \
      CFLAGS="-isysroot $IOS_SYSROOT -O3 $MIN_VER_FLAG $IOS_CFLAGS" \
      LDFLAGS="-isysroot $IOS_SYSROOT $MIN_VER_FLAG $IOS_CFLAGS" \
      CCASFLAGS="$CCASFLAGS"
  else
    sh $SRC_PATH/configure --host $HOST \
      --enable-shared=no \
      $EXTRA_BUILD_FLAGS \
      CC="$IOS_GCC" LD="$IOS_GCC" \
      CFLAGS="-isysroot $IOS_SYSROOT -O3 $MIN_VER_FLAG $IOS_CFLAGS" \
      LDFLAGS="-isysroot $IOS_SYSROOT $MIN_VER_FLAG $IOS_CFLAGS"
  fi


  # Check that configure succeeds
  if [ $? -ne 0 ] ; then
    echo "Failed to configure for arch $ARCH"
    exit 1
  fi

  # build the lib
  make -j$CPUS

  # Check that make succeeds
  if [ $? -ne 0 ] ; then
    echo "Failed to build for arch $ARCH"
    exit 1
  fi

  # Make a copy of the library
  cd $ORIG_PATH
  cp "$BUILD_PATH/.libs/libturbojpeg.a" "$ORIG_PATH/libturbojpeg.$ARCH.a"
}

function combine_libs() {
  LIPO_ARGS=

  for arch in "$@" ; do
    LIPO_ARGS="$LIPO_ARGS -arch $arch libturbojpeg.$arch.a"
  done

  $LIPO $LIPO_ARGS -create -output libturbojpeg.a
  file libturbojpeg.a
}

for arch in $ARCHS_TO_BUILD ; do
  make_lib_for_arch $arch
done

combine_libs $ARCHS_TO_BUILD
