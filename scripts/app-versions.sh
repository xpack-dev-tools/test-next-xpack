# -----------------------------------------------------------------------------
# This file is part of the xPack distribution.
#   (https://xpack.github.io)
# Copyright (c) 2021 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# Application versions specific functions.
# Included with 'source' in all other scripts.

# -----------------------------------------------------------------------------

source "${helper_folder_path}/projects/patchelf.sh"

# -----------------------------------------------------------------------------

function build_versions()
{
  TEST_NEXT_VERSION="$(echo "${RELEASE_VERSION}" | sed -e 's|-.*||')"

  if [ "${TARGET_PLATFORM}" == "win32" ]
  then
    # TODO: add support for building Windows on Linux (mingw-gcc).
    set_gcc_env "${CROSS_COMPILE_PREFIX}-"
  else
    # On Linux & macOS use the xPack GCC.
    set_gcc_env
  fi

  # Temporary, until everything will be available as xpacks.
  if [ "${HOST_UNAME}" == "Darwin" ]
  then
    if [ -d "${HOME}/.local/xbb" ]
    then
      # Note that the xbb path is added at the end.
      : # PATH="${PATH}:${HOME}/.local/xbb/bin"
    fi
  fi

  if [ "${TARGET_PLATFORM}" == "win32" ]
  then
    # In Windows there is still a reference to libgcc_s and libwinpthread
    export DO_COPY_GCC_LIBS="y"
  fi

  run_verbose ${CC} --version

  if [[ "${RELEASE_VERSION}" =~ 1\.2\.3-.* ]]
  then

    if [ "${TARGET_PLATFORM}" == "linux" ]
    then
      build_patchelf "0.14.3"
      if [ -x "${LIBS_INSTALL_FOLDER_PATH}/bin/patchelf" ]
      then
        export PATCHELF="${LIBS_INSTALL_FOLDER_PATH}/bin/patchelf"
      else
        echo "local patchelf not found"
        exit 1
      fi
    fi

    build_test_next "${TEST_NEXT_VERSION}"

    # -------------------------------------------------------------------------
  else
    echo "Unsupported version ${RELEASE_VERSION}."
    exit 1
  fi

}

# -----------------------------------------------------------------------------
