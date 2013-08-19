#!/bin/sh
#
# by hongbo.yang.me
# 2013-Aug-16th
#

#
# build opencore-amr lib for iOS
#

ROOT=`pwd`
PREFIX="$ROOT/build"

if [ -d "$PREFIX" ]; then
    rm -rf "$PREFIX"
fi

if [ ! -d "$PREFIX" ]; then
    mkdir -p $PREFIX
fi

MODULES_FLAGS="
"

cd opencore-amr
if [ -x "configure" ]; then
    autoreconf -i
fi

if [ "0" != $? ]; then
    echo "Error in generating configure script!"
    exit 1
fi

echo "Building for MacOSX ..."
./configure \
    --prefix="$PREFIX/macosx"
if [ 0 != $? ]; then
    echo "configuring failed"
    cd $ROOT
    exit 1
fi
make clean && make && make install

if [ 0 != $? ]; then
    echo "making failed"
    cd $ROOT
    exit 1
fi
ARCHS=(i386 armv7 armv7s)

for ARCH in ${ARCHS[@]}
do
    echo "Build for $ARCH"
    . ../environment.sh

    PREFIX_DIR="$PREFIX/$ARCH"
    if [ ! -d "$PREFIX_DIR" ]; then
        mkdir -p "$PREFIX_DIR"
    fi
    HOST=
    if [ X"$ARCH" == X"i386" ]; then
       HOST="i386-apple-darwin"
    else
        HOST="arm-apple-darwin"
    fi 
    ./configure --enable-cross-compile \
        $BUILD \
        $HOST \
        --enable-shared=no \
        --enable-static=yes \
        --prefix=$PREFIX_DIR 

    if [ 0 != $? ]; then
        echo "configuring $ARCH failed"
        cd $ROOT
        exit 1
    fi
    make clean && make && make install

    if [ 0 != $? ]; then
        echo "making $ARCH failed"
        cd $ROOT
        exit 1
    fi
done


cd $ROOT
mkdir -p $PREFIX/universal/{include,lib}

for file in $PREFIX/$ARCHS/lib/*.a
do
    files=""
    file=`basename $file`
    for ARCH in ${ARCHS[@]}
    do
       files+=" $PREFIX/$ARCH/lib/$file " 
    done
    echo "Creating universal $file"
    lipo $files -create -output "$PREFIX/universal/lib/$file"
done

cp -r $PREFIX/$ARCHS/include/* $PREFIX/universal/include/
