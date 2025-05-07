#!/usr/bin/env bash
set -euo pipefail

# 사용법 체크
if [ $# -lt 1 ] || [ $# -gt 2 ]; then # 폴더 이름은 필수, --y는 선택
  echo "Usage: $0 <folder_name> [--y]" >&2
  exit 1
fi

base="$1"
RESET_REPOS_ARG=""
if [[ "${2:-}" == "--y" ]]; then
  RESET_REPOS_ARG="--yes-delete"
fi

dir="local_${base}"
base2="${base}2"
dir2="local_${base2}"

bash ./utils/setup_repos.sh "$base" $RESET_REPOS_ARG

echo "--------------------------------"
echo "4️⃣ 깃허브 액션"

bash ./utils/actions_setting.sh "$base"
