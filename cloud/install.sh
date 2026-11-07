#!/bin/sh
# Установка правил в облачной сессии Claude Code. Запускается из setup script окружения
# от root, до старта агента (строки для setup script — README.md, «Облачная сессия»).
# Не падает: сбой setup script не даёт начать сессию, поэтому ошибки только печатаем.
set -u

GITLEAKS_VERSION=8.28.0
GITLEAKS_SHA256=a65b5253807a68ac0cafa4414031fd740aeb55f54fb7e55f386acb52e6a840eb  # linux_x64

dir=$(cd "$(dirname "$0")/.." && pwd)
etc=${AGENT_RULES_ETC:-/etc/claude-code}  # другой путь — только для проверки в песочнице

# 1. Правила: управляемый файл инструкций Claude Code на Linux (агент изменить его не может).
mkdir -p "$etc" \
  && cat "$dir/rules/base.md" "$dir/rules/cloud.md" > "$etc/CLAUDE.md" \
  && echo "agent-rules: правила в $etc/CLAUDE.md." \
  || echo "agent-rules: правила положить не удалось."

# 2. gitleaks (версия и sha256 закреплены).
if ! command -v gitleaks >/dev/null; then
  if [ "$(uname -m)" = "x86_64" ]; then
    tmp=$(mktemp -d)
    url="https://github.com/gitleaks/gitleaks/releases/download/v$GITLEAKS_VERSION/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz"
    if curl -sSfL -o "$tmp/gl.tgz" "$url" \
       && echo "$GITLEAKS_SHA256  $tmp/gl.tgz" | sha256sum -c - >/dev/null 2>&1 \
       && tar -xzf "$tmp/gl.tgz" -C "$tmp" gitleaks \
       && install -m 0755 "$tmp/gitleaks" /usr/local/bin/gitleaks; then
      echo "agent-rules: gitleaks $GITLEAKS_VERSION установлен."
    else
      echo "agent-rules: gitleaks поставить не удалось."
    fi
    rm -rf "$tmp"
  else
    echo "agent-rules: gitleaks для $(uname -m) не закреплён, не ставлю."
  fi
fi

# 3. Общий хук gitleaks для всех репозиториев контейнера. Своя настройка репозитория главнее.
git config --system core.hooksPath "$dir/hooks" \
  && echo "agent-rules: хук gitleaks подключён для всех репозиториев." \
  || echo "agent-rules: хук gitleaks подключить не удалось."

# 4. Хук SessionStart: определение среды в каждой сессии (личные настройки Claude Code).
settings="$HOME/.claude/settings.json"
mkdir -p "$HOME/.claude"
python3 -I - "$settings" "$dir/bin/agent-env.sh" <<'EOF' \
  && echo "agent-rules: хук определения среды в $settings." \
  || echo "agent-rules: хук определения среды прописать не удалось."
import json, os, sys
path, cmd = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(path):
    with open(path) as f:
        data = json.load(f)
starts = data.setdefault("hooks", {}).setdefault("SessionStart", [])
if not any(h.get("command") == cmd for e in starts for h in e.get("hooks", [])):
    starts.append({"matcher": "startup|resume|clear|compact",
                   "hooks": [{"type": "command", "command": cmd}]})
with open(path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
EOF
