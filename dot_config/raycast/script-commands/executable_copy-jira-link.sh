#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open Jira Link
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🎟️
# @raycast.argument1 { "type": "text", "placeholder": "Issue Number (ex. 1234)" }
# @raycast.argument2 { "type": "dropdown", "placeholder": "Project", "data": [{"title": "WOOTELIER", "value": "WOOTELIER"}, {"title": "BAEMINAPP", "value": "BAEMINAPP"}] }

# Documentation:
# @raycast.description Generate and open Jira URL

ISSUE_NUM=$1
PROJECT=$2
BASE_URL="https://cloud.jira.woowa.in/browse"
FINAL_URL="${BASE_URL}/${PROJECT}-${ISSUE_NUM}"

# 1. 생성된 URL을 클립보드에 복사
echo -n "$FINAL_URL" | pbcopy

# 2. 기본 브라우저로 해당 URL 열기 
# (브라우저 오픈을 원치 않으시면 아래 줄 앞에 #을 붙여 주석 처리하세요)
open "$FINAL_URL"

# 3. Raycast 화면 하단에 완료 메시지 띄우기
echo "Copied & Opened: ${PROJECT}-${ISSUE_NUM}"

