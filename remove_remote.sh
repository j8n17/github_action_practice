#!/usr/bin/env bash
set -euo pipefail

# 사용법: ./remove_remote.sh <repo-name> [--y]
# 예시: ./remove_remote.sh my-project
# 예시: ./remove_remote.sh my-project --y
# 로그: 상태 메시지 (stderr)

PREFIX="remote_"
_REPO_NAME=""
_FORCE_DELETE="false"

# 인자 파싱
if [[ -z "${1:-}" ]] || [[ "$1" == --* ]]; then # 첫 번째 인자가 없거나 옵션이면 에러
  echo "❌ 사용법: $0 <repo-name> [--y]" >&2
  exit 1
fi
_REPO_NAME="$1"
shift # <repo-name> 소비

while (( "$#" )); do
  case "$1" in
    --y)
      _FORCE_DELETE="true"
      shift
      ;;
    *)
      echo "❌ 알 수 없는 옵션: $1" >&2
      echo "사용법: $0 <repo-name> [--y]" >&2
      exit 1
      ;;
  esac
done

FULL_NAME_PRIMARY="${PREFIX}${_REPO_NAME}"
FULL_NAME_SECONDARY="${PREFIX}${_REPO_NAME}2"

# GitHub 사용자 이름 조회
OWNER=$(gh api user --jq .login)

# 함수: 리포지토리 삭제 로직
delete_repo() {
  local repo_full_name="$1"
  local force_delete_flag="$2"

  if ! gh repo view "${OWNER}/${repo_full_name}" &> /dev/null; then
    echo "ℹ️ 삭제할 리포지토리가 존재하지 않습니다: ${OWNER}/${repo_full_name}" >&2
    return 0 # 존재하지 않으면 성공으로 간주하고 다음으로 진행
  fi

  echo "✅ 삭제 대상 리포지토리를 찾았습니다: ${OWNER}/${repo_full_name}" >&2

  local confirm_action="n" # 기본값 'n'
  if [[ "$force_delete_flag" == "true" ]]; then
    confirm_action="y"
    echo "ℹ️ --y 플래그가 제공되어 '${OWNER}/${repo_full_name}' 리포지토리에 대한 자동 삭제를 진행합니다." >&2
  else
    # 예/아니오만 입력받기
    while true; do
      read -p "❓ 정말로 '${OWNER}/${repo_full_name}' 리포지토리를 삭제하시겠습니까? (y/n) " user_confirm
      if [[ "$user_confirm" == "y" || "$user_confirm" == "n" ]]; then
        confirm_action="$user_confirm"
        break
      fi
      echo "❌ 'y' 또는 'n'만 입력해주세요." >&2
    done
  fi

  if [[ "$confirm_action" == "y" ]]; then
    if gh repo delete "${OWNER}/${repo_full_name}" --yes >&2; then
      echo "✅ 리포지토리를 성공적으로 삭제했습니다: ${OWNER}/${repo_full_name}" >&2
    else
      echo "❌ 리포지토리 삭제에 실패했습니다: ${OWNER}/${repo_full_name}" >&2
      return 1 # 삭제 실패 시 오류 코드 반환
    fi
  else
    echo "ℹ️ '${OWNER}/${repo_full_name}' 리포지토리 삭제 작업이 취소되었습니다." >&2
  fi
  return 0
}

# 첫 번째 리포지토리 삭제 시도
delete_repo "$FULL_NAME_PRIMARY" "$_FORCE_DELETE"
DELETE_PRIMARY_EXIT_CODE=$?

# 두 번째 리포지토리 (이름 뒤에 2가 붙은) 삭제 시도
delete_repo "$FULL_NAME_SECONDARY" "$_FORCE_DELETE"
DELETE_SECONDARY_EXIT_CODE=$?

# 두 작업 중 하나라도 실패하면 스크립트 실패로 간주
if [[ "$DELETE_PRIMARY_EXIT_CODE" -ne 0 ]] || [[ "$DELETE_SECONDARY_EXIT_CODE" -ne 0 ]]; then
  exit 1
fi

exit 0
