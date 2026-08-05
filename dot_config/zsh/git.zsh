# git worktree 헬퍼 함수
# 단축 alias (gst, gco, gcb ...) 는 oh-my-zsh git 플러그인 사용 (~/.zsh_plugins.txt)

# 메인 저장소 루트 (워크트리 안에서 실행해도 동일한 경로 반환)
function _git_main_root() {
  local git_common
  git_common=$(git rev-parse --path-format=absolute --git-common-dir) || return 1
  echo "${git_common:h}"
}

# 새 워크트리 생성 + 이동 (사용법: gwa WOOTELIER-8150 [베이스브랜치])
# 베이스브랜치 생략 시 origin 기본 브랜치 자동 감지 (main/master 레포 모두 대응)
function gwa() {
  local ticket=$1 base=$2
  if [[ -z "$ticket" ]]; then
    echo "사용법: gwa <티켓/브랜치명> [베이스브랜치]"
    return 1
  fi
  local repo_root
  repo_root=$(_git_main_root) || return 1
  git fetch origin || return 1
  if [[ -z "$base" ]]; then
    git remote set-head origin --auto >/dev/null 2>&1
    base=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null) || base=origin/master
  fi
  git worktree add "${repo_root:h}/$ticket" -b "$ticket" "$base" \
    && cd "${repo_root:h}/$ticket"
}

# MR 리뷰용 워크트리 (사용법: gwr WOOTELIER-7633 [포크 repo-url])
# GitLab "Check out branch" 스니펫의 워크트리 버전 — 내 체크아웃은 안 건드림.
#   같은 레포 MR:  gwr WOOTELIER-7633
#   포크 MR:      gwr WOOTELIER-7633 https://git.baemin.in/<동료>/ds-ios.git
function gwr() {
  local branch=$1 url=${2:-origin}
  if [[ -z "$branch" ]]; then
    echo "사용법: gwr <MR 브랜치명> [포크 repo-url (생략 시 origin)]"
    return 1
  fi
  local repo_root
  repo_root=$(_git_main_root) || return 1
  git fetch "$url" "$branch" || return 1
  # 로컬 브랜치는 review/ 접두사 — 같은 이름의 내 브랜치와 충돌 방지, gwd 가 던져도 되는 브랜치로 인식
  git worktree add "${repo_root:h}/review-${branch//\//-}" -b "review/$branch" FETCH_HEAD \
    && cd "${repo_root:h}/review-${branch//\//-}"
}

# 워크트리 + 로컬 브랜치 삭제 (사용법: gwd WOOTELIER-8150 / gwd review-WOOTELIER-7633)
function gwd() {
  local ticket=$1
  if [[ -z "$ticket" ]]; then
    echo "사용법: gwd <워크트리 폴더명>"
    return 1
  fi
  local repo_root
  repo_root=$(_git_main_root) || return 1
  local worktree_path=${repo_root:h}/$ticket
  # 폴더명과 브랜치명이 다를 수 있으니 (review-X ↔ review/X) 체크아웃된 브랜치를 직접 조회
  local branch
  branch=$(git -C "$worktree_path" branch --show-current 2>/dev/null)
  # 지우려는 워크트리 안에 서 있으면 메인 저장소로 빠져나온 뒤 삭제
  [[ "$PWD/" == "$worktree_path/"* ]] && cd "$repo_root"
  git worktree remove "$worktree_path" || return 1
  if [[ "$branch" == review/* ]]; then
    git branch -D "$branch"   # 리뷰 브랜치는 원본이 MR 에 있으므로 무조건 폐기
  elif [[ -n "$branch" ]]; then
    git branch -d "$branch" 2>/dev/null \
      || echo "브랜치 '$branch' 미병합이라 남겨둠 — 강제 삭제: git branch -D $branch"
  fi
}
