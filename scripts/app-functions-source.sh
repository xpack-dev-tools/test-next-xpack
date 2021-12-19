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

  (
      mkdir -p "${BUILD_FOLDER_PATH}/${test_next_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${test_next_folder_name}"

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
          echo "Running test-next cmake..."

          config_options=()

          config_options+=("-G" "Ninja")

          config_options+=("-DCMAKE_VERBOSE_MAKEFILE=ON")
          config_options+=("-DCMAKE_BUILD_TYPE=${build_type}")

          config_options+=("-DCMAKE_INSTALL_PREFIX=${APP_PREFIX}")
          
          run_verbose_timed cmake \
            ${config_options[@]} \
            \
            "${SOURCES_FOLDER_PATH}/${cmake_src_folder_name}"

        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${cmake_folder_name}/cmake-output.txt"
      fi
      fi

  )
}

# -----------------------------------------------------------------------------
