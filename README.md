# my-agents-rules

Общие правила для AI-агентов (Claude Code, Codex): как общаться, как работать с телефона
и голосом, что можно и нельзя в каждой среде. Плюс скрипты, которые доставляют правила в
каждую среду, и общий хук gitleaks, чтобы ни в один репозиторий не попал секрет.

Правила конкретного проекта — в его `AGENTS.md`. Они дополняют общие и в своей области главнее.

## Что где

| Файл | Для кого |
|---|---|
| `rules/base.md` | все агенты, все среды |
| `rules/cloud.md` | добавка для облачной сессии Claude Code |
| `bin/agent-env.sh` | определяет среду: компьютер, облачная сессия, воркспейс; откуда запуск |
| `hooks/pre-commit` | gitleaks перед каждым коммитом во всех репозиториях |
| `cloud/install.sh` | ставит всё это в облачной сессии |
| `AGENTS.md` | агент, который работает с этим репозиторием |

## Компьютер (macOS)

Один раз:

```sh
git clone https://github.com/ansgar-forestier/my-agents-rules ~/my-agents-rules
ln -sfn ~/my-agents-rules/rules/base.md ~/.claude/CLAUDE.md
ln -sfn ~/my-agents-rules/rules/base.md ~/.codex/AGENTS.md
git config --global core.hooksPath ~/my-agents-rules/hooks
brew install gitleaks
```

Путь клона — любой, главное, чтобы ссылки и `core.hooksPath` вели в него.
Глобальный `core.hooksPath` отключает хуки в `.git/hooks` всех репозиториев; если у проекта
своя настройка `core.hooksPath`, она главнее, и gitleaks должен вызывать его собственный хук.

Обновление — `git pull` в клоне (делает пользователь, не агент). Новые правила действуют
со следующей сессии агента.

Определение среды в начале каждой сессии Claude Code — хук SessionStart в
`~/.claude/settings.json` (если файл уже есть — добавить в него):

```json
{ "hooks": { "SessionStart": [ { "matcher": "startup|resume|clear|compact",
  "hooks": [ { "type": "command", "command": "~/my-agents-rules/bin/agent-env.sh" } ] } ] } }
```

## Облачная сессия

Setup script каждого облачного окружения (меню окружения в заголовке сессии → Edit):

```sh
git clone --depth 1 https://github.com/ansgar-forestier/my-agents-rules /opt/agent-rules \
  && sh /opt/agent-rules/cloud/install.sh || echo "agent-rules: не установлены"
```

Скрипт кладёт `rules/base.md` + `rules/cloud.md` в `/etc/claude-code/CLAUDE.md`, ставит
gitleaks, подключает общий хук и хук SessionStart. Каждый новый контейнер берёт свежий `main`.

## Воркспейсы

Правила доставляет инфраструктура, которая создаёт воркспейсы: `rules/base.md` плюс своя
добавка про воркспейс, файл только для чтения.

## Настройки GitHub

Это не код, поэтому записаны здесь.

- **Ruleset для `main`** (Settings → Rules → Rulesets): цель — ветка по умолчанию;
  Restrict deletions, Block force pushes, Require a pull request before merging
  (Required approvals — 0, иначе свой PR не влить); Bypass list пустой — прямой push
  отклоняется у всех.
- **Push protection** для секретов (Settings → Code security или Advanced Security — название
  меняется): второй барьер на стороне
  GitHub, если коммит прошёл мимо хука.
