#!/usr/bin/env bash
# =============================================================================
# macos.sh — system defaults for a fresh Mac (선언적 시스템 설정)
#
# 동작 원리:
#   - `defaults write` : ~/Library/Preferences/*.plist 의 키/값을 쓴다.
#                        System Settings에서 토글을 눌러 바뀌는 값과 동일.
#   - `hidutil`        : 키보드 modifier remapping (Caps Lock → Control 등)
#   - LaunchAgent      : 부팅 시 hidutil 자동 적용 (재부팅 후에도 유지)
#
# 멱등성 있음 — 여러 번 돌려도 안전.
# 일부 설정은 logout/재부팅 후 완전히 반영됨 (스크립트 끝에서 daemon 재시작 시도).
# =============================================================================
set -euo pipefail

echo "==> Applying macOS system defaults…"

# sudo 미리 인증받고 백그라운드로 유지 (스크립트 동안 비밀번호 다시 안 물음)
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# System Settings 가 열려있으면 끄기 (안 그러면 우리 변경을 덮어쓸 수 있음)
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true


# -----------------------------------------------------------------------------
# General UI / UX
# -----------------------------------------------------------------------------
# 파일명 확장자 항상 보이기
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# 인터넷에서 받은 앱 첫 실행 시 "정말 열까요?" 다이얼로그 끄기
defaults write com.apple.LaunchServices LSQuarantine -bool false
# 자동 맞춤법 / 스마트 따옴표 / 스마트 대시 끄기 (코드/한국어 편집에 방해됨)
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false


# -----------------------------------------------------------------------------
# Keyboard — repeat 속도 + Caps Lock → Control
# -----------------------------------------------------------------------------
# Key repeat 속도 (값 작을수록 빠름). vim/터미널 작업에 큰 차이.
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
# 길게 누를 때 accent picker 끄기 → 길게 누르면 key repeat 동작
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Caps Lock → Control: hidutil 로 OS-level remap (모든 키보드에 즉시 적용)
# 0x700000039 = Caps Lock 의 HID usage code, 0x7000000E0 = Left Control
HIDUTIL_MAP='{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0}]}'
hidutil property --set "$HIDUTIL_MAP" >/dev/null

# 재부팅 후에도 유지되도록 LaunchAgent 등록 (매 login 시 hidutil 자동 실행)
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
# Keyboard Shortcuts (System Settings → Keyboard → Keyboard Shortcuts)
#
# symbolichotkeys.plist 의 각 단축키는 정해진 ID 로 식별됨.
# 헬퍼 함수 인자: ID, ENABLED(true/false), CHAR(ASCII), KEYCODE, MODIFIERS
# Modifier 값 (조합은 합산):
#   Cmd     = 1048576
#   Opt     =  524288
#   Ctrl    =  262144
#   Shift   =  131072
# 예) Opt+Cmd = 1572864
# 키코드 참고: Space=49, d=2, 1~5 → 18,19,20,21,23 (5만 22가 아닌 23)
# -----------------------------------------------------------------------------
set_shortcut() {
  local id=$1 enabled=$2 char=$3 keycode=$4 mods=$5
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$id" \
    "{enabled = $enabled; value = { parameters = ($char, $keycode, $mods); type = 'standard'; };}"
}

# Spotlight (ID 64): ⌘Space → ⌥Space
set_shortcut 64 true 32 49 524288
# Show Finder search window (ID 65): ⌥⌘Space (기본값과 동일하지만 명시)
set_shortcut 65 true 32 49 1572864
# Select previous input source (ID 60): 한/영 = ⌘Space
set_shortcut 60 true 32 49 1048576
# Show Desktop (ID 36): ⌥D
set_shortcut 36 true 100 2 524288
# Switch to Desktop 1~5 (ID 118~122): ⌃1 ~ ⌃5
set_shortcut 118 true 49 18 262144
set_shortcut 119 true 50 19 262144
set_shortcut 120 true 51 20 262144
set_shortcut 121 true 52 21 262144
set_shortcut 122 true 53 23 262144


