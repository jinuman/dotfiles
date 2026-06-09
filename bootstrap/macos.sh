#!/usr/bin/env bash
# =============================================================================
# macos.sh — fire-and-forget 시스템 defaults
#
# 원칙 — 여기엔 다음 둘 다 만족하는 것만 넣는다:
#   (1) macOS 업데이트로 안 깨짐   (2) side-effect 없음 (보안/동작 변경 X)
# 그래서 키보드 단축키(symbolichotkeys), Trackpad gestures 처럼 update 때
# reset 되거나 UI 확인이 필요한 건 README §3 수동 체크리스트로 뺀다.
# (Finder 태그는 둘 다 아님 — iCloud 가 Mac 간 동기화.)
# 예외: Caps Lock→Control 은 hidutil+LaunchAgent 라 System Settings 방식보다
#       오히려 update-robust → 여기 유지.
#
# 멱등성 있음 — 여러 번 돌려도 안전.
# 일부 설정은 logout/재부팅 후 완전히 반영됨 (스크립트 끝에서 daemon 재시작).
# =============================================================================
set -euo pipefail

echo "==> Applying macOS system defaults…"

# sudo 미리 인증받고 백그라운드로 유지
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# System Settings 가 열려있으면 끄기
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true


# -----------------------------------------------------------------------------
# General UI / UX
# -----------------------------------------------------------------------------
defaults write NSGlobalDomain AppleShowAllExtensions -bool true              # 파일 확장자 항상 보이기
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false   # 자동 맞춤법 끔
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false    # 스마트 따옴표 끔
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false     # 스마트 대시 끔


# -----------------------------------------------------------------------------
# Keyboard — repeat 속도 + Caps Lock → Control
# -----------------------------------------------------------------------------
defaults write NSGlobalDomain KeyRepeat -int 2                # 값 작을수록 빠름
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false   # accent picker 끔 → key repeat 동작

# Caps Lock → Control: hidutil 로 OS-level remap (모든 키보드에 즉시 적용)
HIDUTIL_MAP='{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0}]}'
hidutil property --set "$HIDUTIL_MAP" >/dev/null

# 재부팅 후에도 유지되도록 LaunchAgent 등록
CAPS_PLIST="$HOME/Library/LaunchAgents/local.capslock-to-control.plist"
mkdir -p "$(dirname "$CAPS_PLIST")"
cat > "$CAPS_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>local.capslock-to-control</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/hidutil</string>
        <string>property</string>
        <string>--set</string>
        <string>$HIDUTIL_MAP</string>
    </array>
    <key>RunAtLoad</key><true/>
</dict>
</plist>
EOF
launchctl unload "$CAPS_PLIST" 2>/dev/null || true
launchctl load "$CAPS_PLIST"


# -----------------------------------------------------------------------------
# Trackpad / Mouse — 커서 속도만 (gesture 들은 README §3 의 수동 체크리스트)
# -----------------------------------------------------------------------------
defaults write -g com.apple.trackpad.scaling -float 2.0      # 트랙패드 커서 속도
defaults write -g com.apple.mouse.scaling -float 2.5         # 마우스 커서 속도


# -----------------------------------------------------------------------------
# Finder
# -----------------------------------------------------------------------------
defaults write com.apple.finder AppleShowAllFiles -bool true             # 숨김 파일 보이기
defaults write com.apple.finder ShowPathbar -bool true                   # 경로 표시줄
defaults write com.apple.finder ShowStatusBar -bool true                 # 상태 표시줄
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true       # 타이틀에 전체 경로
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"      # 기본 리스트 뷰
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true   # 네트워크 .DS_Store 안 만들기
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true       # USB .DS_Store 안 만들기
chflags nohidden ~/Library || true                                       # ~/Library 보이게


# -----------------------------------------------------------------------------
# Dock (System Settings → Desktop & Dock → Dock)
# -----------------------------------------------------------------------------
defaults write com.apple.dock tilesize -int 36                           # Size: Small (기본 64)
defaults write com.apple.dock magnification -bool true                   # Magnification 켬
defaults write com.apple.dock largesize -int 64                          # Magnification 시 최대 크기
defaults write com.apple.dock orientation -string "bottom"               # Dock 위치
defaults write com.apple.dock mineffect -string "genie"                  # 최소화 애니메이션: Genie
defaults write NSGlobalDomain AppleActionOnDoubleClick -string "Maximize"  # 타이틀바 더블클릭 = Zoom
defaults write com.apple.dock minimize-to-application -bool false        # 앱 아이콘으로 최소화 끔
defaults write com.apple.dock autohide -bool false                       # 자동 숨김 끔
defaults write com.apple.dock launchanim -bool true                      # 앱 실행 애니메이션 켬
defaults write com.apple.dock show-process-indicators -bool true         # 실행 중 인디케이터 표시
defaults write com.apple.dock show-recents -bool false                   # Suggested/recent apps 숨김
# Hot Corners 끄기
for corner in wvous-tl-corner wvous-tr-corner wvous-bl-corner wvous-br-corner; do
  defaults write com.apple.dock "$corner" -int 0
done


# -----------------------------------------------------------------------------
# Mission Control (System Settings → Desktop & Dock → Mission Control)
# -----------------------------------------------------------------------------
defaults write com.apple.dock mru-spaces -bool false                     # Spaces 자동 재배치 끔
defaults write NSGlobalDomain AppleSpacesSwitchOnActivate -bool true     # 앱 전환 시 그 앱의 Space 로 따라가기 ON
                                                                          # (false 면 KM/Raycast/⌘Tab 으로 cross-space 포커싱 X)
defaults write com.apple.dock expose-group-apps -bool false              # 앱별 그룹화 끔
defaults write com.apple.spaces spans-displays -bool false               # Displays have separate Spaces: ON


# -----------------------------------------------------------------------------
# Screenshots — ~/Pictures/Screenshots 로 모으기
# -----------------------------------------------------------------------------
mkdir -p "${HOME}/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Pictures/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true


# -----------------------------------------------------------------------------
# Activity Monitor — All Processes 뷰 + Dock 아이콘에 CPU 그래프
# -----------------------------------------------------------------------------
defaults write com.apple.ActivityMonitor ShowCategory -int 0
defaults write com.apple.ActivityMonitor IconType -int 5


# -----------------------------------------------------------------------------
# 변경 사항 일부 즉시 반영을 위해 관련 daemon/앱 재시작
# -----------------------------------------------------------------------------
for app in "Activity Monitor" "Dock" "Finder" "SystemUIServer" "cfprefsd"; do
  killall "$app" >/dev/null 2>&1 || true
done


cat <<'EOF'

==> macos.sh 완료. 자동화 영역 끝.

이제 README §3 사후 수동 작업 체크리스트로 넘어가세요:
  - 앱 권한 부여
  - 키보드 단축키 (Spotlight, 한/영, Mission Control)
  - Trackpad gestures
  - Desktop & Stage Manager, Window tiling 토글
  - 기본 브라우저 → Chrome
  - 앱 로그인 + 라이센스 입력

EOF
