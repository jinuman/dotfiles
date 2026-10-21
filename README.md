# dotfiles

Mac Setup 자동화! **위에서 아래로 따라가면 환경이 완성**된다.

## Stack

| 도구 | 역할 |
|---|---|
| **1Password** | passwords, SSH key, API tokens, 앱 라이센스 |
| **Homebrew + `bootstrap/Brewfile`** | CLI, GUI 앱, App Store 앱, 폰트 |
| **chezmoi** | dotfile + 앱 설정 (zsh, git, VS Code, Sublime, Xcode 등) |
| **`bootstrap/macos.sh`** | macOS 업데이트로 안 깨지는 시스템 defaults + Caps Lock → Control |
| **`Makefile`** | 셋업 `make all`(apply+brew+macos) · 일상 `make status` / `make update` |

> Migration Assistant 안 씀 — 오래된 설정/캐시까지 옮겨와서. 필요한 것만 선언적으로 재구성하는 게 목적.

---

## 1. 사전 수동 작업

1. Apple ID 로그인 (macOS 첫 Setup)
2. App Store → Xcode 설치 시작 (10~30분, 백그라운드)
3. `xcode-select --install` — brew 선행 조건이라 Xcode 본체 기다리지 말고 먼저

## 🌟 2. 부트스트랩

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

### 2-2. 1Password SSH Agent

1Password 앱 실행 → 로그인 → `⌘,` Settings → **Developer**:

1. **Set up the SSH Agent** 클릭 → "Allow 1Password to save SSH key names to disk?" → **Use Key Names**
2. `~/.ssh/config` 수정 제안이 뜨면 건너뜀 (chezmoi 가 씀)
3. Developer Integrations → ☑ **Integrate with 1Password CLI**

최초 1회, 1Password 의 `id_ed25519` 공개키 등록:

- GitHub → Settings → SSH and GPG keys: Authentication Key + Signing Key
- git.baemin.in → Preferences → SSH Keys (Authentication & Signing)

### 2-3. dotfiles + 자동화

```sh
# Public repo 라 HTTPS 로 anonymous clone (SSH 없이도 OK)
# init 중 "회사 git 이메일" 1회 입력 → ~/.config/chezmoi/chezmoi.toml 에 저장 (레포엔 안 올라감)
chezmoi init https://github.com/jinuman/dotfiles.git

# Makefile 통해 한 번에
chezmoi cd
make all
```

`make all` = `chezmoi apply` + `brew bundle` + `macos.sh` (10~30분).

> push 도 SSH 로 가고 싶으면: `git remote set-url origin git@github.com:jinuman/dotfiles.git`

## 3. 이후 수동 작업

자동화 불가능한 단발성 셋업으로 위에서부터 순서대로 진행

### 3-1. 클라우드 로그인

- **iCloud** 로그인
- **Dropbox** 로그인 → sync (Keyboard Maestro · Raycast import 등에 필요)

### 3-2. 키보드 단축키 (System Settings → Keyboard → Keyboard Shortcuts)

| 위치 | 항목 | 값 |
|---|---|---|
| Spotlight | Show Spotlight Search | `⌥Space` |
| Spotlight | Show Finder search window | `⌥⌘Space` (기본) |
| Input Sources | Select the previous input source | `⌘Space` (한/영 토글) |
| Mission Control | Show Desktop | `⌥D` |
| Mission Control | Switch to Desktop 1 | `⌃1` |
| Mission Control | Switch to Desktop 2 | `⌃2` |
| Mission Control | Switch to Desktop 3 | `⌃3` |
| Screenshots | 전체 단축키 | OFF (CleanShot 사용) |

> "Switch to Desktop N" 이 회색이면 Mission Control(F3) 열어 데스크탑 3개부터 만들기.
>
> **Caps Lock → Control** 은 `macos.sh` 가 이미 처리.

### 3-3. Trackpad (System Settings → Trackpad + Accessibility)

