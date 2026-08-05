# git worktree 헬퍼 함수
# 단축 alias (gst, gco, gcb ...) 는 oh-my-zsh git 플러그인 사용 (~/.zsh_plugins.txt)

# 새 워크트리 생성 + 이동 (사용법: gwa WOOTELIER-8150 [베이스브랜치])
# 베이스브랜치 생략 시 origin 기본 브랜치 자동 감지 (main/master 레포 모두 대응)
function gwa() {
  local ticket=$1 base=$2
  if [[ -z "$ticket" ]]; then
    echo "사용법: gwa <티켓/브랜치명> [베이스브랜치]"
    return 1
  fi
  # 다른 워크트리 안에서 실행해도 항상 메인 저장소의 형제 폴더에 생성
  local git_common
  git_common=$(git rev-parse --path-format=absolute --git-common-dir) || return 1
  local repo_root=${git_common:h}
  git fetch origin || return 1
  if [[ -z "$base" ]]; then
    git remote set-head origin --auto >/dev/null 2>&1
    base=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null) || base=origin/master
  fi
  git worktree add "${repo_root:h}/$ticket" -b "$ticket" "$base" \
    && cd "${repo_root:h}/$ticket"
}

# 워크트리 + 로컬 브랜치 삭제 (사용법: gwd WOOTELIER-8150)
function gwd() {
  local ticket=$1
  if [[ -z "$ticket" ]]; then
    echo "사용법: gwd <티켓/브랜치명>"
    return 1
  fi
  local git_common
  git_common=$(git rev-parse --path-format=absolute --git-common-dir) || return 1
  local repo_root=${git_common:h}
  local worktree_path=${repo_root:h}/$ticket
  # 지우려는 워크트리 안에 서 있으면 메인 저장소로 빠져나온 뒤 삭제
  [[ "$PWD/" == "$worktree_path/"* ]] && cd "$repo_root"
  git worktree remove "$worktree_path" || return 1
  git branch -d "$ticket" 2>/dev/null \
    || echo "브랜치 '$ticket' 미병합이라 남겨둠 — 강제 삭제: git branch -D $ticket"
}
