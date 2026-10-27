#!/usr/bin/env bash
# Standalone installer: niri + Noctalia (Catppuccin Lavender), wezterm, fish+starship, greetd/ReGreet,
# wallpapers, Handy (speech-to-text). Arch/CachyOS only. Run as a normal user; sudo is asked when needed.
# Optional parts are asked interactively; without a TTY or with --yes the defaults [Y/n] are used.
#   ./install.sh [--yes] [--no-pkgs] [--no-greeter] [--no-handy] [--no-wallpapers] [--no-nvim] [--no-agents] [--no-firedragon] [--fish-theme]
# Re-run anytime to update: ./install.sh update   (= --yes; package updates run through cachy-update, interactively)
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ $EUID -ne 0 ]] || { echo "run as normal user, not root"; exit 1; }
command -v pacman >/dev/null || { echo "pacman not found: Arch-based only"; exit 1; }

YES=0; [[ -t 0 ]] || YES=1
UPDATE=0
declare -A OPT   # name -> 1/0, preset by flags
for a in "$@"; do case $a in
  update) UPDATE=1; YES=1;;
  --yes) YES=1;; --no-pkgs) OPT[pkgs]=0;; --no-greeter) OPT[greeter]=0;; --no-handy) OPT[handy]=0;;
  --no-wallpapers) OPT[wallpapers]=0;; --no-nvim) OPT[nvim]=0;; --no-agents) OPT[agents]=0;; --no-firedragon) OPT[firedragon]=0;; --fish-theme) OPT[fishtheme]=1;;
  *) echo "unknown arg: $a"; exit 1;; esac; done

# pull the latest repo (install.sh/configs) before doing anything, then re-exec once so the
# rest of this run uses the fresh copy. NIRI_RICE_REEXECED guards against looping forever.
if [[ -z ${NIRI_RICE_REEXECED:-} ]]; then
  if git -C "$SRC" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if git -C "$SRC" pull --ff-only; then
      NIRI_RICE_REEXECED=1 exec "$SRC/install.sh" "$@"
    else
      echo "!! git pull failed (local changes in $SRC?); continuing with the checked-out copy"
    fi
  fi
fi

# ask <name> <question> <default y|n>  -> sets OPT[name]
ask() {
  [[ -n ${OPT[$1]:-} ]] && return
  local def=$3 ans
  if (( YES )); then ans=$def; else read -rp "$2 [$( [[ $def == y ]] && echo Y/n || echo y/N )] " ans; ans=${ans:-$def}; fi
  [[ $ans =~ ^[Yy] ]] && OPT[$1]=1 || OPT[$1]=0
}

ask pkgs       "Install packages (pacman/AUR)?" y
ask greeter    "Replace the display manager with greetd + ReGreet (Catppuccin login screen)?" y
ask wallpapers "Copy wallpapers to ~/Pictures/Wallpapers?" y
ask handy      "Download and set up Handy (speech-to-text, Ctrl+Space)?" y
ask nvim       "Install Neovim + AstroNvim config (plugins are fetched on first nvim start)?" y
ask agents     "Install Claude Code and Codex agents (GSD) to ~/.claude/agents and ~/.codex/agents?" y
ask firedragon "Install FireDragon browser (chaotic-aur/AUR), replacing Firefox?" y
ask fishtheme  "Apply Catppuccin Mocha colors to fish syntax highlighting?" n

REPO_PKGS=(python nodejs npm niri noctalia cachyos-niri-noctalia wezterm fish fisher starship eza bat fastfetch ugrep direnv
  adw-gtk-theme capitaine-cursors catppuccin-gtk-theme-mocha ttf-jetbrains-mono-nerd adwaita-fonts
  noto-fonts noto-fonts-emoji polkit-kde-agent xwayland-satellite xdg-desktop-portal-gnome
  xdg-desktop-portal-gtk gnome-keyring wl-clipboard curl base-devel
  telegram-desktop filezilla git openssh k9s
  podman podman-compose slirp4netns fuse-overlayfs)
(( OPT[nvim] ))    && REPO_PKGS+=(neovim ripgrep fd lazygit tree-sitter-cli unzip)
(( OPT[greeter] )) && REPO_PKGS+=(greetd greetd-regreet plymouth)
(( OPT[handy] ))   && REPO_PKGS+=(fuse2 wtype xdotool)
AUR_PKGS=(tela-circle-icon-theme-dracula clash-verge-rev-bin tg-ws-proxy-bin spotify-launcher)
(( OPT[firedragon] )) && AUR_PKGS+=(firedragon-catppuccin-bin)

