#!/usr/bin/env bash
set -euo pipefail

# 사용법 체크
if [ $# -lt 1 ] || [ $# -gt 2 ]; then # 폴더 이름은 필수, --yes-delete는 선택
  echo "Usage: $0 <folder_name> [--yes-delete]" >&2
  exit 1
fi

parent_dir="$(dirname "$0")"
base="$1"
YES_DELETE_ARG=""
if [[ "${2:-}" == "--yes-delete" ]]; then
  YES_DELETE_ARG="--yes-delete"
fi

# 1. 첫 번째 저장소
# 1-1. 기존 디렉토리가 있으면 삭제
echo "1️⃣  첫 번째 저장소"
dir="local_${base}"
if [ -d "$dir" ]; then
  rm -rf "$dir"
  echo "✅ 기존 '$dir' 폴더 삭제 완료"
fi
# 1-2. 디렉토리 생성 및 파일 작성
mkdir -p "$dir"
echo "line1" > "$dir/${base}.txt"
echo "✅ ${dir}/${base}.txt 생성 완료"
# 1-3. Git 초기화, add, commit
cd "$dir"
git init
git add "${base}.txt"
git commit -m "Initial commit: add ${base}.txt with line1"
echo "✅ Git 저장소 초기화 및 첫 커밋 완료"
# 1-4. 원격 GitHub 저장소 생성
cd ..
remote_url="$(bash "$parent_dir/create_github_repo.sh" "$base" $YES_DELETE_ARG).git"
echo "✅ 원격 저장소 URL: $remote_url"
# 1-5. 원격 저장소 연결 및 push
cd "$dir"
git remote add origin "$remote_url"
git branch -M main
git push -u origin main
echo "✅ 원격 저장소에 초기 커밋 푸시 완료"

# 2. 두 번째 저장소
# 2-1. 원격 저장소 클론
echo "--------------------------------"
echo "2️⃣ 두 번째 저장소"
cd ..
base2="${base}2"
dir2="local_${base2}"
if [ -d "$dir2" ]; then
    rm -rf "$dir2"
    echo "✅ 기존 '$dir2' 폴더 삭제 완료"
fi
git clone "$remote_url" "$dir2"
echo "✅ '$remote_url' 저장소를 '$dir2'으로 클론 완료"

# 2-2. 두 번째 원격 GitHub 저장소 생성
remote_url_2="$(bash "$parent_dir/create_github_repo.sh" "${base2}" $YES_DELETE_ARG).git"
echo "✅ 두 번째 원격 저장소 URL: $remote_url_2"

# 2-3. 기존 origin을 upstream으로 변경
cd "$dir2"
git remote rename origin upstream
echo "✅ 기존 'origin' 원격 저장소를 'upstream'으로 이름 변경 완료"

# 2-4. 두 번째 원격 저장소를 origin으로 추가
git remote add origin "$remote_url_2"
echo "✅ 클론된 저장소에 두 번째 원격 저장소를 'origin'으로 추가 완료"

# 2-5. 설정된 원격 저장소 확인
git remote -v

# 2-6. 두 저장소 동기화
git fetch upstream
git merge upstream/main
git push origin main

echo "✅ 모든 설정 완료"

# 3. 첫 번째 저장소 변경
echo "--------------------------------"
echo "3️⃣ 파일 수정"
# 3-1. 첫 번째 저장소에서 파일 수정
cd "../$dir"
echo "line2" >> "${base}.txt"
git add "${base}.txt"
git commit -m "Update ${base}.txt with line2"
echo "✅ 첫 번째 저장소에서 파일 수정 완료"

# 3-2. 첫 번째 저장소에서 파일 수정 후 푸시
git push origin main
echo "✅ 첫 번째 저장소에서 파일 수정 후 푸시 완료"

# 3-3. 두 번째 저장소에서 파일 수정
cd "../$dir2"
echo "line3" >> "${base}.txt"
git add "${base}.txt"
git commit -m "Update ${base}.txt with line3"
echo "✅ 두 번째 저장소에서 파일 수정 완료"
