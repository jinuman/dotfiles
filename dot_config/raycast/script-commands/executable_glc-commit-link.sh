#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title GitLab Commit Link
# @raycast.mode silent
# @raycast.argument1 { "type": "text", "placeholder": "Commit Hash" }

# Optional parameters:
# @raycast.icon 💻
# @raycast.packageName GitLab

commit_hash="$1"

# 선택지
project=$(printf "배민\n디자인시스템" | /usr/bin/osascript <<EOF
  set choiceList to paragraphs of "$(cat)"
  choose from list choiceList with prompt "프로젝트를 선택하세요:" default items {"배민"}
EOF
)

# 사용자가 취소했을 경우
if [ "$project" = "false" ]; then
  exit 1
fi

# URL 결정
case "$project" in
  "배민")
    url="https://git.baemin.in/appservice/ios/baemin-ios/-/commit/$commit_hash"
    ;;
  "디자인시스템")
    url="https://git.baemin.in/appservice/ios/baemin-design-system-ios/-/commit/$commit_hash"
    ;;
esac

# 링크 열기
open "$url"
