# =============================================================================
# Dotfiles bootstrap (~/.local/share/chezmoi/Makefile)
#
# 새 맥 셋업:
#   make all      # 전체 (apply + brew + macos)
#   make apply    # source → ~ 배포만
#   make brew     # Brewfile 만 다시 동기화
#   make macos    # 시스템 defaults 만 다시 적용
#
# 일상 운용 (설정 바꾼 뒤):
#   make status   # ~ 에서 바뀐 설정 미리보기 (읽기 전용)
#   make update   # ~ 의 변경을 source 로 흡수 (chezmoi re-add) + diff
#   make help     # 명령 목록
#
# 새 맥 첫 셋업 흐름: README §1~§2 → 그 후 `chezmoi cd && make all`
# =============================================================================

# 모든 target은 파일 산출물 아닌 작업 (PHONY)
.PHONY: help all check apply brew macos status update _need-chezmoi

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

# -----------------------------------------------------------------------------
# 일상 운용 — ~ 에서 손으로 바꾼 설정을 source 로 되담기 (apply 의 역방향)
#
#   설정(Sublime/VS Code/Xcode/plist…) 바꿈 → `make update` 한 방이면
#   레포에 다 반영됨. 파일마다 `chezmoi re-add <path>` 칠 필요 없음.
#
#   re-add = "이미 관리 중 + 변경된" 파일만 source 로 담는다:
#     · 템플릿(*.tmpl)·디렉터리·스크립트는 안 건드림         → 안전
#     · '새' 파일은 안 잡힘 → 최초 1회만 `chezmoi add <path>` 후 이후 update
#     · 휘발성 plist drift 가 섞일 수 있어 '커밋 전 diff 검토' 흐름으로 둠
# -----------------------------------------------------------------------------

# chezmoi 존재만 확인 (op/brew 까지 보는 check 보다 가벼움 — re-add/status 엔 충분)
_need-chezmoi:
	@command -v chezmoi >/dev/null 2>&1 || { echo "✗ chezmoi 없음 — brew install chezmoi"; exit 1; }

# 무엇이 어긋났는지 미리보기 — 아무것도 바꾸지 않음
status: _need-chezmoi ## ~ 에서 바뀐 설정 미리보기 (chezmoi status)
	@out="$$(chezmoi status)"; \
		if [ -z "$$out" ]; then \
			echo "✓ 변경 없음 — ~ 와 source 가 일치"; \
		else \
			echo "$$out"; \
			echo ""; \
			echo "  범례: 1열=~ 에서 변경(→ make update 대상) · 2열=source 에서 변경(→ make apply 대상)"; \
			echo "        M 수정 · A 추가 · D 삭제"; \
		fi

# ~ 의 변경을 source 로 흡수 후, 미커밋 변경을 보여줌 (커밋/push 는 직접)
update: _need-chezmoi ## ~ 의 변경을 source 로 흡수 (chezmoi re-add) + 변경 요약
	chezmoi re-add
	@src="$$(chezmoi source-path)"; \
		echo ""; \
		if [ -z "$$(git -C "$$src" status --porcelain)" ]; then \
			echo "✓ source 변경 없음 — 이미 최신 (re-add 가 새로 담은 것 없음)"; \
		else \
			echo "==> source 미커밋 변경 (git status):"; \
			git -C "$$src" status --short; \
			echo ""; \
			echo "   상세: chezmoi cd && git diff"; \
			echo "   커밋: chezmoi cd && git add -A && git commit && git push"; \
		fi

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
