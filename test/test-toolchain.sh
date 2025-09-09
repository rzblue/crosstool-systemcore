#! /usr/bin/env bash
# Adapted from OpenSDK:
# Copyright 2021-2023 Ryan Hirasaki
#
# This file is part of OpenSDK
#
# OpenSDK is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# OpenSDK is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with OpenSDK; see the file COPYING. If not see
# <http://www.gnu.org/licenses/>.

TEST_DIR=$(realpath $(dirname "$0"))

while getopts "l:a:t:p:" opt; do
  case $opt in
	l)
  	case $OPTARG in 
      cxx) TARGET_ENABLE_CXX=true
      ;;
      fortran) TARGET_ENABLE_FORTRAN=true
      ;;
    esac
  	;;
  a)
    ARCHIVE_NAME=$( realpath "$OPTARG" )
    ;;
  t)
    TOOLCHAIN_NAME="$OPTARG"
    ;;
  p)
    TARGET_PREFIX="$OPTARG"
    ;;
	\?)
  	echo "Invalid option: -$OPTARG"
  	;;
	:)
  	echo "Option -$OPTARG requires an argument."
  	;;
  esac
done

die() {
    echo "[FATAL]: $1" >&2
    exit 1
}

xcd() {
    cd "$1" >/dev/null || die "cd failed"
}

xpushd() {
    pushd "$1" >/dev/null || die "pushd failed: $1"
}

xpopd() {
    popd >/dev/null || die "popd failed"
}

cleanup() {
    if [ -d "$tmp" ]; then
        echo "Deleting temporary files"
        chmod u+w -R "$tmp"
        rm -rf "$tmp"
    fi
}
pwd
if [ ! -f "$ARCHIVE_NAME" ]; then
    echo "[ERR] $ARCHIVE_NAME not found"
    exit 1
fi
ARCHIVE_NAME=$( realpath "$ARCHIVE_NAME")

tmp="$(mktemp -d)"
trap cleanup EXIT

xpushd "${tmp}"

mkdir -p toolchain
xpushd toolchain
tar -xf "$ARCHIVE_NAME"

CC="./${TOOLCHAIN_NAME}/bin/${TARGET_PREFIX}gcc"
CXX="./${TOOLCHAIN_NAME}/bin/${TARGET_PREFIX}g++"
GFORTRAN="./${TOOLCHAIN_NAME}/bin/${TARGET_PREFIX}gfortran"
STRIP="./${TOOLCHAIN_NAME}/bin/${TARGET_PREFIX}strip"

MACHINE="$("${CC}" -dumpmachine)"
VERSION="$("${CC}" -dumpversion)"

echo "[INFO]: Compiler Target: ${MACHINE}"
echo "[INFO]: Compiler Version: ${VERSION}"

echo "[INFO]: Testing C Compiler"
"$CC" "${TEST_DIR}/hello.c" -o a.out || exit
echo "[INFO]: Testing C Compiler with libasan"
"$CC" "${TEST_DIR}/hello.c" -o /dev/null -fsanitize=address -latomic || exit
echo "[INFO]: Testing C Compiler with libubsan"
"$CC" "${TEST_DIR}/hello.c" -o /dev/null -fsanitize=undefined -latomic || exit
echo "[INFO]: Testing C Compiler with symbol visibility"
"$CC" "${TEST_DIR}/hello.c" -o /dev/null -fvisibility=hidden -Werror || exit

if [ "${TARGET_ENABLE_CXX}" = "true" ]; then
    echo "[INFO]: Testing C++ Compiler"
    "$CXX" "${TEST_DIR}/hello.cpp" -o /dev/null || exit
    echo "[INFO]: Testing C++ Compiler with libasan"
    "$CXX" "${TEST_DIR}/hello.cpp" -o /dev/null -fsanitize=address -latomic || exit
    echo "[INFO]: Testing C++ Compiler with libubsan"
    "$CXX" "${TEST_DIR}/hello.cpp" -o /dev/null -fsanitize=undefined -latomic || exit
    echo "[INFO]: Testing C++ Compiler with symbol visibility"
    "$CXX" "${TEST_DIR}/hello.cpp" -o /dev/null -fvisibility=hidden -Werror || exit
fi

if [ "${TARGET_ENABLE_FORTRAN}" = "true" ]; then
    echo "[INFO]: Testing Fortran Compiler"
    "$GFORTRAN" "${TEST_DIR}/hello.f95" -o /dev/null || exit
    echo "[INFO]: Testing Fortran Compiler with libasan"
    "$GFORTRAN" "${TEST_DIR}/hello.f95" -o /dev/null -fsanitize=address || exit
    echo "[INFO]: Testing Fortran Compiler with libubsan"
    "$GFORTRAN" "${TEST_DIR}/hello.f95" -o /dev/null -fsanitize=undefined || exit
fi

echo "[INFO]: Testing ELF strip"
"${STRIP}" a.out || exit

echo "[INFO]: Logging basic compiler file result"
file a.out || exit
