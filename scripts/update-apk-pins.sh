#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/update-apk-pins.sh [--dry-run] [DOCKERFILE_PATH]

Update ARG APK_*_VERSION values used by apk add package=${APK_*_VERSION}.
By default, updates Dockerfile in place.

Options:
  -n, --dry-run  Show planned updates without writing files
  -h, --help     Show this help
EOF
}

dry_run=false
dockerfile_path="Dockerfile"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run)
      dry_run=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      dockerfile_path="$1"
      shift
      ;;
  esac
done

if [[ ! -f "${dockerfile_path}" ]]; then
  echo "Dockerfile not found: ${dockerfile_path}" >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker command is required" >&2
  exit 1
fi

base_image="$(
  awk '
    /^FROM[[:space:]]+/ {
      for (i = 2; i <= NF; i++) {
        if ($i ~ /^--platform=/) {
          continue
        }
        print $i
        exit
      }
    }
  ' "${dockerfile_path}"
)"

if [[ -z "${base_image}" ]]; then
  echo "Failed to detect base image from ${dockerfile_path}" >&2
  exit 1
fi

declare -A package_by_arg=()
declare -A old_version_by_arg=()
declare -A new_version_by_arg=()
declare -a args_in_order=()
declare -a packages=()

while IFS= read -r token; do
  if [[ "${token}" =~ ^([a-z0-9.+_-]+)=\$\{(APK_[A-Z0-9_]+_VERSION)\}$ ]]; then
    pkg="${BASH_REMATCH[1]}"
    arg_name="${BASH_REMATCH[2]}"
    if [[ -z "${package_by_arg[${arg_name}]+x}" ]]; then
      package_by_arg["${arg_name}"]="${pkg}"
      args_in_order+=("${arg_name}")
      packages+=("${pkg}")
    fi
  fi
done < <(grep -oE '[a-z0-9.+_-]+=\$\{APK_[A-Z0-9_]+_VERSION\}' "${dockerfile_path}")

if [[ "${#packages[@]}" -eq 0 ]]; then
  echo "No pinned APK variables found in ${dockerfile_path}" >&2
  exit 1
fi

while IFS= read -r line; do
  if [[ "${line}" =~ ^ARG[[:space:]]+(APK_[A-Z0-9_]+_VERSION)=([^[:space:]]+) ]]; then
    old_version_by_arg["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}"
  fi
done < "${dockerfile_path}"

resolved_packages="$(
  docker run --rm "${base_image}" sh -euc \
    "apk add --no-cache ${packages[*]} >/dev/null; for pkg in ${packages[*]}; do line=\$(apk search --exact --installed \"\$pkg\" | head -n1); [ -n \"\$line\" ] || { echo \"Failed to resolve \$pkg\" >&2; exit 1; }; echo \"\$pkg=\$line\"; done"
)"

for arg_name in "${args_in_order[@]}"; do
  pkg="${package_by_arg[${arg_name}]}"
  line="$(printf '%s\n' "${resolved_packages}" | awk -F= -v p="${pkg}" '$1 == p { print $2; exit }')"
  if [[ -z "${line}" ]]; then
    echo "Failed to resolve version for package: ${pkg}" >&2
    exit 1
  fi
  version="$(printf '%s\n' "${line}" | awk -F- '{for (i = 1; i <= NF; i++) {if ($i ~ /^[0-9]/) {printf "%s", $i; for (j = i + 1; j <= NF; j++) {printf "-%s", $j}; print ""; break}}}')"
  if [[ -z "${version}" ]]; then
    echo "Failed to parse version from installed package entry: ${line}" >&2
    exit 1
  fi
  new_version_by_arg["${arg_name}"]="${version}"
done

tmp_file="$(mktemp)"
mapping_file="$(mktemp)"
trap 'rm -f "${tmp_file}" "${mapping_file}"' EXIT

for arg_name in "${args_in_order[@]}"; do
  echo "${arg_name}=${new_version_by_arg[${arg_name}]}" >> "${mapping_file}"
done

awk -F= '
  NR == FNR {
    repl[$1] = $2
    next
  }
  {
    if (match($0, /^ARG[[:space:]]+(APK_[A-Z0-9_]+_VERSION)=([^[:space:]]+)/, m) && (m[1] in repl)) {
      print "ARG " m[1] "=" repl[m[1]]
    } else {
      print $0
    }
  }
' "${mapping_file}" "${dockerfile_path}" > "${tmp_file}"

if [[ "${dry_run}" == "false" ]]; then
  mv "${tmp_file}" "${dockerfile_path}"
fi

echo "Resolved APK pin versions from ${base_image}"
for arg_name in "${args_in_order[@]}"; do
  old_version="${old_version_by_arg[${arg_name}]:-(missing)}"
  new_version="${new_version_by_arg[${arg_name}]}"
  if [[ "${old_version}" == "${new_version}" ]]; then
    echo "  ${arg_name}: ${new_version} (unchanged)"
  else
    echo "  ${arg_name}: ${old_version} -> ${new_version}"
  fi
done

if [[ "${dry_run}" == "true" ]]; then
  echo "Dry-run mode: ${dockerfile_path} was not modified"
else
  echo "Updated APK pin versions in ${dockerfile_path}"
fi