if (( OPT[pkgs] )); then
  # All package updates go through cachy-update from here on (pacnew/orphan/cache/reboot checks,
  # AUR via paru/yay) instead of a bare pacman -Syu. Bootstrap just it and run it interactively
  # first; everything below only fills in what's still missing, it doesn't upgrade.
  sudo pacman -S --needed --noconfirm cachy-update libnotify
  if [[ -t 0 ]]; then
    echo ">>> Launching cachy-update — go through its prompts, this script continues after it exits."
    cachy-update || echo "!! cachy-update exited non-zero; continuing anyway"
  else
    echo "!! no TTY: skipping the interactive cachy-update run, run it yourself afterwards"
  fi

  # existing but non-functional (e.g. a paru-bin linked against the wrong libalpm) doesn't count
  helper=""
  for h in paru yay; do command -v "$h" >/dev/null && "$h" --version >/dev/null 2>&1 && { helper=$h; break; }; done
  if [[ -z $helper ]]; then
    # no working AUR helper on this box: bootstrap paru. Built from source (not paru-bin) so it
    # links against whatever libalpm this box actually has (CachyOS ships its own pacman/libalpm ABI).
    sudo pacman -Rns --noconfirm paru-bin 2>/dev/null || true
    tmp=$(mktemp -d)
    git clone --depth 1 https://aur.archlinux.org/paru.git "$tmp" \
      && (cd "$tmp" && makepkg -si --needed --noconfirm) || echo "!! paru bootstrap failed"
    rm -rf "$tmp"
    command -v paru >/dev/null && paru --version >/dev/null 2>&1 && helper=paru
  fi

  # cachy-update already brought installed packages up to date above; just fill in what's
  # missing from these lists (no -u here on purpose)
  sudo pacman -S --needed --noconfirm "${REPO_PKGS[@]}" || {
    # names differ between repos; retry one by one so a single miss doesn't abort
    for p in "${REPO_PKGS[@]}"; do sudo pacman -S --needed --noconfirm "$p" || echo "!! skipped $p"; done; }
  if [[ -n $helper ]]; then "$helper" -S --needed --noconfirm "${AUR_PKGS[@]}" || echo "!! AUR failed: ${AUR_PKGS[*]}"
  else echo "!! no AUR helper: install manually: ${AUR_PKGS[*]}"; fi
  # FireDragon replaces Firefox, not sit alongside it -- only drop Firefox once FireDragon is actually there
  (( OPT[firedragon] )) && command -v firedragon >/dev/null && sudo pacman -Rns --noconfirm firefox 2>/dev/null || true
  # rootless podman needs a subuid/subgid range; useradd grants one by default, but add it if missing
  grep -q "^$USER:" /etc/subuid 2>/dev/null || sudo usermod --add-subuids 100000-165535 "$USER"
  grep -q "^$USER:" /etc/subgid 2>/dev/null || sudo usermod --add-subgids 100000-165535 "$USER"
fi

# ---------- user files (existing ones are backed up to <file>.bak-<ts>) ----------
TS=$(date +%Y%m%d%H%M%S)
install_tree() { # install_tree <srcdir> <dstdir>
  (cd "$1" && find . -type f) | while read -r f; do
    d="$2/$f"; mkdir -p "$(dirname "$d")"
    [[ -e $d ]] && ! cmp -s "$1/$f" "$d" && cp -a "$d" "$d.bak-$TS"
    cp "$1/$f" "$d"
  done
}
install_tree "$SRC/home" "$HOME"
(( OPT[nvim] )) && install_tree "$SRC/nvim" "$HOME/.config/nvim"
if (( OPT[agents] )); then
  for t in claude codex; do
    d="$HOME/.$t/agents"; mkdir -p "$d"
    (cd "$SRC/agents/$t" && for f in *; do sed "s|@HOME@|$HOME|g" "$f" > "$d/$f"; done)
  done
fi
CFG="$HOME/.config"
sed -i "s|@HOME@|$HOME|g" "$CFG/noctalia/config.toml"
if (( OPT[wallpapers] == 0 )); then
  # config points at wallpapers we didn't copy: switch Noctalia's wallpaper off instead of leaving a dead path
  sed -i '/^\[wallpaper\]/,/^enabled/ s/^enabled = true/enabled = false/' "$CFG/noctalia/config.toml"
else
  install_tree "$SRC/wallpapers" "$HOME/Pictures/Wallpapers"
fi

# tg-ws-proxy: autostart it (in its tray) only if the AUR install actually succeeded
command -v tg-ws-proxy >/dev/null && printf '    spawn-sh-at-startup "tg-ws-proxy"\n' >> "$CFG/niri/cfg/autostart.kdl"

# monitors: generated from what niri sees (now if a session is running, otherwise at first niri start)
"$HOME/.local/bin/niri-autodisplay" 2>/dev/null || true

# Noctalia notifications are pinned to DP-2: drop the pin if that output doesn't exist here
outs=$(for s in /sys/class/drm/card*-*/status; do
  [[ $(cat "$s" 2>/dev/null) == connected ]] && { n=${s%/status}; echo "${n#*/card*-}"; }; done; true)
grep -qx 'DP-2' <<<"$outs" || sed -i '/^monitors = \[ "DP-2" \]/d' "$CFG/noctalia/config.toml"

if command -v gsettings >/dev/null; then
  gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' || true
  gsettings set org.gnome.desktop.interface icon-theme 'Tela-circle-dracula' || true
  gsettings set org.gnome.desktop.interface cursor-theme 'capitaine-cursors' || true
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
  gsettings set org.gnome.desktop.interface font-name 'Adwaita Sans 11' || true
  gsettings set org.gnome.desktop.interface monospace-font-name 'Adwaita Mono 11' || true
