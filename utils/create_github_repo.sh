#!/usr/bin/env bash
set -euo pipefail

# 사용법: ./create_github_repo.sh <repo-name> [--yes-delete]
# 예시: ./create_github_repo.sh my-project
# 예시: ./create_github_repo.sh my-project --yes-delete
# 출력: 원격 리포지토리 URL (stdout)
# 로그: 상태 메시지 (stderr)

PREFIX="remote_"
_REPO_NAME=""
_FORCE_DELETE="false"

# 인자 파싱
if [[ -z "${1:-}" ]] || [[ "$1" == --* ]]; then # 첫 번째 인자가 없거나 옵션이면 에러
  echo "❌ 사용법: $0 <repo-name> [--yes-delete]" >&2
  exit 1
fi
_REPO_NAME="$1"
shift # <repo-name> 소비

while (( "$#" )); do
  case "$1" in
    --yes-delete)
      _FORCE_DELETE="true"
      shift
      ;;
    *)
      echo "❌ 알 수 없는 옵션: $1" >&2
      echo "사용법: $0 <repo-name> [--yes-delete]" >&2
      exit 1
      ;;
  esac
done

FULL_NAME="${PREFIX}${_REPO_NAME}"

# GitHub 사용자 이름 조회
OWNER=$(gh api user --jq .login)

# 동일한 이름의 리포지토리 존재 여부 확인
if gh repo view "${OWNER}/${FULL_NAME}" &> /dev/null; then
  echo "✅ 기존 리포지토리가 존재합니다: ${OWNER}/${FULL_NAME}" >&2
  
  CONFIRM_ACTION="n" # 기본값 'n'
  if [[ "$_FORCE_DELETE" == "true" ]]; then
    CONFIRM_ACTION="y"
    echo "ℹ️ --yes-delete 플래그가 제공되어 자동으로 삭제를 진행합니다." >&2
  else
    # 예/아니오만 입력받기
    while true; do
      read -p "❓ 기존 리포지토리를 삭제하고 새로 생성하시겠습니까? (y/n) " USER_CONFIRM
      if [[ "$USER_CONFIRM" == "y" || "$USER_CONFIRM" == "n" ]]; then
        CONFIRM_ACTION="$USER_CONFIRM"
        break
      fi
      echo "❌ 'y' 또는 'n'만 입력해주세요." >&2
    done
  fi

  if [[ "$CONFIRM_ACTION" == "y" ]]; then
    gh repo delete "${OWNER}/${FULL_NAME}" --yes >&2
    echo "✅ 기존 리포지토리를 삭제했습니다." >&2
  else
    echo "ℹ️ 작업이 취소되었습니다. 기존 리포지토리를 사용합니다." >&2
    # 기존 리포지토리 URL 반환하고 종료
    EXISTING_URL=$(gh repo view "${OWNER}/${FULL_NAME}" --json url -q .url)
    echo "$EXISTING_URL"
    exit 0
  fi
fi

# 원격 리포지토리 생성
gh repo create "${OWNER}/${FULL_NAME}" --public --confirm >&2
URL=$(gh repo view "${OWNER}/${FULL_NAME}" --json url -q .url)
echo "✅ GitHub 원격 저장소 생성 완료: $URL" >&2

# stdout에 URL만 반환
echo "$URL"