| 위치 | 항목 | 값 |
|---|---|---|
| Trackpad → Point & Click | Tap to click | ON |
| Trackpad → Point & Click | Look up & data detectors | Tap with Three Fingers |
| Trackpad → More Gestures | Swipe between full-screen applications | Swipe Left or Right with Four Fingers |
| Trackpad → More Gestures | Mission Control | Swipe Up with Four Fingers |
| Trackpad → More Gestures | App Exposé | Swipe Down with Four Fingers |
| Accessibility → Pointer Control → Trackpad Options | Use trackpad for dragging | ON, **Three Finger Drag** |
| Accessibility → Zoom | Use scroll gesture with modifier keys to zoom | ON (`⌃` + scroll) |

### 3-4. Desktop & Dock (System Settings → Desktop & Dock)

| 위치 | 항목 | 값 |
|---|---|---|
| Desktop & Stage Manager | Show Items | In Stage Manager 만 |
| Desktop & Stage Manager | Click wallpaper to show desktop | Always |
| Desktop & Stage Manager | Stage Manager | OFF |
| Default web browser | | Google Chrome |
| Windows | Prefer tabs when opening documents | In Full Screen |
| Windows | Ask to keep changes when closing documents | OFF |

> Dock 크기·확대·최근 앱, 타이틀바 더블클릭, Hot Corners, 타일링, 앱 종료 시 창 유지, Spaces 자동 재배치는 `macos.sh` 가 처리.

### 3-5. Desktop 운영 (3-Desktop)

종일 떠 있는 **앵커 앱만** 데스크탑에 고정한다. 나머지(호출형·백그라운드)는 어디서 켜든 따라오므로 고정하지 않는다.

| Desktop | 모드 | 단축키 | 고정 앱 (앵커) |
|---|---|---|---|
| 1 | 브라우저 · 레퍼런스 | `⌃1` | Chrome, Figma, Obsidian |
| 2 | 개발 (빌드) | `⌃2` | Xcode (+Simulator), WezTerm, Fork, Sublime, Claude, Cursor, Kiro, Bruno |
| 3 | 소통 | `⌃3` | Slack, Zoom, KakaoTalk, Discord |

원칙: D1(레퍼런스) ↔ D2(빌드)는 종일 swipe 하는 두 작업 모드라 인접. 인터럽트성 소통은 D3 로 격리해 작업 데스크탑(1·2)이 안 흔들리게 한다.

1. Mission Control → `+` 두 번 → 데스크탑 3개
2. 원하는 데스크탑으로 이동 → 앵커 앱 실행 → **Dock 우클릭 → Options → Assign To → This Desktop**

**전역 앱 (Assign 하지 말 것 — `None` 유지):** Raycast, 1Password, CleanShot, KeyCastr, Dropbox, Keyboard Maestro, Ice, Rectangle, Contexts, Charles, AppCleaner, iWork, IINA, Bandizip, Allkdic 등 호출형·백그라운드 앱. 앱 전환 시 그 앱의 Space 로 따라가는 macOS 기본 동작 때문에 이들을 데스크탑에 고정하면 **켤 때마다 그 데스크탑으로 끌려간다** — 고정 안 해야 '지금 보던' 데스크탑에 뜬다.

> **Figma**: 단일 화면이면 D1 에 두고 Xcode(D2)와 swipe 비교. 외장 모니터면 Xcode 옆 D2.
> **Claude Code / Gemini CLI**: WezTerm 안에서 도는 CLI라 별도 고정 불필요 (D2).
> **집중 작업**: 앱을 풀스크린(`⌃⌘F`)으로 — macOS 가 임시 Space 를 만들어 위에 얹는다.

### 3-6. 앱별 import / 로그인 / 라이센스

- **Rectangle**: Settings → Import Config → `~/.config/rectangle/config.json`
- **Keyboard Maestro**: Editor → File → Start Syncing Macros → Dropbox 안 `Keyboard Maestro Macros.kmsync`
- **Raycast**: Settings → Advanced → Import → Dropbox `settings/raycast/*.rayconfig` → Extensions → Script Commands → Add Directories → `~/.config/raycast/script-commands`
- **Xcode**: Settings → Themes → **Monokai**, Key Bindings → **Default**
- **VS Code**: 계정 로그인만 (Settings Sync 는 끔 — 설정은 chezmoi 가 관리)
- **Chrome**: Google 계정 로그인 → 북마크/확장/비밀번호 sync, 1Password 확장 설치
- **Slack / Discord / Notion / Figma / Zoom**: 각자 로그인
- **라이센스** (1Password): Keyboard Maestro, CleanShot X, Contexts

