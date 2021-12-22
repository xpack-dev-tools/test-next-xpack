# -----------------------------------------------------------------------------
# This file is part of the xPack distribution.
#   (https://xpack.github.io)
# Copyright (c) 2021 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# Common initialisation functions.
# Included with 'source' in the build scripts.

# -----------------------------------------------------------------------------

function set_xpack_defaults()
{
  DISTRO_NAME=${DISTRO_NAME:-"xPack"}
  DISTRO_LC_NAME=${DISTRO_LC_NAME:-"xpack"}
  DISTRO_TOP_FOLDER=${DISTRO_TOP_FOLDER:-"xPacks"}

  APP_DESCRIPTION="${DISTRO_NAME} ${APP_NAME}"

  # ---------------------------------------------------------------------------

  GITHUB_ORG="${GITHUB_ORG:-"xpack-dev-tools"}"
  GITHUB_REPO="${GITHUB_REPO:-"${APP_LC_NAME}-xpack"}"
  GITHUB_PRE_RELEASES="${GITHUB_PRE_RELEASES:-"pre-releases"}"

  NPM_PACKAGE="${NPM_PACKAGE:-"@xpack-dev-tools/${APP_LC_NAME}@next"}"
}

# -----------------------------------------------------------------------------

function identify_host()
{
  echo
  uname -a

  # uname -> Darwin, Linux
  # uname -m -> x86_64, arm64, aarch64, armv7l, armv8l
  # DO NOT use uname -p, it is deprecated in recent Linux distros, use -p.

  HOST_DISTRO_NAME=""
  HOST_UNAME="$(uname)"
  HOST_NODE_PLATFORM=""
  HOST_NODE_ARCH=""

  # uname -m -> x86_64, arm64, aarch64, armv7l, armv8l

  if [ "${HOST_UNAME}" == "Darwin" ]
  then

    HOST_NODE_PLATFORM="darwin"

    HOST_BITS="64"
    HOST_MACHINE="$(uname -m)"
    if [ "${HOST_MACHINE}" == "x86_64" ]
    then
      HOST_NODE_ARCH="x64"
    elif [ "${HOST_MACHINE}" == "arm64" ]
    then
      HOST_NODE_ARCH="arm64"
    else
      echo "Unknown uname -m ${HOST_MACHINE}"
      exit 1
    fi

    HOST_DISTRO_NAME=Darwin
    HOST_DISTRO_LC_NAME=darwin

  elif [ "${HOST_UNAME}" == "Linux" ]
  then
    # ----- Determine distribution name and word size -----

    set +e
    HOST_DISTRO_NAME=$(lsb_release -si)
    set -e

    HOST_NODE_PLATFORM="linux"

    if [ -z "${HOST_DISTRO_NAME}" ]
    then
      echo "Please install the lsb core package and rerun."
      HOST_DISTRO_NAME="Linux"
    fi

    HOST_MACHINE="$(uname -m)"
    if [ "${HOST_MACHINE}" == "x86_64" ]
    then
      HOST_BITS="64"
      HOST_NODE_ARCH="x64"
    elif [ "${HOST_MACHINE}" == "i686" ]
    then
      HOST_BITS="32"
      HOST_NODE_ARCH="ia32"
    elif [ "${HOST_MACHINE}" == "aarch64" ]
    then
      HOST_BITS="64"
      HOST_NODE_ARCH="arm64"
    elif [ "${HOST_MACHINE}" == "armv7l" \
      -o "${HOST_MACHINE}" == "armv8l" ]
    then
      HOST_BITS="32"
      HOST_NODE_ARCH="arm"
    else
      echo "Unknown uname -m ${HOST_MACHINE}"
      exit 1
    fi

    HOST_DISTRO_LC_NAME=$(echo ${HOST_DISTRO_NAME} | tr "[:upper:]" "[:lower:]")

  else
    echo "Unknown uname ${HOST_UNAME}"
    exit 1
  fi

  echo
  echo "Build script running on ${HOST_DISTRO_NAME} ${HOST_NODE_ARCH} (${HOST_BITS}-bit)."
  echo "User $(whoami), in '${HOME}'"

  HOST_ROOT_UMASK=${HOST_ROOT_UMASK:-"000"}

  if [ -f "/.dockerenv" -a "$(whoami)" == "root" ]
  then
    umask ${HOST_ROOT_UMASK}
  fi
}