# -----------------------------------------------------------------------------
# Trackpad — built-in 과 Magic Trackpad 양쪽 도메인에 동일 설정 필요
#   com.apple.AppleMultitouchTrackpad            ← built-in trackpad
#   com.apple.driver.AppleBluetoothMultitouch.trackpad ← Magic Trackpad
# Gesture 값 의미: 0 = off, 2 = 손가락 수에 따른 해당 동작 활성
# -----------------------------------------------------------------------------
# 포인터 / 마우스 속도
defaults write -g com.apple.trackpad.scaling -float 2.0
defaults write -g com.apple.mouse.scaling -float 2.5

# Tap to click
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Look up & data detectors: 세 손가락 탭
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerTapGesture -int 2

# 네 손가락 가로 swipe: 전체화면 앱 전환 (3 fingers 가로는 끔 → 3-finger drag 와 안 겹치게)
defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerHorizSwipeGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerHorizSwipeGesture -int 2
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerHorizSwipeGesture -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerHorizSwipeGesture -int 0

# 네 손가락 세로 swipe: Mission Control (3 fingers 세로도 끔)
defaults write com.apple.AppleMultitouchTrackpad TrackpadFourFingerVertSwipeGesture -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadFourFingerVertSwipeGesture -int 2
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerVertSwipeGesture -int 0
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerVertSwipeGesture -int 0

# 세 손가락 드래그 (Accessibility → Pointer Control → Trackpad Options)
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true


# -----------------------------------------------------------------------------
# Finder
# -----------------------------------------------------------------------------
defaults write com.apple.finder AppleShowAllFiles -bool true             # 숨김 파일 보이기
defaults write com.apple.finder ShowPathbar -bool true                   # 경로 표시줄
defaults write com.apple.finder ShowStatusBar -bool true                 # 상태 표시줄
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true       # 타이틀에 전체 경로
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"      # 기본 리스트 뷰
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true  # 네트워크 .DS_Store 안 만들기
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true      # USB .DS_Store 안 만들기
chflags nohidden ~/Library || true                                       # ~/Library 보이게


# -----------------------------------------------------------------------------
# Dock (System Settings → Desktop & Dock → Dock)
# -----------------------------------------------------------------------------
defaults write com.apple.dock tilesize -int 36                           # Size: Small (기본 64)
defaults write com.apple.dock magnification -bool true                   # Magnification 켬
defaults write com.apple.dock largesize -int 64                          # Magnification 시 최대 크기 (Small)
defaults write com.apple.dock orientation -string "bottom"               # Dock 위치
defaults write com.apple.dock mineffect -string "genie"                  # 최소화 애니메이션: Genie
defaults write NSGlobalDomain AppleActionOnDoubleClick -string "Maximize" # 타이틀바 더블클릭 = Zoom
defaults write com.apple.dock minimize-to-application -bool false        # 앱 아이콘으로 최소화 끔
defaults write com.apple.dock autohide -bool false                       # 자동 숨김 끔 (항상 보임)
defaults write com.apple.dock launchanim -bool true                      # 앱 실행 애니메이션 켬
defaults write com.apple.dock show-process-indicators -bool true         # 실행 중 인디케이터 표시
defaults write com.apple.dock show-recents -bool false                   # Suggested/recent apps 숨김
# Hot Corners 끄기 (실수로 트리거 방지)
for corner in wvous-tl-corner wvous-tr-corner wvous-bl-corner wvous-br-corner; do
  defaults write com.apple.dock "$corner" -int 0
done


# -----------------------------------------------------------------------------
# Desktop & Stage Manager (System Settings → Desktop & Dock → Desktop & Stage Manager)
# 키 이름이 macOS 버전마다 약간 다름. Sonoma/Sequoia 기준.
# -----------------------------------------------------------------------------
# Click wallpaper to show desktop: Always (기본 "Only in Stage Manager")
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool true
# Stage Manager 자체는 끔
defaults write com.apple.WindowManager GloballyEnabled -bool false
# Stage Manager에서 recent apps 보이기 (Stage Manager 켰을 때만 효과)
defaults write com.apple.WindowManager AutoHide -bool false


# -----------------------------------------------------------------------------
# Windows (System Settings → Desktop & Dock → Windows)
# -----------------------------------------------------------------------------
defaults write NSGlobalDomain AppleWindowTabbingMode -string "fullscreen"   # Prefer tabs: In Full Screen
defaults write NSGlobalDomain NSCloseAlwaysConfirmsChanges -bool false      # Ask to keep changes: OFF
defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool true           # Close windows when quitting: OFF
                                                                            # (true = 윈도우 유지 = UI 토글 OFF 의미)
