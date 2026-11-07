#!/bin/sh
# Где запущен агент: компьютер пользователя, облачная сессия Claude Code, воркспейс или неизвестно, и откуда запуск.
# Claude Code вызывает скрипт сам (хук SessionStart в личных настройках), Codex — вручную.
# Что проверять и готовить для конкретного проекта — в его собственном скрипте, не здесь.
set -u

phone=
if [ "${CLAUDE_CODE_REMOTE:-}" = "true" ]; then
  case "${CLAUDE_CODE_ENTRYPOINT:-}" in
    remote_mobile) from="с телефона (приложение Claude)"; phone=1 ;;
    *)             from="точка входа: ${CLAUDE_CODE_ENTRYPOINT:-неизвестна}" ;;
  esac
  echo "Среда агента: облачная сессия Claude Code (контейнер Anthropic, claude.ai/code), $from."
elif [ -r /etc/workspace.env ]; then
  name=$(sed -n 's/^WORKSPACE_NAME=//p' /etc/workspace.env)
  echo "Среда агента: воркспейс ${name:-без имени} — контейнер пользователя на его сервере."
elif [ "$(uname -s)" = "Darwin" ]; then
  echo "Среда агента: компьютер пользователя (macOS)."
else
  echo "Среда агента: неизвестно — Linux без известных отметок ($(uname -n)). Считай, что компьютера пользователя, VPN и секретов нет."
fi

[ -n "$phone" ] && echo "Формат ответов: для телефона и озвучки (rules/base.md, «Работа с телефона»)."

if command -v gitleaks >/dev/null; then
  echo "gitleaks: есть."
else
  echo "gitleaks: нет — коммитить нельзя, пока его не поставят."
fi
