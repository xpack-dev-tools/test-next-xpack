# -----------------------------------------------------------------------------
# This file is part of the xPack distribution.
#   (https://xpack.github.io)
# Copyright (c) 2021 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# Common miscellaneous functions.
# Included with 'source' in the build scripts.

# -----------------------------------------------------------------------------

# Local hack to avoid a dependency to realpath(1).
function realpath()
{
  python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$1"
}

# -----------------------------------------------------------------------------

function start_timer()
{
  BUILD_BEGIN_SECOND=$(date +%s)
  echo
  echo "Build script \"$0\" started at $(date)."
}

function stop_timer()
{
  local end_second=$(date +%s)
  echo
  echo "Build script \"$0\" completed at $(date)."
  local delta_seconds=$((end_second-BUILD_BEGIN_SECOND))
  if [ ${delta_seconds} -lt 100 ]
  then
    echo "Duration: ${delta_seconds} seconds."
  else
    local delta_minutes=$(((delta_seconds+30)/60))
    echo "Duration: ${delta_minutes} minutes."
  fi
}

function ndate()
{
  date -u +%Y%m%d-%H%M%S
}

# -----------------------------------------------------------------------------

function run_verbose()
{
  # Does not include the .exe extension.
  local app_path=$1
  shift

  echo
  echo "[${app_path} $@]"
  "${app_path}" "$@" 2>&1
}

function run_verbose_develop()
{
  # Does not include the .exe extension.
  local app_path=$1
  shift

  if [ "${IS_DEVELOP}" == "y" ]
  then
    echo
    echo "[${app_path} $@]"
  fi
  "${app_path}" "$@" 2>&1
}

function run_verbose_timed()
{
  # Does not include the .exe extension.
  local app_path=$1
  shift

  echo
  echo "[${app_path} $@]"
  time "${app_path}" "$@" 2>&1
}

function echo_develop()
{
  if [ "${IS_DEVELOP}" == "y" ]
  then
    echo "$@"
  fi
}

# -----------------------------------------------------------------------------

function tests_initialize()
{
  export TEST_FUNCTION_NAMES_FILE_PATH="${INSTALL_FOLDER_PATH}/test-function-names"
  rm -rf "${TEST_FUNCTION_NAMES_FILE_PATH}"
  touch "${TEST_FUNCTION_NAMES_FILE_PATH}"
}

function tests_add()
{
  echo "$1" >> "${TEST_FUNCTION_NAMES_FILE_PATH}"
}

function tests_run()
{
  (
    echo
    echo "Runnng final tests..."

    for test_function in $(cat ${TEST_FUNCTION_NAMES_FILE_PATH})
    do
      if [ "${test_function}" != "" ]
      then
        echo
        local func=$(echo ${test_function} | sed -e 's|-|_|g')
        echo "Running ${func}..."
        ${func}
      fi
    done
  ) 2>&1 | tee "${LOGS_FOLDER_PATH}/tests-output-$(date -u +%Y%m%d-%H%M).txt"
}

# -----------------------------------------------------------------------------

function run_app()
{
  # Does not include the .exe extension.
  local app_path=$1
  shift

  if [ "${TARGET_PLATFORM}" == "linux" ]
  then
    run_verbose "${app_path}" "$@"
  elif [ "${TARGET_PLATFORM}" == "darwin" ]
  then
    run_verbose "${app_path}" "$@"
  elif [ "${TARGET_PLATFORM}" == "win32" ]
  then
    if [ -x "${app_path}" ]
    then
      # When testing native variants, like llvm.
      run_verbose "${app_path}" "$@"
      return
    fi

    if [ "$(uname -o)" == "Msys" ]
    then
      run_verbose "${app_path}.exe" "$@"
      return
    fi

    local wsl_path=$(which wsl.exe 2>/dev/null)
    if [ ! -z "${wsl_path}" ]
    then
      run_verbose "${app_path}.exe" "$@"
      return
    fi

    (
      local wine_path=$(which wine 2>/dev/null)
      if [ ! -z "${wine_path}" ]
      then
        if [ -f "${app_path}.exe" ]
        then
          run_verbose wine "${app_path}.exe" "$@"
        else
          echo "${app_path}.exe not found"
          exit 1
        fi
      else
        echo "Install wine if you want to run the .exe binaries on Linux."
      fi
    )

  else
    echo "Oops! Unsupported TARGET_PLATFORM=${TARGET_PLATFORM}."
    exit 1
  fi
}