### 3-7. Brewfile 에 없는 앱 (선택)

- **Kiro** ([kiro.dev](https://kiro.dev)) — `dot_zshrc` 에 shell integration 라인 있음
- **Antigravity** — `dot_zprofile` 에 `~/.antigravity/antigravity/bin` PATH 있음

### 3-8. Claude Code 로컬 설정 (레포 밖, zip 으로 AirDrop)

계정에 묶인 것(Anthropic·Figma 스킬, claude.ai 커넥터)은 로그인하면 따라오지만, 아래는 **기기 로컬 파일**이라 직접 옮긴다. 사내 정보가 들어 있어 공개 레포인 여기엔 담지 않는다.

| 항목 | 경로 | 옮기는 법 |
|---|---|---|
| 사용자 스킬 (`adr-dessys`, `darkmode-share-doc`, `worklog-daily`) | `~/.claude/skills/` | zip → AirDrop |
| 스케줄 태스크 `worklog-daily` | `~/.claude/scheduled-tasks/worklog-daily/` | 본문은 스킬에 있음. 새 맥에서 **스텁 프롬프트로 재등록** |
| 사내 플러그인 `designsystem-ios` | `~/.claude/plugins/`, `settings.json` 의 `enabledPlugins`·`extraKnownMarketplaces` | 복사하지 말고 **재설치** |

> 구조: `worklog-daily` 의 긴 지침은 `~/.claude/skills/worklog-daily/SKILL.md` 한 곳에만 두고, 스케줄 태스크는 "이 스킬을 호출하라"는 2줄 스텁만 가진다. 스케줄러는 `~/.claude/scheduled-tasks/<taskId>/SKILL.md` 고정 경로만 읽어서 파일 자체는 `skills/` 로 옮길 수 없기 때문.

**이전 맥 — zip 만들기.** Claude Code(데스크톱 앱 Code 탭, Auto 권한) 세션에 아래처럼 요청하면 바탕화면에 묶어 준다.

> `~/.claude/skills/` 전체와, 스케줄 태스크 `worklog-daily` 를 새 맥에서 만들 때 쓸 스텁 프롬프트(아래 2줄)를 `worklog-daily-task-prompt.txt` 로 넣어 `~/Desktop/claude-local-config.zip` 으로 묶어줘. `.DS_Store` 는 빼고, zip 안 경로는 `.claude/skills/...` 로 홈 기준 상대 경로여야 해. 다 되면 Finder 에서 보여줘.

손으로 할 때:

```sh
cd ~ && zip -r ~/Desktop/claude-local-config.zip .claude/skills -x '*.DS_Store'
cd ~/Desktop && zip claude-local-config.zip worklog-daily-task-prompt.txt   # 스텁 2줄 (아래)
```

스텁 프롬프트 (`worklog-daily-task-prompt.txt`):

```
Skill 도구로 `worklog-daily` 스킬을 호출하고, 그 스킬의 지시를 처음부터 끝까지 그대로 수행해라.
스킬이 지시하는 Confluence 작업일지 저장(updateConfluencePage)과 스킬 파일(~/.claude/skills/worklog-daily/SKILL.md) 수정은 이 태스크가 허용한 쓰기 동작이다. 질문하지 말고 끝까지 수행한 뒤 스킬의 6절 형식으로 보고해라.
```

바탕화면의 zip 을 우클릭 → 공유 → AirDrop 으로 새 맥에 보낸다.

**새 맥 — 풀기 + 등록.** Finder 더블클릭으로 풀면 Downloads 안에 풀려 버리니 터미널에서 홈에 푼다.

```sh
rm -rf ~/.claude/scheduled-tasks/worklog-daily          # 옛 태스크 폴더가 있으면 이름 충돌 → 제거
unzip -o ~/Downloads/claude-local-config.zip -d ~
ls ~/.claude/skills                                     # adr-dessys  darkmode-share-doc  worklog-daily
```

1. Claude 데스크톱 앱 완전 종료 → 재실행 (스킬 목록 갱신).
2. Auto 권한 세션에서 요청:
   > `~/worklog-daily-task-prompt.txt` 내용을 프롬프트로, taskId `worklog-daily`, 설명 '하루 활동을 모아 월간 작업일지를 갱신하고 다음 근무일 계획을 채움', cron `30 18 * * 1-5` 로 scheduled task 를 만들어줘.
3. "worklog-daily 지금 실행해줘" 로 한 번 돌려 스킬 호출 확인 (정오 이전이면 catch-up 모드라 오늘 칸은 안 건드림).
4. 이전 맥의 태스크는 **비활성**으로 둔다 (둘 다 켜면 같은 날 두 번 저장).

**새 맥 — 사내 플러그인 재설치.** `claude` CLI 안에서 (git.baemin.in SSH 접근 필요, 2-2 이후):

```
/login                      ← 회사 claude.ai 계정 (API 콘솔 계정 아님)
/plugin marketplace add https://git.baemin.in/appservice/woowahan-mobile-plugin-marketplace.git
/plugin install designsystem-ios@woowahan-mobile
/reload-plugins             ← "1 plugin · 1 skill · 1 plugin MCP server" 면 OK
```

(선택) 최근 10일치 Claude 대화 로그 `~/.claude/projects/**/*.jsonl` 은 `worklog-daily` 가 활동 근거로 읽는다. 이어 붙이고 싶으면 같은 방식으로 zip 에 추가.

## 4. 동작 확인

```sh
# 키보드: ⌥Space = Spotlight, ⌘Space = 한/영, ⌃1~3 = Desktop 전환, Caps Lock = Control

# 셸
echo $SHELL                # /bin/zsh
mise --version
starship --version

# dotfiles 정합성
chezmoi diff               # 비어야 정상
```

---

## 일상 운용

| 작업 | 명령 |
|---|---|
| **바뀐 설정 미리보기** (읽기 전용) | `chezmoi cd && make status` |
| **바뀐 설정 → 레포 흡수** | `chezmoi cd && make update` |
| dotfile **새로** 추가 (최초 1회) | `chezmoi add <path>` |
| 원격 pull + ~ 에 적용 | `chezmoi update` |
| Brewfile 동기화 | `chezmoi cd && make brew` |
| `macos.sh` 재실행 | `chezmoi cd && make macos` |
| 전체 재적용 | `chezmoi cd && make all` |
| 변경 커밋 | `chezmoi cd && git add -A && git commit && git push` |
| Makefile 명령 목록 | `chezmoi cd && make help` |

> **`make update` ≠ `chezmoi update`** — `make update` 는 **~ → 레포** (`chezmoi re-add`), `chezmoi update` 는 **원격 → ~** (git pull 후 apply).
>
> `make update` 는 이미 관리 중인 파일만 담는다. 새 설정 파일은 최초 1회 `chezmoi add <path>`.

## 트러블슈팅

- **`mas` 실패** → App Store 로그인 후 해당 앱 한 번 받기(구매 내역) → `make brew` 재실행
- **`chezmoi diff` plist drift 반복** → 해당 앱 종료 후 `make update` (또는 `chezmoi re-add <path>`). `git diff` 로 휘발성 변경은 빼고 커밋
- **쉴 새 없이 바뀌는 plist** (예: Contexts) → `.chezmoiignore` 에 넣어 평소엔 무시. 백업할 때만 그 줄을 잠깐 `#` 주석 → `make update` → 주석 해제 → 커밋
- **`chezmoi inconsistent state`** → 중복 디렉터리 (예: `Library` vs `private_Library`) 한쪽 제거
- **단축키 일부 안 먹음** → macOS 메이저 업그레이드 후 reset. System Settings 에서 다시 지정
- **`subl` 또는 `code` 명령 없음** → 새 셸 열거나 `eval "$(brew shellenv)"`
