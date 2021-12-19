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

functions identify_host()
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

  # Compute the BUILD/HOST/TARGET for configure.
  CROSS_COMPILE_PREFIX=""
  if [ "${TARGET_PLATFORM}" == "win32" ]
  then

    # Disable test when cross compiling for Windows.
    WITH_TESTS="n"

    # For Windows targets, decide which cross toolchain to use.
    if if [ "${TARGET_ARCH}" == "x64" ]
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
  DEPLOY_FOLDER_PATH="$(dirname "${scripts_folder_path}")/${DEPLOY_FOLDER_NAME}"
  mkdir -pv "${DEPLOY_FOLDER_PATH}"

  DISTRO_INFO_NAME=${DISTRO_INFO_NAME:-"distro-info"}

  BUILD_GIT_PATH="${WORK_FOLDER_PATH}/build.git"

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

function do_config_guess()
{
  BUILD="$(bash ${helper_folder_path}/config.guess)"
}

# -----------------------------------------------------------------------------