function run_app_silent()
{
  # Does not include the .exe extension.
  local app_path=$1
  shift

  if [ "${TARGET_PLATFORM}" == "linux" ]
  then
    "${app_path}" "$@" 2>&1
  elif [ "${TARGET_PLATFORM}" == "darwin" ]
  then
    "${app_path}" "$@" 2>&1
  elif [ "${TARGET_PLATFORM}" == "win32" ]
  then
    if [ "$(uname -o)" == "Msys" ]
    then
      "${app_path}.exe" "$@"
      return
    fi

    local wsl_path=$(which wsl.exe 2>/dev/null)
    if [ ! -z "${wsl_path}" ]
    then
      "${app_path}.exe" "$@" 2>&1
      return
    fi
    (
      local wine_path=$(which wine 2>/dev/null)
      if [ ! -z "${wine_path}" ]
      then
        if [ -f "${app_path}.exe" ]
        then
          wine "${app_path}.exe" "$@" 2>&1
        else
          echo "${app_path}.exe not found"
          exit 1
        fi
      else
        echo "Install wine if you want to run the .exe binaries on Linux."
      fi
    )

  else
    echo "Oops! Unsupported TARGET_PLATFORM=${TARGET_PLATFORM}."
    exit 1
  fi
}

function run_app_exit()
{
  local expected_exit_code=$1
  shift
  local app_path=$1
  shift
  if [ "${node_platform}" == "win32" ]
  then
    app_path+='.exe'
  fi

  (
    set +e
    echo
    echo "${app_path} $@"
    "${app_path}" "$@" 2>&1
    local actual_exit_code=$?
    echo "exit(${actual_exit_code})"
    set -e
    if [ ${actual_exit_code} -ne ${expected_exit_code} ]
    then
      exit ${actual_exit_code}
    fi
  )
}

function test_expect()
{
  local app_name="$1"
  local expected="$2"

  show_libs "${app_name}"

  # Remove the trailing CR present on Windows.
  local output
  if [ "${app_name:0:1}" == "/" ]
  then
    output="$(run_app_silent "${app_name}" "$@" | sed 's/\r$//')"
  else
    output="$(run_app_silent "./${app_name}" "$@" | sed 's/\r$//')"
  fi

  if [ "x${output}x" == "x${expected}x" ]
  then
    echo
    echo "Test \"${app_name}\" passed :-)"
  else
    echo "expected ${#expected}: \"${expected}\""
    echo "got ${#output}: \"${output}\""
    echo
    exit 1
  fi
}

# -----------------------------------------------------------------------------

function readelf_shared_libs()
{
  local file_path="$1"
  shift

  (
    set +e

    readelf -d "${file_path}" | egrep '(SONAME)' || true
    readelf -d "${file_path}" | egrep '(RUNPATH|RPATH)' || true
    readelf -d "${file_path}" | egrep '(NEEDED)' || true
  )
}


