# niri-noctalia-rice

Моё оформление CachyOS: **niri + Noctalia** (палитра Catppuccin Lavender), **wezterm**, **fish + starship**, экран входа **greetd/ReGreet**, обои.

```
git clone <repo> && cd niri-noctalia-rice
./install.sh [--fish-theme] [--no-pkgs] [--no-greeter]
```

- `--fish-theme` применить Catppuccin Mocha к подсветке fish (на исходной машине не был применён)
- `--no-pkgs` / `--no-greeter` пропустить пакеты / замену display manager

Перезаписанные файлы сохраняются как `*.bak-<время>`. После первого входа в niri: `noctalia msg templates-apply`.

## Что внутри
| Путь | Назначение |
|---|---|
| `home/.config/niri` | конфиг niri (`noctalia.kdl` генерируется шеллом) |
| `home/.config/noctalia` | `config.toml`, палитра Catppuccin-Lavender, `plugins.json` |
| `home/.config/{wezterm,fish,starship.toml,fastfetch,gtk-3.0,gtk-4.0}` | терминал, shell, prompt, GTK |
| `home/Pictures/Wallpapers` | обои (по умолчанию `wallhaven_dggkwj.jpg`) |
| `etc/greetd` | greetd + ReGreet в мини-сессии niri, фон `greet.jpg` |

## Отличия от исходной машины
- Мониторы определяются автоматически (`~/.local/bin/niri-autodisplay` при каждом старте niri: макс. частота при родном разрешении, VRR, масштаб по DPI, слева направо; убери строку AUTOGEN в `display.kdl`, чтобы зафиксировать вручную; поворот не определяется, моя раскладка в `display.kdl.janna`); greeter генерирует `output` по подключённым портам.
- Исправлен фон greeter'а (раньше указывал на несуществующий `greet.png`).
- Убраны: путь к Handy AppImage (добавляется, если файл есть), garuda-алиас и логотип fastfetch, kvantum/qt5ct (не использовались).
- Не включены: плагины Noctalia (ставятся сами), `fish_variables`, `settings.json` v4, кэш/состояние.
- Fingerprint в lockscreen включён в конфиге, но нужен `fprintd` + `fprintd-enroll`.
