# niri-noctalia-rice

Моё оформление CachyOS: **niri + Noctalia** (палитра Catppuccin Lavender), **wezterm**, **fish + starship**, экран входа **greetd/ReGreet**, обои.

```
git clone <repo> && cd niri-noctalia-rice
./install.sh [--fish-theme] [--no-pkgs] [--no-greeter]
```

- `--fish-theme` применить Catppuccin Mocha к подсветке fish (на исходной машине не был применён)
- Необязательные части (пакеты, greeter, обои, Handy, тема fish) спрашиваются интерактивно; без TTY или с `--yes` берутся значения по умолчанию, а флаги `--no-*` / `--fish-theme` отвечают за вас
- `--no-nvim` / `--no-agents`: пропустить Neovim с конфигом AstroNvim (`nvim/`, плагины подтянутся при первом запуске `nvim`) и агентов Claude Code / Codex (`agents/`, ставятся в `~/.claude/agents` и `~/.codex/agents`; сами агенты GSD вызывают `~/.codex/get-shit-done`, его нужно ставить отдельно)
- `--firedragon`: поставить браузер FireDragon (`firedragon` из chaotic-aur/AUR через paru/yay; по умолчанию не ставится; профиль не переносится)
- Handy: AppImage качается с GitHub (последняя версия, или `HANDY_VERSION=0.8.3`), ставится в `~/.local/opt/handy`, симлинк `~/.local/bin/handy`, настройки (PTT Ctrl+Space, `handy-paste` через wl-copy+wtype) кладутся только если Handy ещё не настраивался; модели не в репозитории, выбираются в окне Handy

Перезаписанные файлы сохраняются как `*.bak-<время>`. После первого входа в niri: `noctalia msg templates-apply`.

## Что внутри
| Путь | Назначение |
|---|---|
| `home/.config/niri` | конфиг niri (`noctalia.kdl` генерируется шеллом) |
| `home/.config/noctalia` | `config.toml`, палитра Catppuccin-Lavender, `plugins.json` |
| `home/.config/{wezterm,fish,starship.toml,fastfetch,gtk-3.0,gtk-4.0}` | терминал, shell, prompt, GTK |
| `wallpapers/` | обои (по умолчанию `wallhaven_dggkwj.jpg`) |
| `handy/` | шаблон настроек Handy |
| `etc/greetd` | greetd + ReGreet в мини-сессии niri, фон `greet.jpg` |

## Отличия от исходной машины
- Мониторы определяются автоматически (`~/.local/bin/niri-autodisplay` при каждом старте niri: макс. частота при родном разрешении, VRR, масштаб по DPI, слева направо; убери строку AUTOGEN в `display.kdl`, чтобы зафиксировать вручную; поворот не определяется, моя раскладка в `display.kdl.janna`); greeter генерирует `output` по подключённым портам.
- Исправлен фон greeter'а (раньше указывал на несуществующий `greet.png`).
- Убраны: путь к Handy AppImage (добавляется, если файл есть), garuda-алиас и логотип fastfetch, kvantum/qt5ct (не использовались).
- Не включены: плагины Noctalia (ставятся сами), `fish_variables`, `settings.json` v4, кэш/состояние.
- Fingerprint в lockscreen включён в конфиге, но нужен `fprintd` + `fprintd-enroll`.
