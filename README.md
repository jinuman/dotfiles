# dotfiles

새 맥 셋업 자동화. **위에서 아래로 따라가면 환경이 완성**된다.

## Stack

| 도구 | 역할 |
|---|---|
| **1Password** | passwords, SSH key, API tokens, 앱 라이센스 |
| **Homebrew + `bootstrap/Brewfile`** | CLI, GUI 앱, App Store 앱, 폰트 |
| **chezmoi** | dotfile + 앱 설정 (zsh, git, VS Code, Sublime, Xcode 등) |
| **`bootstrap/macos.sh`** | 시스템 defaults (`defaults write`) + Caps Lock → Control |
| **`Makefile`** | `make apply` / `make brew` / `make macos` / `make all` 묶음 |

> Migration Assistant 안 씀 — 오래된 설정/캐시까지 옮겨와서. 필요한 것만 선언적으로 재구성하는 게 목적.

---

## 1. 사전 수동 작업

| # | 작업 | 비고 |
|---|---|---|
| 1 | Apple ID 로그인 | macOS 첫 셋업 |
| 2 | App Store → Xcode 설치 시작 | 10~30분, 백그라운드 |
| 3 | `xcode-select --install` | brew prereq, Xcode 본체 기다리지 말고 먼저 |

## 2. 부트스트랩

### 2-1. Homebrew + 필수 패키지

```sh
# Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

# 1Password 앱 — brew cask 가 SHA 깨졌으면 1password.com 또는 App Store 에서 직접
brew install --cask 1password || open https://1password.com/downloads/mac

# CLI + chezmoi
brew install --cask 1password-cli
brew install chezmoi
```

> `brew install --cask 1password` 가 `Cask reports different checksum` 으로 실패하면 MacPaw upstream 과 homebrew-cask 가 어긋난 일시적 상황. 직접 다운로드 후 다음 단계로 진행.

### 2-2. 1Password GUI 셋업 + CLI 로그인

1Password 앱 실행 → 본인 계정 로그인 → `⌘,` Settings → **Developer**:

- ☑ **Use the SSH agent** — 앞으로 `git push` / 기타 ssh 인증에 사용 (`private_dot_ssh/config` 가 이 socket 가리킴)
- ☑ **Integrate with 1Password CLI** — `dot_gitconfig.work.tmpl` 의 `onepasswordRead` 에 필요

CLI 로그인:
```sh
eval "$(op signin)"     # 1Password 앱 팝업 → Touch ID/Watch 인증
op whoami               # email/account 출력되면 OK
```

### 2-3. dotfiles + 자동화

```sh
# Public repo 라 HTTPS 로 anonymous clone (SSH 없이도 OK)
chezmoi init https://github.com/jinuman/dotfiles.git

# Makefile 통해 한 번에
chezmoi cd
make all
```

`make all` = `chezmoi apply` + `brew bundle` + `macos.sh` (10~30분).
끝나면 macOS 가 **"Use Chrome"** 다이얼로그 띄움 → 클릭.

> SSH 는 `git push` 할 때만 필요 — §2-2 의 SSH agent 토글 ON 으로 자동.
> push 도 SSH 로 가고 싶으면: `git remote set-url origin git@github.com:jinuman/dotfiles.git`

## 3. 사후 수동 작업

자동화 불가능한 단발성 셋업. 위에서부터 순서대로.

### 3-1. 앱 권한 (System Settings → Privacy & Security)

| 권한 | 부여할 앱 |
|---|---|
| Accessibility | Raycast, Rectangle, Contexts, Keyboard Maestro, Espanso, KeyCastr, Ice |
| Input Monitoring | KeyCastr, Espanso |
| Screen Recording | CleanShot, Zoom, Slack |
| Full Disk Access | Dropbox, AppCleaner |

### 3-2. 기본 브라우저

`macos.sh` 끝에 macOS 보안 다이얼로그가 뜸 → **"Use 'Google Chrome'"** 클릭. (Apple 정책상 자동화 불가)

### 3-3. 앱별 import / 로그인

- **Rectangle**: Settings → Import Config → `~/.config/rectangle/config.json`
- **Keyboard Maestro**: Editor → File → Start Syncing Macros → Dropbox 안 `Keyboard Maestro Macros.kmsync`
- **Xcode**: Settings → Themes → **Monokai**. Custom Key Bindings set 있으면 같이 선택.
- **VS Code**: GitHub/계정 로그인 → settings sync (선택)
- **Chrome**: Google 계정 로그인 → 북마크/확장/비밀번호 sync, 1Password 확장 설치
- **Slack / Discord / Notion / Figma / Zoom**: 각자 로그인

### 3-4. 라이센스 입력 (1Password 에서 꺼냄)

- Sublime Text
- Keyboard Maestro
- CleanShot X

### 3-5. 클라우드 sync 시작

- **iCloud** 로그인 (Drive/Photos 는 데이터 크기 보고 선택적으로)
- **Dropbox** 로그인 → sync 대기 (KM `.kmsync` 동기화에 필요)
- Time Machine 외장하드 연결 (있으면)

### 3-6. Brew cask 없는 앱 직접 다운로드 (선택)

- **Kiro** ([kiro.dev](https://kiro.dev)) — `dot_zshrc` 에 shell integration 라인 이미 있음
- **Antigravity** — `dot_zshrc` 의 `~/.antigravity/antigravity/bin` PATH 가리킴

## 4. 동작 확인

```sh
# 키보드 단축키 (System Settings → Keyboard → Keyboard Shortcuts)
#   Spotlight = ⌥Space, Input source = ⌘Space, Switch Desktop = ⌃1..⌃5
#   Caps Lock 키 누르면 Control 동작

# 셸
echo $SHELL                # /bin/zsh
mise --version             # 동작
starship --version

# dotfiles 정합성
chezmoi diff               # 비어야 정상
```

---

## 일상 운용

| 작업 | 명령 |
|---|---|
| dotfile 추가 | `chezmoi add <path>` |
| dotfile 갱신 (pull + apply) | `chezmoi update` |
| Brewfile 동기화 | `chezmoi cd && make brew` |
| `macos.sh` 재실행 | `chezmoi cd && make macos` |
| 전체 재적용 | `chezmoi cd && make all` |
| Brewfile dump (전체 갱신) | `brew bundle dump --describe --file=~/.local/share/chezmoi/bootstrap/Brewfile --force` |
| 변경 커밋 | `chezmoi cd && git add -A && git commit && git push` |
| Makefile 명령 목록 | `chezmoi cd && make help` |

## 트러블슈팅

- **`mas` 실패** → App Store 로그인 후 해당 앱 한 번 받기(구매 내역) → `brew bundle ...` 재실행
- **`onepasswordRead` 에러** → `op whoami` 로 상태 확인. 안 되어 있으면 `eval "$(op signin)"` 후 재시도
- **`chezmoi diff` plist drift 반복** → 해당 앱 (VS Code 등) 종료 후 `chezmoi re-add <path>` 로 source 갱신
- **`chezmoi inconsistent state`** → 중복 디렉터리 (예: `Library` vs `private_Library`) 한쪽 제거
- **Caps Lock → Control 안 됨** → Karabiner-Elements 잔존 가능. `sudo /Library/Application\ Support/org.pqrs/Karabiner-Elements/uninstall/uninstall_karabiner_elements.sh` + 재부팅
- **단축키 일부 안 먹음** → macOS 메이저 업그레이드 후 symbolichotkeys ID 어긋남. System Settings 에서 수동 지정
- **`subl` 또는 `code` 명령 없음** → 새 셸 열거나 `eval "$(brew shellenv)"`
