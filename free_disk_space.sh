#!/bin/bash
#
# Frees disk space on Ubuntu runners.

readonly RMZ_DOWNLOAD_URL='https://github.com/SUPERCILEX/fuc/releases/download/3.0.0/x86_64-unknown-linux-gnu-rmz'

function download_rmz() {
  local file
  file="$(mktemp -dq)"/rmz
  sudo curl -fsL --tlsv1.3 --proto =https -o "${file}" "${RMZ_DOWNLOAD_URL}" \
    && sudo install "${file}" /usr/bin/rmz
}

function command_setup() {
  local command="$1"

  # Default to using rmz.
  function remove_dir() {
    sudo rmz "$1" || true
  }

  case "${command}" in
    rsync)
      function remove_dir() {
        sudo rsync --delete -r "$(mktemp -dq)"/ "$1" && sudo rmdir "$1" || true
      }
      ;;
    find)
      function remove_dir() {
        sudo find "$1" -delete || true
      }
      ;;
    rm)
      function remove_dir() {
        sudo rm -r "$1" || true
      }
      ;;
    *)
      if ! download_rmz; then
        echo '::error::Failed to download rmz, falling back to rm'
        function remove_dir() {
          sudo rm -r "$1" || true
        }
      fi
  esac
}

function haskell() {
  remove_dir "${GHCUP_INSTALL_BASE_PREFIX}"/.ghcup
}

function android_sdk() {
  remove_dir "${ANDROID_SDK_ROOT}"
}

function tool_cache() {
  remove_dir "${AGENT_TOOLSDIRECTORY}"
}

# Gets the amount of free space in bytes.
function get_free_space() {
  df -B 1 --output=avail / | tail -1
}

function format_bytes() {
  numfmt --to=iec-i --suffix=B "$1"
}

function format_seconds() {
  local time="$1"
  local minutes="$(( time / 60 % 60 ))"
  local seconds="$(( time % 60 ))"

  (( seconds == 0 )) && (( minutes == 0 )) && echo '0s'
  (( minutes > 0 )) && printf '%dm' "${minutes}"
  (( seconds > 0 )) && (( minutes > 0 )) && printf ' '
  (( seconds > 0 )) && printf '%ds\n' "${seconds}"
}

function remove() {
  local operation="$1"
  local title="$2"
  local before
  before="$(get_free_space)"

  SECONDS=0
  $operation
  local time="${SECONDS}"

  local after
  after="$(get_free_space)"

  local freed="$(( after - before ))"
  printf "${title}: Freed %s in %s\n" \
    "$(format_bytes "${freed}")" "$(format_seconds "${time}")"
}

function main() {
  echo '::group::Freeing disk space'

  command_setup "${INPUT_COMMAND}"

  local free_space_before
  free_space_before="$(get_free_space)"
  echo "Free space before: $(format_bytes "${free_space_before}")"

  if [[ "${INPUT_HASKELL}" == 'true' ]]; then
    remove haskell 'Haskell'
  fi

  if [[ "${INPUT_ANDROID_SDK}" == 'true' ]]; then
    remove android_sdk 'Android SDK'
  fi

  if [[ "${INPUT_TOOL_CACHE}" == 'true' ]]; then
    remove tool_cache 'Tool cache'
  fi

  local free_space_after
  free_space_after="$(get_free_space)"
  echo "Free space after: $(format_bytes "${free_space_after}")"

  local total_space_freed="$(( free_space_after - free_space_before ))"
  echo "Total space freed: $(format_bytes "${total_space_freed}")"

  echo '::endgroup::'
}

main "$@"