fi

# cachy-update has no non-interactive flag, so it's not used for this script's own `update`;
# just wire up its tray applet + daily check for everyday OS updates
if command -v cachy-update >/dev/null; then
  cachy-update --tray --enable || true
  cachy-update --check --enable || true
fi

if command -v npm >/dev/null; then
  # user-owned prefix, no sudo: `sudo npm install -g` skips postinstall scripts as a safety
  # measure when run as root, and leaves root-owned files behind
  npm config get prefix | grep -qx "$HOME/.local" || npm config set prefix "$HOME/.local"
  # don't reinstall what's already there and working: re-running npm install -g re-triggers the
  # native-binary download, which is what breaks it on every `update` even when it was fine before
  for pkgcmd in "@anthropic-ai/claude-code:claude" "@openai/codex:codex"; do
    pkg=${pkgcmd%%:*}; cmd=${pkgcmd##*:}
    command -v "$cmd" >/dev/null && "$cmd" --version >/dev/null 2>&1 && continue
    npm install -g "$pkg" || echo "!! npm global install failed: $pkg"
  done
fi

if command -v fish >/dev/null; then
  fish -c 'type -q fisher; and fisher update' || true
  (( OPT[fishtheme] )) && { fish -c 'fish_config theme save catppuccin-mocha' || true; }
  [[ $SHELL == */fish ]] || chsh -s "$(command -v fish)" || true
fi

# ---------- Handy: AppImage from GitHub releases + settings ----------
if (( OPT[handy] )); then
  H="$HOME/.local/opt/handy"; mkdir -p "$H"
  ver=${HANDY_VERSION:-$(curl -fsSL https://api.github.com/repos/cjpais/Handy/releases/latest | sed -n 's/.*"tag_name": *"v\{0,1\}\([^"]*\)".*/\1/p' | head -1)}
  if [[ -n $ver ]] && curl -fL --retry 3 -o "$H/Handy.AppImage.part" \
       "https://github.com/cjpais/Handy/releases/download/v$ver/Handy_${ver}_amd64.AppImage"; then
    mv "$H/Handy.AppImage.part" "$H/Handy.AppImage"; chmod +x "$H/Handy.AppImage"
    ln -sf "$H/Handy.AppImage" "$HOME/.local/bin/handy"
    echo "Handy $ver installed"
    # settings only on first install, so an already-configured Handy isn't overwritten
    S="$HOME/.local/share/com.pais.handy/settings_store.json"
    if [[ ! -e $S ]]; then mkdir -p "$(dirname "$S")"; sed "s|@HOME@|$HOME|g" "$SRC/handy/settings_store.json" > "$S"; fi
    printf '    spawn-sh-at-startup "$HOME/.local/bin/handy"\n' >> "$CFG/niri/cfg/autostart.kdl"
  else
    echo "!! Handy download failed (version '${ver:-?}'); rerun with HANDY_VERSION=x.y.z or --no-handy"
    OPT[handy]=0
  fi
fi
# no Handy -> drop its keybinds so Ctrl+Space isn't swallowed by a dead binding
(( OPT[handy] )) || sed -i '/Handy/d' "$CFG/niri/cfg/keybinds.kdl"

# ---------- greeter (greetd + ReGreet in a mini niri session) ----------
if (( OPT[greeter] )); then
  sudo install -Dm644 "$SRC/etc/greetd/config.toml"  /etc/greetd/config.toml
  sudo install -Dm644 "$SRC/etc/greetd/regreet.toml" /etc/greetd/regreet.toml
  sudo install -Dm644 "$SRC/etc/greetd/greet.jpg"    /usr/share/backgrounds/greet.jpg
  tmp=$(mktemp); first=""
  { echo '// generated by install.sh: greeter niri session'
    for o in $(grep -E '^(DP|HDMI|eDP|DVI|VGA)-' <<<"$outs"); do
      [[ -z $first ]] && first=$o
      echo "output \"$o\" {"; [[ $o == "$first" ]] && echo '  focus-at-startup'; echo '  backdrop-color "#1e1e2e"'; echo '}'
    done
    echo "window-rule {"; echo "  match at-startup=true"; echo "  open-on-output \"${first:-DP-1}\""; echo "}"
    sed -n '/^spawn-sh-at-startup/,$p' "$SRC/etc/greetd/niri.kdl"
  } > "$tmp"
  sudo install -Dm644 "$tmp" /etc/greetd/niri.kdl; rm -f "$tmp"
  sudo systemctl disable sddm gdm lightdm ly 2>/dev/null || true
  sudo systemctl enable -f greetd.service
fi

cat <<'MSG'

Done. Log out/reboot, then inside niri run once:
  noctalia msg templates-apply     # regenerates wezterm/gtk/starship/niri colors from the palette
Backups of overwritten files: *.bak-<timestamp>
Handy: pick/download a speech model in its window on first start (models are not in the repo, ~1.8 GB for mine).
MSG
