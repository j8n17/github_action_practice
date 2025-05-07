#!/usr/bin/env bash
set -euo pipefail

base="$1"
dir="local_${base}"
base2="${base}2"
dir2="local_${base2}"

# GitHub 사용자 이름 조회
OWNER=$(gh api user --jq .login)
UPSTREAM_REPO_OWNER="$OWNER"

UPSTREAM_REPO_NAME="remote_${base}"
REPO_NAME="remote_${base2}"

echo "OWNER: $OWNER"
echo "REPO_NAME: $REPO_NAME"
echo "UPSTREAM_REPO_OWNER: $UPSTREAM_REPO_OWNER"
echo "UPSTREAM_REPO_NAME: $UPSTREAM_REPO_NAME"

# 리포지토리 변수 UPSTREAM_REPO_NAME 설정
gh variable set UPSTREAM_REPO_NAME \
  --repo "${OWNER}/${REPO_NAME}" \
  --body "$UPSTREAM_REPO_NAME"

# (선택) UPSTREAM_REPO_OWNER 설정 (current repo owner와 다를 때만)
gh variable set UPSTREAM_REPO_OWNER \
  --repo "${OWNER}/${REPO_NAME}" \
  --body "$UPSTREAM_REPO_OWNER"

# GitHub Actions 권한 설정
gh api \
  --silent \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  -F "default_workflow_permissions=read" \
  -F "can_approve_pull_request_reviews=true" \
  /repos/${OWNER}/${REPO_NAME}/actions/permissions/workflow

# .github/workflows 디렉토리 생성
mkdir -p "$dir2/.github/workflows"

# sync_upstream.yml 파일 복사
cp "$(dirname "$0")/sync_upstream.yml" "$dir2/.github/workflows/"

# 변경사항 커밋 및 푸시
cd "$dir2"
git add .github/workflows/sync_upstream.yml
git commit -m "Add sync_upstream workflow"
git push origin main

echo "✅ sync_upstream.yml workflow 추가 완료"