function show_libs()
{
  # Does not include the .exe extension.
  local app_path=$1
  shift

  (
    if [ "${TARGET_PLATFORM}" == "linux" ]
    then
      run_verbose ls -l "${app_path}"
      echo
      echo "[readelf -d ${app_path} | egrep ...]"
      # Ignore errors in case it is not using shared libraries.
      set +e
      readelf_shared_libs "${app_path}"
      echo
      echo "[ldd -v ${app_path}]"
      ldd -v "${app_path}" || true
      set -e
    elif [ "${TARGET_PLATFORM}" == "darwin" ]
    then
      run_verbose ls -l "${app_path}"
      if [ "${IS_DEVELOP}" == "y" ]
      then
        run_verbose file "${app_path}"
      fi
      echo
      echo "[otool -L ${app_path}]"
      set +e
      local lc_rpaths=$(get_darwin_lc_rpaths "${app_path}")
      local lc_rpaths_line=$(echo "${lc_rpaths}" | tr '\n' ':' | sed -e 's|:$||')
      if [ ! -z "${lc_rpaths_line}" ]
      then
        echo "${app_path}: (LC_RPATH=${lc_rpaths_line})"
      else
        echo "${app_path}:"
      fi
      otool -L "${app_path}" | sed -e '1d'
    elif [ "${TARGET_PLATFORM}" == "win32" ]
    then
      if is_elf "${app_path}"
      then
        run_verbose ls -l "${app_path}"
        echo
        echo "[readelf -d ${app_path} | egrep ...]"
        # Ignore errors in case it is not using shared libraries.
        set +e
        readelf_shared_libs "${app_path}"
        echo
        echo "[ldd -v ${app_path}]"
        ldd -v "${app_path}" || true
        set -e
      else
        if [ -f "${app_path}" ]
        then
          run_verbose ls -l "${app_path}"
          echo
          echo "[${CROSS_COMPILE_PREFIX}-objdump -x ${app_path}]"
          ${CROSS_COMPILE_PREFIX}-objdump -x ${app_path} | grep -i 'DLL Name' || true
        elif [ -f "${app_path}.exe" ]
        then
          run_verbose ls -l "${app_path}.exe"
          echo
          echo "[${CROSS_COMPILE_PREFIX}-objdump -x ${app_path}.exe]"
          ${CROSS_COMPILE_PREFIX}-objdump -x ${app_path}.exe | grep -i 'DLL Name' || true
        else
          echo
          echo "${app_path} "
        fi
      fi
    else
      echo "Oops! Unsupported TARGET_PLATFORM=${TARGET_PLATFORM}."
      exit 1
    fi
  )
}

function show_native_libs()
{
  # Does not include the .exe extension.
  local app_path=$1
  shift

  (
    echo
    echo "[readelf -d ${app_path} | egrep ...]"
    # Ignore errors in case it is not using shared libraries.
    set +e
    readelf_shared_libs "${app_path}"
    echo
    echo "[ldd -v ${app_path}]"
    ldd -v "${app_path}" || true
    set -e
  )
}

# -----------------------------------------------------------------------------