# -----------------------------------------------------------------------------

function set_build_env()
{
  # Defaults, to ensure the variables are defined.
  PATH="${PATH:-""}"
  LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-""}"

  DOT_EXE=""

  if [ -z "${TARGET_PLATFORM}" -a -z "${TARGET_ARCH}" ]
  then
    # If the target was not specified, assume a native build (current host).
    TARGET_PLATFORM="${HOST_NODE_PLATFORM}"
    TARGET_ARCH="${HOST_NODE_ARCH}"
    TARGET_BITS="${HOST_BITS}"
  else
    case "${TARGET_PLATFORM}" in
      ia32|arm)
        TARGET_BITS=32
        ;;
      x64|arm64)
        TARGET_BITS=64
        ;;
      *)
        echo "Unsupported TARGET_PLATFORM ${TARGET_PLATFORM}"
        exit 1
    esac
  fi

  # Compute the BUILD/HOST/TARGET for configure.
  CROSS_COMPILE_PREFIX=""
  if [ "${TARGET_PLATFORM}" == "win32" ]
  then

    # Disable test when cross compiling for Windows.
    WITH_TESTS="n"

    # For Windows targets, decide which cross toolchain to use.
    if [ "${TARGET_ARCH}" == "x64" ]
    then
      CROSS_COMPILE_PREFIX="x86_64-w64-mingw32"
    else
      echo "Oops! Unsupported TARGET_ARCH=${TARGET_ARCH}."
      exit 1
    fi

    do_config_guess

    DOT_EXE=".exe"

    HOST="${CROSS_COMPILE_PREFIX}"
    TARGET="${HOST}"

  elif [ "${TARGET_PLATFORM}" == "darwin" ]
  then

    do_config_guess

    HOST="${BUILD}"
    TARGET="${HOST}"

  elif [ "${TARGET_PLATFORM}" == "linux" ]
  then

    do_config_guess

    HOST="${BUILD}"
    TARGET="${HOST}"

  else
    echo "Oops! Unsupported TARGET_PLATFORM=${TARGET_PLATFORM}."
    exit 1
  fi

  BUILD_FOLDER_PATH="${TARGET_FOLDER_PATH}/build"
  mkdir -pv "${BUILD_FOLDER_PATH}"

  LIBS_BUILD_FOLDER_PATH="${BUILD_FOLDER_PATH}/libs"
  mkdir -pv "${LIBS_BUILD_FOLDER_PATH}"

  INSTALL_FOLDER_PATH="${TARGET_FOLDER_PATH}/install"
  LIBS_INSTALL_FOLDER_PATH="${INSTALL_FOLDER_PATH}/libs"
  mkdir -pv "${LIBS_INSTALL_FOLDER_PATH}/include"
  mkdir -pv "${LIBS_INSTALL_FOLDER_PATH}/lib"

  STAMPS_FOLDER_PATH="${INSTALL_FOLDER_PATH}"

  LOGS_FOLDER_NAME=${LOGS_FOLDER_NAME:-"logs"}
  LOGS_FOLDER_PATH="${TARGET_FOLDER_PATH}/${LOGS_FOLDER_NAME}"
  mkdir -pv "${LOGS_FOLDER_PATH}"

  DEPLOY_FOLDER_NAME=${DEPLOY_FOLDER_NAME:-"deploy"}
  DEPLOY_FOLDER_PATH="$(dirname "${TARGET_FOLDER_PATH}")/${DEPLOY_FOLDER_NAME}"
  mkdir -pv "${DEPLOY_FOLDER_PATH}"

  DISTRO_INFO_NAME=${DISTRO_INFO_NAME:-"distro-info"}

  BUILD_GIT_PATH="${TARGET_FOLDER_PATH}/build.git"

  APP_PREFIX="${INSTALL_FOLDER_PATH}/${APP_LC_NAME}"
  # Use with --docdir, --mandir, --infodir, --htmldir, --pdfdir.
  APP_PREFIX_DOC="${APP_PREFIX}/share/doc"

  SOURCES_FOLDER_PATH=${SOURCES_FOLDER_PATH:-"${TARGET_FOLDER_PATH}/sources"}
  mkdir -pv "${SOURCES_FOLDER_PATH}"

  if [ "${TARGET_PLATFORM}" == "darwin" -a "${TARGET_ARCH}" == "arm64" ]
  then
    WITH_UPDATE_CONFIG_SUB=${WITH_UPDATE_CONFIG_SUB:-"y"}
  else
    WITH_UPDATE_CONFIG_SUB=${WITH_UPDATE_CONFIG_SUB:-""}
  fi

  TARGET_FOLDER_NAME="${TARGET_PLATFORM}-${TARGET_ARCH}"

  # Use the UTC date as version in the name of the distribution file.
  DISTRIBUTION_FILE_DATE=${DISTRIBUTION_FILE_DATE:-$(date -u +%Y%m%d-%H%M)}

  CACHE_FOLDER_PATH=${CACHE_FOLDER_PATH:-"${HOME}/Work/cache"}

  # ---------------------------------------------------------------------------

  export BUILD
  export HOST
  export TARGET

  export LANGUAGE="en_US:en"
  export LANG="en_US.UTF-8"
  export LC_ALL="en_US.UTF-8"
  export LC_COLLATE="en_US.UTF-8"
  export LC_CTYPE="UTF-8"
  export LC_MESSAGES="en_US.UTF-8"
  export LC_MONETARY="en_US.UTF-8"
  export LC_NUMERIC="en_US.UTF-8"
  export LC_TIME="en_US.UTF-8"

  export PATH
  export LD_LIBRARY_PATH

  export APP_PREFIX
  export SOURCES_FOLDER_PATH
  export DOT_EXE

  # libtool fails with the Ubuntu /bin/sh.
  export SHELL="/bin/bash"
  export CONFIG_SHELL="/bin/bash"

  echo
  env | sort

}

