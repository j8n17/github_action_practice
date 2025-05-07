#!/usr/bin/env bash
set -euo pipefail

# 사용법 체크
if [ $# -ne 1 ]; then
  echo "Usage: $0 <folder_name>"
  exit 1
fi

base="$1"
dir="local_${base}"
base2="${base}2"
dir2="local_${base2}"

bash ./utils/setup_repos.sh "$base"

echo "--------------------------------"
cd "$dir2"
echo "4️⃣ 로컬 머지"
git fetch upstream
if ! git merge upstream/main; then
  echo "⚠️ 머지 실패: upstream/main 브랜치를 머지하는 중 충돌이 발생했을 수 있습니다."
else
  git push origin main
  echo "✅ 두 번째 저장소 동기화 완료"
fi
