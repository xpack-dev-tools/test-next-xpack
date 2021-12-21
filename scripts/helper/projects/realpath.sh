# -----------------------------------------------------------------------------
# This file is part of the xPack distribution.
#   (https://xpack.github.io)
# Copyright (c) 2021 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# Minimalistic realpath to be used on macOS
function build_realpath()
{
  # https://github.com/harto/realpath-osx
  # https://github.com/harto/realpath-osx/archive/1.0.0.tar.gz

  # 18 Oct 2012 "1.0.0"

  local realpath_version="$1"

  local realpath_src_folder_name="realpath-osx-${realpath_version}"

  local realpath_archive="${realpath_src_folder_name}.tar.gz"
  # GitHub release archive.
  local realpath_url="https://github.com/harto/realpath-osx/archive/${realpath_version}.tar.gz"

  local realpath_folder_name="${realpath_src_folder_name}"

  mkdir -pv "${LOGS_FOLDER_PATH}/${realpath_folder_name}"

  local realpath_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${realpath_folder_name}-installed"
  if [ ! -f "${realpath_stamp_file_path}" ]
  then

    # In-source build

    if [ ! -d "${BUILD_FOLDER_PATH}/${realpath_folder_name}" ]
    then
      cd "${BUILD_FOLDER_PATH}"

      download_and_extract "${realpath_url}" "${realpath_archive}" \
        "${realpath_src_folder_name}"

      if [ "${realpath_src_folder_name}" != "${realpath_folder_name}" ]
      then
        mv -v "${realpath_src_folder_name}" "${realpath_folder_name}"
      fi
    fi

    (
      cd "${BUILD_FOLDER_PATH}/${realpath_folder_name}"

      # xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"
      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      (
        if [ "${IS_DEVELOP}" == "y" ]
        then
          env | sort
        fi

        echo
        echo "Running realpath make..."

        run_verbose make

        run_verbose install -v -d "${LIBS_INSTALL_FOLDER_PATH}/bin"
        run_verbose install -v -m755 -c realpath "${LIBS_INSTALL_FOLDER_PATH}/bin"

        # TODO: No tests?

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${realpath_folder_name}/configure-output-$(ndate).txt"
    )

    (
      test_realpath
    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${realpath_folder_name}/test-output-$(ndate).txt"

    hash -r

    touch "${realpath_stamp_file_path}"

  else
    echo "Component realpath already installed."
  fi

  # test_functions+=("test_realpath")
}

function test_realpath()
{
  (
    echo
    echo "Checking the realpath binaries shared libraries..."

    show_libs "${LIBS_INSTALL_FOLDER_PATH}/bin/realpath"
  )
}

# -----------------------------------------------------------------------------
