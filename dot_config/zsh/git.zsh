# git worktree 헬퍼 함수
# 단축 alias (gst, gco, gcb ...) 는 oh-my-zsh git 플러그인 사용 (~/.zsh_plugins.txt)

# 메인 저장소 루트 (워크트리 안에서 실행해도 동일한 경로 반환)
function _git_main_root() {
  local git_common
  git_common=$(git rev-parse --path-format=absolute --git-common-dir) || return 1
  echo "${git_common:h}"
}

# 새 워크트리 생성 + 이동 (사용법: gwa WOOTELIER-8356)
# 현재 브랜치(HEAD)에서 <티켓> 브랜치를 따서 <레포명>-<티켓> 형제 폴더에 생성
#   예: ds-ios 의 release 에서 gwa WOOTELIER-8356
#       → ../ds-ios-WOOTELIER-8356 폴더, WOOTELIER-8356 브랜치 (로컬 release 기반)
function gwa() {
  local ticket=$1
  if [[ -z "$ticket" ]]; then
    echo "사용법: gwa <티켓/브랜치명>"
    return 1
  fi
  local repo_root
  repo_root=$(_git_main_root) || return 1
  git worktree add "$repo_root-$ticket" -b "$ticket" || return 1
  cd "$repo_root-$ticket" || return 1
  # 내 브랜치에서 딴 것이므로 mise 설정 자동 신뢰
  command -v mise >/dev/null 2>&1 && mise trust >/dev/null 2>&1
  return 0
}

# 워크트리 + 로컬 브랜치 삭제 (사용법: gwd WOOTELIER-8356)
function gwd() {
  local ticket=$1
  if [[ -z "$ticket" ]]; then
    echo "사용법: gwd <티켓/브랜치명>"
    return 1
  fi
  local repo_root
  repo_root=$(_git_main_root) || return 1
  local worktree_path=$repo_root-$ticket
  # 폴더명을 통째로 넘겨도 동작 (gwd ds-ios-WOOTELIER-8356 / 예전 레이아웃 ../WOOTELIER-8356)
  [[ ! -d "$worktree_path" && -d "${repo_root:h}/$ticket" ]] && worktree_path=${repo_root:h}/$ticket
  # 폴더명과 브랜치명이 다를 수 있으니 체크아웃된 브랜치를 직접 조회
  local branch
  branch=$(git -C "$worktree_path" branch --show-current 2>/dev/null)
  # 지우려는 워크트리 안에 서 있으면 메인 저장소로 빠져나온 뒤 삭제
  [[ "$PWD/" == "$worktree_path/"* ]] && cd "$repo_root"
  git worktree remove "$worktree_path" || return 1
  if [[ -n "$branch" ]]; then
    git branch -d "$branch" 2>/dev/null \
      || echo "브랜치 '$branch' 미병합이라 남겨둠 — 강제 삭제: git branch -D $branch"
  fi
}