function get_current_version()
{
  local version_file_path="${scripts_folder_path}/VERSION"
  if [ $# -ge 1 ]
  then
    version_file_path="$1"
  fi

  # Extract only the first line
  cat "${version_file_path}" | sed -e '2,$d'
}

function get_current_package_version()
{
  # Hack to get the 'repo' path.
  local package_file_path="$(dirname "${scripts_folder_path}")/package.json"
  if [ $# -ge 1 ]
  then
    package_file_path="$1"
  fi

  # Extract only the first line
  grep '"version":' "${package_file_path}" | sed -e 's|.*"version": "\(.*\)".*|\1|'
}

function do_config_guess()
{
  BUILD="$(bash ${helper_folder_path}/config.guess)"
}

function _set_compiler_env()
{
  if [ "${TARGET_PLATFORM}" == "darwin" ]
  then
    set_clang_env "" ""
  else
    set_gcc_env "" ""
  fi

  if [ "${TARGET_PLATFORM}" == "win32" ]
  then
    export NATIVE_CC=${CC}
    export NATIVE_CXX=${CXX}
  fi

  (
    which ${CC}
    ${CC} --version

    which make
    make --version
  )
}

function set_clang_env()
{
  local prefix="${1:-}"
  local suffix="${2:-}"

  unset_compiler_env

  export CC="${prefix}clang${suffix}"
  export CXX="${prefix}clang++${suffix}"

  export AR="${prefix}ar"
  export AS="${prefix}as"
  # export DLLTOOL="${prefix}dlltool"
  export LD="${prefix}ld"
  export NM="${prefix}nm"
  # export OBJCOPY="${prefix}objcopy"
  export OBJDUMP="${prefix}objdump"
  export RANLIB="${prefix}ranlib"
  # export READELF="${prefix}readelf"
  export SIZE="${prefix}size"
  export STRIP="${prefix}strip"
  # export WINDRES="${prefix}windres"
  # export WINDMC="${prefix}windmc"
  # export RC="${prefix}windres"

  set_xbb_extras
}

function set_gcc_env()
{
  local prefix="${1:-}"
  local suffix="${2:-}"

  unset_compiler_env

  export CC="${prefix}gcc${suffix}"
  export CXX="${prefix}g++${suffix}"

  # These are the special GCC versions, not the binutils ones.
  export AR="${prefix}gcc-ar${suffix}"
  export NM="${prefix}gcc-nm${suffix}"
  export RANLIB="${prefix}gcc-ranlib${suffix}"

  # From binutils.
  export AS="${prefix}as"
  export DLLTOOL="${prefix}dlltool"
  export LD="${prefix}ld"
  export OBJCOPY="${prefix}objcopy"
  export OBJDUMP="${prefix}objdump"
  export READELF="${prefix}readelf"
  export SIZE="${prefix}size"
  export STRIP="${prefix}strip"
  export WINDRES="${prefix}windres"
  export WINDMC="${prefix}windmc"
  export RC="${prefix}windres"

  set_xbb_extras
}

function unset_compiler_env()
{
  unset CC
  unset CXX
  unset AR
  unset AS
  unset DLLTOOL
  unset LD
  unset NM
  unset OBJCOPY
  unset OBJDUMP
  unset RANLIB
  unset READELF
  unset SIZE
  unset STRIP
  unset WINDRES
  unset WINDMC
  unset RC

  unset XBB_CPPFLAGS

  unset XBB_CFLAGS
  unset XBB_CXXFLAGS

  unset XBB_CFLAGS_NO_W
  unset XBB_CXXFLAGS_NO_W

  unset XBB_LDFLAGS
  unset XBB_LDFLAGS_LIB
  unset XBB_LDFLAGS_APP
  unset XBB_LDFLAGS_APP_STATIC_GCC
}

function set_xbb_extras()
{
  # ---------------------------------------------------------------------------

  XBB_CPPFLAGS=""

  XBB_CFLAGS="-ffunction-sections -fdata-sections -pipe"
  XBB_CXXFLAGS="-ffunction-sections -fdata-sections -pipe"

  if [ "${TARGET_ARCH}" == "x64" -o "${TARGET_ARCH}" == "x32" -o "${TARGET_ARCH}" == "ia32" ]
  then
    XBB_CFLAGS+=" -m${TARGET_BITS}"
    XBB_CXXFLAGS+=" -m${TARGET_BITS}"
  fi

  XBB_LDFLAGS=""

  if [ "${IS_DEBUG}" == "y" ]
  then
    XBB_CFLAGS+=" -g -O0"
    XBB_CXXFLAGS+=" -g -O0"
    XBB_LDFLAGS+=" -g -O0"
  else
    XBB_CFLAGS+=" -O2"
    XBB_CXXFLAGS+=" -O2"
    XBB_LDFLAGS+=" -O2"
  fi

  if [ "${IS_DEVELOP}" == "y" ]
  then
    XBB_LDFLAGS+=" -v"
  fi

  if [ "${TARGET_PLATFORM}" == "linux" ]
  then
    SHLIB_EXT="so"

    # Do not add -static here, it fails.
    # Do not try to link pthread statically, it must match the system glibc.
    XBB_LDFLAGS_LIB="${XBB_LDFLAGS}"
    XBB_LDFLAGS_APP="${XBB_LDFLAGS} -Wl,--gc-sections"
    XBB_LDFLAGS_APP_STATIC_GCC="${XBB_LDFLAGS_APP} -static-libgcc -static-libstdc++"
  elif [ "${TARGET_PLATFORM}" == "darwin" ]
  then
    SHLIB_EXT="dylib"

    if [ "${TARGET_ARCH}" == "x64" ]
    then
      export MACOSX_DEPLOYMENT_TARGET="10.13"
    elif [ "${TARGET_ARCH}" == "arm64" ]
    then
      export MACOSX_DEPLOYMENT_TARGET="11.0"
    else
      echo "Unknown TARGET_ARCH ${TARGET_ARCH}"
      exit 1
    fi

    if [[ "${CC}" =~ *clang* ]]
    then
      XBB_CFLAGS+=" -mmacosx-version-min=${MACOSX_DEPLOYMENT_TARGET}"
      XBB_CXXFLAGS+=" -mmacosx-version-min=${MACOSX_DEPLOYMENT_TARGET}"
    fi

    # Note: macOS linker ignores -static-libstdc++, so
    # libstdc++.6.dylib should be handled.
    XBB_LDFLAGS+=" -Wl,-macosx_version_min,${MACOSX_DEPLOYMENT_TARGET}"

    # With GCC 11.2 path are longer, and post-processing may fail:
    # error: /Library/Developer/CommandLineTools/usr/bin/install_name_tool: changing install names or rpaths can't be redone for: /Users/ilg/Work/gcc-11.2.0-2/darwin-x64/install/gcc/libexec/gcc/x86_64-apple-darwin17.7.0/11.2.0/g++-mapper-server (for architecture x86_64) because larger updated load commands do not fit (the program must be relinked, and you may need to use -headerpad or -headerpad_max_install_names)
    XBB_LDFLAGS+=" -Wl,-headerpad_max_install_names"

    XBB_LDFLAGS_LIB="${XBB_LDFLAGS}"
    XBB_LDFLAGS_APP="${XBB_LDFLAGS} -Wl,-dead_strip"
    XBB_LDFLAGS_APP_STATIC_GCC="${XBB_LDFLAGS_APP} -static-libstdc++"
    if [[ "${CC}" =~ *gcc* ]]
    then
      XBB_LDFLAGS_APP_STATIC_GCC+=" -static-libgcc"
    fi
  elif [ "${TARGET_PLATFORM}" == "win32" ]
  then
    SHLIB_EXT="dll"

    # Note: use this explcitly in the application.
    # set_gcc_env "${CROSS_COMPILE_PREFIX}-"

    # To make `access()` not fail when passing a non-zero mode.
    # https://sourceforge.net/p/mingw-w64/mailman/message/37372220/
    # Do not add it to XBB_CPPFLAGS, since the current macro
    # crashes C++ code, like in `llvm/lib/Support/LockFileManager.cpp`:
    # `if (sys::fs::access(LockFileName.c_str(), sys::fs::AccessMode::Exist) ==`
    XBB_CFLAGS+=" -D__USE_MINGW_ACCESS"

    # CRT_glob is from Arm script
    # -static avoids libwinpthread-1.dll
    # -static-libgcc avoids libgcc_s_sjlj-1.dll
    XBB_LDFLAGS_LIB="${XBB_LDFLAGS}"
    XBB_LDFLAGS_APP="${XBB_LDFLAGS} -Wl,--gc-sections"
    XBB_LDFLAGS_APP_STATIC_GCC="${XBB_LDFLAGS_APP} -static-libgcc -static-libstdc++"
  else
    echo "Oops! Unsupported TARGET_PLATFORM=${TARGET_PLATFORM}."
    exit 1
  fi

  XBB_CFLAGS_NO_W="${XBB_CFLAGS} -w"
  XBB_CXXFLAGS_NO_W="${XBB_CXXFLAGS} -w"

  PKG_CONFIG="${helper_folder_path}/pkg-config-verbose"

  # Hopefully defining it empty would be enough...
  PKG_CONFIG_PATH=${PKG_CONFIG_PATH:-""}

  # Prevent pkg-config to search the system folders (configured in the
  # pkg-config at build time).
  PKG_CONFIG_LIBDIR=${PKG_CONFIG_LIBDIR:-""}

  set +u
  echo
  echo "CC=${CC}"
  echo "CXX=${CXX}"
  echo "XBB_CPPFLAGS=${XBB_CPPFLAGS}"
  echo "XBB_CFLAGS=${XBB_CFLAGS}"
  echo "XBB_CXXFLAGS=${XBB_CXXFLAGS}"

  echo "XBB_LDFLAGS_LIB=${XBB_LDFLAGS_LIB}"
  echo "XBB_LDFLAGS_APP=${XBB_LDFLAGS_APP}"
  echo "XBB_LDFLAGS_APP_STATIC_GCC=${XBB_LDFLAGS_APP_STATIC_GCC}"

  echo "PKG_CONFIG=${PKG_CONFIG}"
  echo "PKG_CONFIG_PATH=${PKG_CONFIG_PATH}"
  echo "PKG_CONFIG_LIBDIR=${PKG_CONFIG_LIBDIR}"
  set -u

  # ---------------------------------------------------------------------------

  export SHLIB_EXT

  # CC & co were exported by set_gcc_env.
  export XBB_CPPFLAGS

  export XBB_CFLAGS
  export XBB_CXXFLAGS

  export XBB_CFLAGS_NO_W
  export XBB_CXXFLAGS_NO_W

  export XBB_LDFLAGS
  export XBB_LDFLAGS_LIB
  export XBB_LDFLAGS_APP
  export XBB_LDFLAGS_APP_STATIC_GCC

  export PKG_CONFIG
  export PKG_CONFIG_PATH
  export PKG_CONFIG_LIBDIR
}

# -----------------------------------------------------------------------------
