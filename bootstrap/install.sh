#!/usr/bin/env bash
# 사전 수동 단계 (Xcode CLT, 1Password 로그인, brew/chezmoi/op signin,
# chezmoi init --apply) 가 끝난 뒤에 실행. 자세한 순서는 README §1~§2.
#
# 멱등성 있음 — Brewfile / macos.sh 수정 후 재실행 OK.
set -euo pipefail

cd ~/.local/share/chezmoi 2>/dev/null \
  || { echo "✗ chezmoi source 없음 — README §2 부트스트랩 먼저"; exit 1; }

# Sanity checks ----------------------------------------------------------------
[[ "$(uname)" == "Darwin" ]]  || { echo "✗ macOS only"; exit 1; }
command -v brew    >/dev/null || { echo "✗ brew 없음 — README §2 참고"; exit 1; }
command -v chezmoi >/dev/null || { echo "✗ chezmoi 없음 — brew install chezmoi"; exit 1; }
op whoami >/dev/null 2>&1     || { echo "✗ op 미로그인 — eval \"\$(op signin)\""; exit 1; }
ssh -o BatchMode=yes -T git@github.com 2>&1 | grep -q "successfully authenticated" \
                              || { echo "✗ GitHub SSH 안 됨 — 1Password SSH agent 토글 확인"; exit 1; }

# Re-apply dotfiles (repo가 init 이후 갱신됐을 수 있음) ------------------------
echo "==> chezmoi apply"
chezmoi apply

# Brewfile (10~20분, mas 실패는 일부 허용) ------------------------------------
echo "==> brew bundle"
brew bundle --file=bootstrap/Brewfile \
  || echo "  ! brew bundle 일부 실패 (보통 mas — README 트러블슈팅 참고)"

# 시스템 defaults + Caps Lock remap + LaunchAgent -----------------------------
echo "==> macos.sh"
bash bootstrap/macos.sh

cat <<'EOF'

==> 완료. 다음 단계는 README §3 "사후 수동 작업".
주요: 앱 권한 부여 / "Use Chrome" 다이얼로그 / iCloud·Dropbox 로그인 / 라이센스 입력
EOF
