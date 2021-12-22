#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# This file is part of the xPack distribution.
#   (https://xpack.github.io)
# Copyright (c) 2021 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Safety settings (see https://gist.github.com/ilg-ul/383869cbb01f61a51c4d).

if [[ ! -z ${DEBUG} ]]
then
  set ${DEBUG} # Activate the expand mode if DEBUG is anything but empty.
else
  DEBUG=""
fi

set -o errexit # Exit if command failed.
set -o pipefail # Exit if pipe failed.
set -o nounset # Exit if variable not set.

# Remove the initial space and instead use '\n'.
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Identify the script location, to reach, for example, the helper scripts.

script_path="$0"
if [[ "${script_path}" != /* ]]
then
  # Make relative path absolute.
  script_path="$(pwd)/$0"
fi

script_name="$(basename "${script_path}")"

script_folder_path="$(dirname "${script_path}")"
script_folder_name="$(basename "${script_folder_path}")"

# =============================================================================

scripts_folder_path="$(dirname $(dirname "${script_folder_path}"))/scripts"
helper_folder_path="${scripts_folder_path}/helper"

# -----------------------------------------------------------------------------

source "${scripts_folder_path}/app-definitions.sh"

# Helper first.
source "${helper_folder_path}/init-functions.sh"
source "${helper_folder_path}/misc-functions.sh"
source "${helper_folder_path}/post-functions.sh"

# Applications may redefine helper functions.
source "${scripts_folder_path}/app-functions.sh"
source "${scripts_folder_path}/app-versions.sh"

# -----------------------------------------------------------------------------

set_xpack_defaults

RELEASE_VERSION="${RELEASE_VERSION:-$(get_current_version)}"

TARGET_FOLDER_PATH="${TARGET_FOLDER_PATH:=""}"
# target-arch, using Node.js semantics.
TARGET_PAIR="${TARGET_PAIR:=""}"

# Node.js process.platform (darwin|linux|win32)
TARGET_PLATFORM=""
# Node.js process.arch (ia32|x64|arm|arm64)
TARGET_ARCH=""

WITH_STRIP=${WITH_STRIP:-"y"}
WITH_PDF=${WITH_PDF:-"n"}
WITH_HTML=${WITH_HTML:-"n"}

WITH_TESTS="${WITH_TESTS:-"y"}"

WITHOUT_MULTILIB="${WITHOUT_MULTILIB:-""}"

IS_DEVELOP="${IS_DEVELOP:-"n"}"
IS_DEBUG="${IS_DEBUG:-"n"}"

TEST_ONLY="${TEST_ONLY:-""}"
USE_GITS="${USE_GITS:-""}"

LINUX_INSTALL_RELATIVE_PATH=""

if [ "$(uname)" == "Linux" ]
then
  JOBS="$(nproc)"
elif [ "$(uname)" == "Darwin" ]
then
  JOBS="$(sysctl hw.ncpu | sed 's/hw.ncpu: //')"
else
  JOBS="1"
fi

if [ ! -z "#{DEBUG}" ]
then
  echo $@
fi

while [ $# -gt 0 ]
do

  case "$1" in

    --target-folder)
      if [ -z ${WORK_FOLDER_PATH+x} ]
      then
        TARGET_FOLDER_PATH="$2"
      else
        TARGET_FOLDER_PATH="${WORK_FOLDER_PATH}/${APP_LC_NAME}-${RELEASE_VERSION}/$(basename "$2")"
      fi
      shift 2
      ;;

    --target)
      TARGET_PAIR="$2"
      TARGET_PLATFORM="$(echo "${TARGET_PAIR}" | sed -e 's|\(.*\)-\(.*\)|\1|')"
      TARGET_ARCH="$(echo "${TARGET_PAIR}" | sed -e 's|\(.*\)-\(.*\)|\2|')"
      shift 2
      ;;

    --disable-strip)
      WITH_STRIP="n"
      shift
      ;;

    --disable-tests)
      WITH_TESTS="n"
      shift
      ;;

    --without-pdf)
      WITH_PDF="n"
      shift
      ;;

    --with-pdf)
      WITH_PDF="y"
      shift
      ;;

    --without-html)
      WITH_HTML="n"
      shift
      ;;

    --with-html)
      WITH_HTML="y"
      shift
      ;;

    --jobs)
      JOBS=$2
      shift 2
      ;;

    --develop)
      IS_DEVELOP="y"
      shift
      ;;

    --debug)
      IS_DEBUG="y"
      shift
      ;;

    --linux-install-relative-path)
      LINUX_INSTALL_RELATIVE_PATH="$2"
      shift 2
      ;;

    --test-only|--tests-only)
      TEST_ONLY="y"
      shift
      ;;

    --disable-multilib)
      WITHOUT_MULTILIB="y"
      shift
      ;;

    --use-gits)
      USE_GITS="y"
      shift
      ;;

    *)
      echo "Unknown action/option $1"
      exit 1
      ;;

  esac

done

if [ "${IS_DEBUG}" == "y" ]
then
  WITH_STRIP="n"
fi

if [ "${TARGET_PLATFORM}" == "win32" ]
then
  export WITH_TESTS="n"
fi

# -----------------------------------------------------------------------------

start_timer

identify_host

set_build_env

# set_compiler_env

# -----------------------------------------------------------------------------

echo
echo "Here we go..."
echo

tests_initialize

build_versions

post_process

# -----------------------------------------------------------------------------

# Final checks.
# To keep everything as pristine as possible, run the tests
# only after the archive is packed.

prime_wine

unset_compiler_env

tests_run

# -----------------------------------------------------------------------------

stop_timer

exit 0

# -----------------------------------------------------------------------------



echo "Building ${APP_NAME}..."
echo "args: $@"
echo "helper path: ${helper_folder_path}"
echo "pwd: $(pwd)"
echo "PATH: ${PATH}"
echo "SHELL: ${SHELL}"


if [ -z "${TARGET_FOLDER_PATH}" ]
then
  echo "Missing --target-folder, quit."
  exit 1
fi

mkdir -pv "${TARGET_FOLDER_PATH}"
cd "${TARGET_FOLDER_PATH}"

mkdir -p build install logs sources


# env | sort
sleep 1
echo "Done."

# -----------------------------------------------------------------------------