# Sequoia(15.x) window tiling 기능들 — 다 끔
defaults write com.apple.WindowManager EnableTilingByEdgeDrag -bool false
defaults write com.apple.WindowManager EnableTopTilingByEdgeDrag -bool false
defaults write com.apple.WindowManager EnableTilingOptionAccelerator -bool false
defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false


# -----------------------------------------------------------------------------
# Mission Control (System Settings → Desktop & Dock → Mission Control)
# -----------------------------------------------------------------------------
defaults write com.apple.dock mru-spaces -bool false                        # Spaces 자동 재배치 끔
defaults write NSGlobalDomain AppleSpacesSwitchOnActivate -bool false       # 앱 전환 시 Space 따라가기 끔
defaults write com.apple.dock expose-group-apps -bool false                 # 앱별 그룹화 끔
defaults write com.apple.spaces spans-displays -bool false                  # Displays have separate Spaces: ON
                                                                            # (spans-displays=false 가 "분리된 Spaces" 의미)


# -----------------------------------------------------------------------------
# Screenshots — Desktop 안 어지럽게 ~/Pictures/Screenshots 로 모음
# -----------------------------------------------------------------------------
mkdir -p "${HOME}/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Pictures/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true


# -----------------------------------------------------------------------------
# Safari — 의도적으로 제외
#
# Safari는 macOS Mojave부터 sandboxed 앱이라 prefs 가
# ~/Library/Containers/com.apple.Safari/Data/Library/Preferences/com.apple.Safari.plist
# 에 있고, 여기 쓰려면 실행 중인 터미널 앱(WezTerm 등)이 System Settings →
# Privacy & Security → Full Disk Access 권한을 가지고 있어야 함.
#
# 기본 브라우저 Chrome 쓰니까 굳이 Safari dev menu 자동화는 가치 낮음.
# 필요해지면 Safari 직접 열어서 Settings → Advanced → "Show features for web developers" 체크.
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Activity Monitor — All Processes 뷰 + Dock 아이콘에 CPU 그래프
# -----------------------------------------------------------------------------
defaults write com.apple.ActivityMonitor ShowCategory -int 0
defaults write com.apple.ActivityMonitor IconType -int 5


# -----------------------------------------------------------------------------
# Default browser → Chrome
#
# 전제: Brewfile의 `defaultbrowser` 와 `google-chrome` 둘 다 설치되어 있어야 함.
# 동작: LaunchServices API 호출 → macOS가 확인 다이얼로그를 띄움.
#       사용자가 "Use 'Google Chrome'" 클릭해야 실제 적용 (Apple 보안 정책,
#       악성 앱의 몰래 변경 방지 목적이라 우회 불가).
# -----------------------------------------------------------------------------
if command -v defaultbrowser >/dev/null 2>&1; then
  defaultbrowser chrome || true
else
  echo "  ! defaultbrowser 미설치 — brew bundle 먼저 실행 필요"
fi


# -----------------------------------------------------------------------------
# 변경 사항 일부 즉시 반영을 위해 관련 daemon/앱 재시작
# (단축키, trackpad 설정 등은 logout/재부팅이 필요할 수 있음)
# -----------------------------------------------------------------------------
for app in "Activity Monitor" "Dock" "Finder" "WindowManager" "SystemUIServer" "cfprefsd"; do
  killall "$app" >/dev/null 2>&1 || true
done


cat <<'EOF'

==> Done. 일부 설정은 로그아웃 또는 재부팅 후에 완전히 반영됨.

수동 확인 권장:
  - System Settings → Keyboard → Keyboard Shortcuts 에서 단축키 잘 들어갔는지
  - Trackpad 동작 (3-finger drag, 4-finger swipes) 의도대로인지
  - Caps Lock 키 눌렀을 때 Control 동작하는지

알려진 한계:
  - "Switch to Desktop N" 단축키는 N번째 데스크탑이 실제로 존재해야 동작.
    Mission Control(F3) 열어 데스크탑 5개까지 만들어 둘 것.
  - symbolichotkeys ID는 macOS 메이저 버전이 바뀌면 어긋날 수 있음.
    안 먹는 단축키 있으면 System Settings 에서 수동 지정.

EOF
