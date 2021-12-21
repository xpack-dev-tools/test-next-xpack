# -----------------------------------------------------------------------------
# This file is part of the xPack distribution.
#   (https://xpack.github.io)
# Copyright (c) 2021 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# Application specific functions.
# Included with 'source' in all other scripts.

# -----------------------------------------------------------------------------

function build_test_next()
{
  local test_next_version="$1"

  local test_next_folder_name="test_next-${test_next_version}"

  mkdir -pv "${LOGS_FOLDER_PATH}/${test_next_folder_name}/"

  local test_next_stamp_file_path="${STAMPS_FOLDER_PATH}/${test_next_folder_name}-installed"
  if [ ! -f "${test_next_stamp_file_path}" ]
  then

    (
      mkdir -p "${BUILD_FOLDER_PATH}/${test_next_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${test_next_folder_name}"

      # Used to set LD_LIBRARY_PATH
      xbb_activate_installed_dev
      
      CFLAGS="-pipe"
      CXXFLAGS="-pipe"

      LDFLAGS=""
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      elif [ "${TARGET_PLATFORM}" == "darwin" ]
      then
        LDFLAGS+=" -static-libgcc -static-libstdc++"
      fi
      if [ "${IS_DEVELOP}" == "y" ]
      then
        LDFLAGS+=" -v"
      fi

      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      local build_type
      if [ "${IS_DEBUG}" == "y" ]
      then
        build_type=Debug
      else
        build_type=Release
      fi

      if [ ! -f "CMakeCache.txt" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running cmake test_next..."

          config_options=()

          config_options+=("-G" "Ninja")

          config_options+=("-DCMAKE_VERBOSE_MAKEFILE=ON")
          config_options+=("-DCMAKE_BUILD_TYPE=${build_type}")

          config_options+=("-DCMAKE_INSTALL_PREFIX=${APP_PREFIX}")

          run_verbose cmake \
            "${config_options[@]}" \
            \
            "$(dirname "${scripts_folder_path}")/meta"

        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${test_next_folder_name}/cmake-output.txt"
      fi

      (
        echo
        echo "Running test_next build..."

        if [ "${IS_DEVELOP}" == "y" ]
        then
          run_verbose cmake \
            --build . \
            --parallel ${JOBS} \
            --verbose \
            --config "${build_type}"
        else
          run_verbose cmake \
            --build . \
            --parallel ${JOBS} \
            --config "${build_type}"
        fi

        (
          echo
          echo "Running test_next install..."

          run_verbose cmake \
            --build . \
            --config "${build_type}" \
            -- \
            install

            show_libs "${APP_PREFIX}/bin/test-next"
        )

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${test_next_folder_name}/build-output.txt"

    )

    else
    echo "Component test_next already installed."
  fi

  tests_add "test_test_next"
}

function test_test_next()
{
  echo
  echo "Running the binaries..."

  TEST_BIN_PATH="${APP_PREFIX}/bin"

  run_app "${TEST_BIN_PATH}/test-next"
}

# -----------------------------------------------------------------------------