function compute_sha()
{
  # $1 shasum program
  # $2.. options
  # ${!#} file

  file=${!#}
  sha_file="${file}.sha"
  "$@" >"${sha_file}"
  echo "SHA: $(cat ${sha_file})"
}

# -----------------------------------------------------------------------------


# $1 - absolute path to input folder
# $2 - name of output folder below INSTALL_FOLDER
function copy_license()
{
  # Iterate all files in a folder and install some of them in the
  # destination folder
  (
    if [ -z "$2" ]
    then
      return
    fi

    echo
    echo "Copying license files for $2..."

    cd "$1"
    local f
    for f in *
    do
      if [ -f "$f" ]
      then
        if [[ "$f" =~ AUTHORS.*|NEWS.*|COPYING.*|README.*|LICENSE.*|Copyright.*|COPYRIGHT.*|FAQ.*|DEPENDENCIES.*|THANKS.*|CHANGES.* ]]
        then
          install -d -m 0755 \
            "${APP_PREFIX}/${DISTRO_INFO_NAME}/licenses/$2"
          install -v -c -m 644 "$f" \
            "${APP_PREFIX}/${DISTRO_INFO_NAME}/licenses/$2"
        fi
      elif [ -d "$f" ] && [[ "$f" =~ [Ll][Ii][Cc][Ee][Nn][Ss][Ee]* ]]
      then
        (
          cd "$f"
          local files=$(find . -type f)
          for file in ${files}
          do
            install -d -m 0755 \
              "${APP_PREFIX}/${DISTRO_INFO_NAME}/licenses/$2/$(dirname ${file})"
            install -v -c -m 644 "$file" \
              "${APP_PREFIX}/${DISTRO_INFO_NAME}/licenses/$2/$(dirname ${file})"
          done
        )
      fi
    done
  )
  (
    if [ "${TARGET_PLATFORM}" == "win32" ]
    then
      find "${APP_PREFIX}/${DISTRO_INFO_NAME}/licenses" \
        -type f \
        -exec unix2dos '{}' ';'
    fi
  )
}

function copy_build_files()
{
  echo
  echo "Copying build files..."

  (
    cd "${BUILD_GIT_PATH}"

    mkdir -pv patches

    # Ignore hidden folders/files (like .DS_Store).
    find scripts patches -type d ! -iname '.*' \
      -exec install -d -m 0755 \
        "${APP_PREFIX}/${DISTRO_INFO_NAME}"/'{}' ';'

    find scripts patches -type f ! -iname '.*' \
      -exec install -v -c -m 644 \
        '{}' "${APP_PREFIX}/${DISTRO_INFO_NAME}"/'{}' ';'

    if [ -f CHANGELOG.txt ]
    then
      install -v -c -m 644 \
          CHANGELOG.txt "${APP_PREFIX}/${DISTRO_INFO_NAME}"
    fi
    if [ -f CHANGELOG.md ]
    then
      install -v -c -m 644 \
          CHANGELOG.md "${APP_PREFIX}/${DISTRO_INFO_NAME}"
    fi
  )
}

# Must be called in the build folder, like
# cd "${LIBS_BUILD_FOLDER_PATH}"
# cd "${BUILD_FOLDER_PATH}"

function copy_cmake_logs()
{
  local folder_name="$1"

  echo
  echo "Preserving CMake log files..."
  rm -rf "${LOGS_FOLDER_PATH}/${folder_name}"
  mkdir -pv "${LOGS_FOLDER_PATH}/${folder_name}/CMakeFiles"

  (
    cd "${folder_name}"
    cp -v "CMakeCache.txt" "${LOGS_FOLDER_PATH}/${folder_name}"

    cp -v "CMakeFiles"/*.log "${LOGS_FOLDER_PATH}/${folder_name}/CMakeFiles"
  )
}


# Copy one folder to another
function copy_dir()
{
  local from_path="$1"
  local to_path="$2"

  set +u
  # rm -rf "${to_path}"
  mkdir -pv "${to_path}"

  (
    cd "${from_path}"
    if [ "${TARGET_PLATFORM}" == "darwin" ]
    then
      find . -xdev -print0 | cpio -oa0 | (cd "${to_path}" && cpio -im)
    else
      find . -xdev -print0 | cpio -oa0V | (cd "${to_path}" && cpio -imuV)
    fi
  )

  set -u
}

# Copy the build files to the Work area, to make them easily available.
function copy_build_git()
{
  if [ -d "${BUILD_GIT_PATH}" ]
  then
    chmod -R +w "${BUILD_GIT_PATH}"
    rm -rf "${BUILD_GIT_PATH}"
  fi
  mkdir -pv "${BUILD_GIT_PATH}"
  echo ${scripts_folder_path}
  cp -r "$(dirname ${scripts_folder_path})/scripts" "${BUILD_GIT_PATH}"
  rm -rf "${BUILD_GIT_PATH}/scripts/helper/.git"
  rm -rf "${BUILD_GIT_PATH}/scripts/helper/build-helper.sh"
}

# -----------------------------------------------------------------------------
