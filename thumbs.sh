#!/bin/bash

# THe Ultimate Make Bash Script
# Used to wrap build scripts for easy dep
# handling and multiplatform support


# Basic usage on *nix:
# export tbs_arch=x86
# ./thumbs.sh make


# On Win (msvc 2013):
# C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall x86_amd64
# SET tbs_tools=msvc12
# thumbs make

# On Win (mingw32):
# SET path=C:\mingw32\bin;%path%
# SET tbs_tools=mingw
# SET tbs_arch=x86
# thumbs make


# Global settings are stored in env vars
# Should be inherited

[ $tbs_conf ]           || export tbs_conf=Release
[ $tbs_arch ]           || export tbs_arch=x64
[ $tbs_tools ]          || export tbs_tools=gnu
[ $tbs_static_runtime ] || export tbs_static_runtime=0

# -----------

if [ $# -lt 1 ]
then
  echo ""
  echo " Usage : ./thumbs.sh [command]"
  echo ""
  echo " Commands:"
  echo "   make [target]   - builds everything"
  echo "   check           - runs tests"
  echo "   clean           - removes build files"
  echo "   list            - echo paths to any interesting files"
  echo "                     space separated; relative"
  echo "   list_bin        - echo binary paths"
  echo "   list_inc        - echo lib include files"
  echo "   list_slib       - echo static lib path"
  echo "   list_dlib       - echo dynamic lib path"
  echo ""
  exit
fi

# -----------

upper()
{
  echo $1 | tr [:lower:] [:upper:]
}

lower()
{
  echo $1 | tr [:upper:] [:lower:]
}

# Local settings

l_inc="./src/webp"
l_slib=
l_dlib=
l_bin=
list=

make=
c_flags=

target=
[ $2 ] && target=$2

# -----------

case "$tbs_tools" in
msvc12)
  make="nmake //f Makefile.vc CFG=$(lower $tbs_conf)-static OBJDIR=. $target"
  make+=";nmake //f Makefile.vc CFG=$(lower $tbs_conf)-dynamic OBJDIR=. $target"
  
  l_slib="./$(lower $tbs_conf)-static/$tbs_arch/lib/libwebp.lib"
  l_dlib="./$(lower $tbs_conf)-dynamic/$tbs_arch/lib/libwebp_dll.lib"
  l_bin="./$(lower $tbs_conf)-dynamic/$tbs_arch/bin/libwebp.dll"
  list="$l_bin $l_slib $l_dlib $l_inc" ;;
  
gnu)
  c_flags+=" -fPIC"
  make="make -f makefile.unix $target"
  
  l_slib="./src/libwebp.a"
  l_dlib=""
  l_bin=""
  list="$l_slib $l_dlib $l_inc" ;;
  
mingw)
  make="mingw32-make -f makefile.unix $target"
  
  l_slib="./src/libwebp.a"
  l_dlib=""
  l_bin=""
  list="$l_bin $l_slib $l_dlib $l_inc" ;;

*) echo "Tool config not found for $tbs_tools"
   exit 1 ;;
esac

# -----------

case "$tbs_arch" in
x64)
  [ $tbs_tools = gnu -o $tbs_tools = mingw ] && c_flags+=" -m64" ;;
x86)
  [ $tbs_tools = gnu -o $tbs_tools = mingw ] && c_flags+=" -m32" ;;

*) echo "Arch config not found for $tbs_arch"
   exit 1 ;;
esac

# -----------

if [ $tbs_static_runtime -gt 0 ]
then
  [ $tbs_tools = msvc12 ] && c_flags+=" /MT"
fi

# -----------

case "$1" in
make)
  export CFLAGS=$c_flags
  export ARCH=$tbs_arch
  
  eval $make || exit 1
  cd .. ;;
  
check)
  cd build
  ctest . || exit 1
  cd .. ;;
  
clean)
  rm -rf debug-dynamic
  rm -rf debug-static
  rm -rf release-dynamic
  rm -rf release-static ;;

list) echo $list ;;
list_bin) echo $l_bin ;;
list_inc) echo $l_inc ;;
list_slib) echo $l_slib ;;
list_dlib) echo $l_dlib ;;

*) echo "Unknown command $1"
   exit 1 ;;
esac
