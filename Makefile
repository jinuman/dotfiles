# =============================================================================
# Dotfiles bootstrap (~/.local/share/chezmoi/Makefile)
#
# 사용:
#   make help     # 명령 목록
#   make all      # 전체 (apply + brew + macos)
#   make brew     # Brewfile 만 다시 동기화
#   make macos    # 시스템 defaults 만 다시 적용
#
# 새 맥 첫 셋업 흐름: README §1~§2 → 그 후 `chezmoi cd && make all`
# =============================================================================

# 모든 target은 파일 산출물 아닌 작업 (PHONY)
.PHONY: help all check apply brew macos

# 도움말 — 각 target 의 `##` 주석을 자동 파싱
help: ## 명령 목록 출력
	@awk -F':.*##' '/^[a-zA-Z_-]+:.*##/ {printf "  \033[36m%-8s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Sanity check — install.sh 가 하던 가드와 동일
check: ## 환경 sanity check (macOS / brew / chezmoi / op 사인인)
	@[ "$$(uname)" = "Darwin" ] || { echo "✗ macOS only"; exit 1; }
	@command -v brew    >/dev/null 2>&1 || { echo "✗ brew 없음 — README §2-1"; exit 1; }
	@command -v chezmoi >/dev/null 2>&1 || { echo "✗ chezmoi 없음 — brew install chezmoi"; exit 1; }
	@op whoami          >/dev/null 2>&1 || { echo "✗ op 미로그인 — eval \"\$$(op signin)\""; exit 1; }
	@echo "✓ sanity OK"

# chezmoi source → ~ 로 배포
apply: check ## chezmoi apply
	chezmoi apply

# Brewfile 의 모든 항목 설치 (mas 실패는 일부 허용)
brew: check ## brew bundle --file=bootstrap/Brewfile
	brew bundle --file=bootstrap/Brewfile \
		|| echo "  ! brew bundle 일부 실패 (보통 mas — README 트러블슈팅 참고)"

# 시스템 defaults + Caps Lock remap + LaunchAgent
macos: check ## bash bootstrap/macos.sh
	bash bootstrap/macos.sh

# 전체 — 새 맥에서 한 번에 진행할 때
all: apply brew macos ## apply + brew + macos
	@echo ""
	@echo "==> 완료. README §3 사후 수동 작업 참고."
	@echo "   주요: 앱 권한 부여 / Use Chrome 다이얼로그 / iCloud·Dropbox / 라이센스"
