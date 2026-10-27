#!/usr/bin/env bash
# Standalone installer: niri + Noctalia (Catppuccin Lavender), wezterm, fish+starship, greetd/ReGreet,
# wallpapers, Handy (speech-to-text). Arch/CachyOS only. Run as a normal user; sudo is asked when needed.
# Optional parts are asked interactively; without a TTY or with --yes the defaults [Y/n] are used.
#   ./install.sh [--yes] [--no-pkgs] [--no-greeter] [--no-handy] [--no-wallpapers] [--fish-theme]
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ $EUID -ne 0 ]] || { echo "run as normal user, not root"; exit 1; }
command -v pacman >/dev/null || { echo "pacman not found: Arch-based only"; exit 1; }

YES=0; [[ -t 0 ]] || YES=1
declare -A OPT   # name -> 1/0, preset by flags
for a in "$@"; do case $a in
  --yes) YES=1;; --no-pkgs) OPT[pkgs]=0;; --no-greeter) OPT[greeter]=0;; --no-handy) OPT[handy]=0;;
  --no-wallpapers) OPT[wallpapers]=0;; --fish-theme) OPT[fishtheme]=1;;
  *) echo "unknown arg: $a"; exit 1;; esac; done

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
ask fishtheme  "Apply Catppuccin Mocha colors to fish syntax highlighting?" n

REPO_PKGS=(python niri noctalia cachyos-niri-noctalia wezterm fish fisher starship eza bat fastfetch ugrep direnv
  adw-gtk-theme capitaine-cursors catppuccin-gtk-theme-mocha ttf-jetbrains-mono-nerd adwaita-fonts
  noto-fonts noto-fonts-emoji polkit-kde-agent xwayland-satellite xdg-desktop-portal-gnome
  xdg-desktop-portal-gtk gnome-keyring wl-clipboard curl)
(( OPT[greeter] )) && REPO_PKGS+=(greetd greetd-regreet plymouth)
(( OPT[handy] ))   && REPO_PKGS+=(fuse2 wtype xdotool)
AUR_PKGS=(tela-circle-icon-theme-dracula)

if (( OPT[pkgs] )); then
  sudo pacman -Syu --needed --noconfirm "${REPO_PKGS[@]}" || {
    # names differ between repos; retry one by one so a single miss doesn't abort
    for p in "${REPO_PKGS[@]}"; do sudo pacman -S --needed --noconfirm "$p" || echo "!! skipped $p"; done; }
  helper=$(command -v paru || command -v yay || true)
  if [[ -n $helper ]]; then "$helper" -S --needed --noconfirm "${AUR_PKGS[@]}" || echo "!! AUR failed: ${AUR_PKGS[*]}"
  else echo "!! no AUR helper: install manually: ${AUR_PKGS[*]}"; fi
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
CFG="$HOME/.config"
sed -i "s|@HOME@|$HOME|g" "$CFG/noctalia/config.toml"
if (( OPT[wallpapers] == 0 )); then
  # config points at wallpapers we didn't copy: switch Noctalia's wallpaper off instead of leaving a dead path
  sed -i '/^\[wallpaper\]/,/^enabled/ s/^enabled = true/enabled = false/' "$CFG/noctalia/config.toml"
else
  install_tree "$SRC/wallpapers" "$HOME/Pictures/Wallpapers"
fi

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
