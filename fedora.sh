#!/usr/bin/env bash
set -euo pipefail
# Fedora Setup — Ryzen 7 7730U (lean)

echo "=== System update ==="
sudo dnf upgrade --refresh -y

echo "=== Happ Desktop ==="
[[ "$(uname -m)" == "x86_64" ]] || { echo "Happ: x86_64 only"; exit 1; }
curl -fL https://github.com/Happ-proxy/happ-desktop/releases/download/4.1.1/Happ.linux.x64.rpm -o /tmp/happ.rpm
sudo dnf install -y /tmp/happ.rpm && rm -f /tmp/happ.rpm

echo "=== GitHub CLI ==="
sudo dnf install -y gh
gh auth status >/dev/null 2>&1 || { gh auth login -p https -w; gh auth setup-git; }

echo "=== RPM Fusion ==="
sudo dnf install -y "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

echo "=== Packages ==="
sudo dnf copr enable -y atim/lazygit
sudo dnf copr enable -y sneed/llama-cpp-vulkan   # llama.cpp with Vulkan GPU accel (AMD)
sudo dnf install -y git curl neovim fontconfig unzip fzf jq kitty gcc \
  mesa-va-drivers-freeworld gamemode mangohud \
  mpv lazygit syncthing btop llama-cpp lm_sensors snapper \
  jetbrains-mono-fonts fedora-workstation-repositories

echo "=== Chrome ==="
sudo dnf config-manager setopt google-chrome.enabled=1
sudo dnf install -y google-chrome-stable

echo "=== LazyVim ==="
[[ -d ~/.config/nvim ]] || { git clone --depth 1 https://github.com/LazyVim/starter ~/.config/nvim; rm -rf ~/.config/nvim/.git; }

echo "=== Nerd Font ==="
mkdir -p ~/.local/share/fonts/JetBrainsMono
curl -fL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip -o /tmp/jbm.zip
unzip -oq /tmp/jbm.zip -d ~/.local/share/fonts/JetBrainsMono && rm -f /tmp/jbm.zip && fc-cache -f

echo "=== Kitty ==="
mkdir -p ~/.config/kitty
cat > ~/.config/kitty/kitty.conf <<'EOF'
font_family JetBrainsMono Nerd Font
bold_font JetBrainsMono Nerd Font
italic_font JetBrainsMono Nerd Font
bold_italic_font JetBrainsMono Nerd Font
font_size 13.0
enable_audio_bell no
confirm_os_window_close 0
allow_remote_control yes
disable_ligatures never
background_opacity 0.94
dynamic_background_opacity yes
window_padding_width 12
hide_window_decorations yes
draw_minimal_borders yes
cursor_shape beam
cursor_beam_thickness 2.0
cursor_blink_interval 0.6
tab_bar_edge top
tab_bar_style powerline
tab_powerline_style slanted
tab_title_template "{index}: {title}"
active_tab_font_style bold
inactive_tab_font_style normal
visual_bell_duration 0.0
map ctrl+shift+t launch --type=tab --cwd=current
map ctrl+shift+shift+t launch --type=tab --cwd=last_reported
map ctrl+shift+v launch --location=vsplit --cwd=current
map ctrl+shift+h launch --location=hsplit --cwd=current
map alt+1 goto_tab 1
map alt+2 goto_tab 2
map alt+3 goto_tab 3
map alt+4 goto_tab 4
map alt+5 goto_tab 5
map alt+6 goto_tab 6
map alt+7 goto_tab 7
map alt+8 goto_tab 8
map alt+9 goto_tab 9
map alt+0 launch --type=background $HOME/.local/bin/tabswitcher
foreground #CDD6F4
background #1E1E2E
selection_foreground #1E1E2E
selection_background #F5E0E6
cursor #F5E0E6
cursor_text_color #1E1E2E
url_color #89B4FA
active_tab_foreground #1E1E2E
active_tab_background #CBA6F7
inactive_tab_foreground #A6ADC8
inactive_tab_background #313244
color0 #45475A
color1 #F38BA8
color2 #A6E3A1
color3 #F9E2AF
color4 #89B4FA
color5 #F5C2E7
color6 #94E2D5
color7 #BAC2DE
color8 #585B70
color9 #F38BA8
color10 #A6E3A1
color11 #F9E2AF
color12 #89B4FA
color13 #F5C2E7
color14 #94E2D5
color15 #A6ADC8
EOF

mkdir -p ~/.local/bin
cat > ~/.local/bin/tabswitcher <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
for c in kitty jq fzf; do command -v "$c" >/dev/null || { echo "$c missing"; exit 1; }; done
[[ -n "${KITTY_WINDOW_ID:-}" ]] || { echo "Run inside Kitty"; exit 1; }
sel=$(kitty @ ls | jq -r '.[] | .tabs[] | [.id, (.title // "Untitled")] | @tsv' | fzf --height=40% --layout=reverse --border --prompt="Tabs> ") || exit 0
kitty @ focus-tab --match "id:${sel%%$'\t'*}"
EOF
chmod +x ~/.local/bin/tabswitcher

for rc in ~/.bashrc ~/.zshrc; do
  touch "$rc"
  grep -q new_tab_parent "$rc" || cat >> "$rc" <<'EOF'
new_tab() { kitty @ launch --type=tab --cwd="$PWD"; }
new_tab_parent() { kitty @ launch --type=tab --cwd="$(dirname "$PWD")"; }
alias tabswitcher="$HOME/.local/bin/tabswitcher"
EOF
done

echo "=== Syncthing ==="
systemctl --user enable --now syncthing

echo "=== Flatpaks ==="
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.spotify.Client com.discordapp.Discord org.telegram.desktop \
  md.obsidian.Obsidian com.usebottles.bottles org.vinegarhq.Sober \
  io.dbeaver.DBeaverCommunity
sudo dnf install llama-cpp

echo "=== RyzenAdj ==="
sudo dnf copr enable -y shdwchn10/ryzenadj
sudo dnf install -y ryzenadj
RYZENADJ_BIN="$(command -v ryzenadj)"
[[ -n "$RYZENADJ_BIN" ]] || { echo "ryzenadj not found"; exit 1; }
sudo tee /usr/local/sbin/ryzen-power-limit >/dev/null <<EOF
#!/usr/bin/env bash
set -euo pipefail
RYZENADJ_BIN="$RYZENADJ_BIN"
AC_STAPM=10000; AC_FAST=18000; AC_SLOW=15000
BATTERY_STAPM=8000; BATTERY_FAST=15000; BATTERY_SLOW=12000
ON_AC=0
for supply in /sys/class/power_supply/*; do
  [[ -d "\$supply" ]] || continue
  type="\$(cat "\$supply/type" 2>/dev/null || true)"
  if [[ "\$type" != "Battery" ]] && [[ "\$(cat "\$supply/online" 2>/dev/null || echo 0)" == "1" ]]; then ON_AC=1; break; fi
done
if [[ "\$ON_AC" == "1" ]]; then MODE="AC"; STAPM="\$AC_STAPM"; FAST="\$AC_FAST"; SLOW="\$AC_SLOW"
else MODE="Battery"; STAPM="\$BATTERY_STAPM"; FAST="\$BATTERY_FAST"; SLOW="\$BATTERY_SLOW"; fi
echo "Applying \$MODE limits: STAPM \$((STAPM/1000))W Fast \$((FAST/1000))W Slow \$((SLOW/1000))W"
"\$RYZENADJ_BIN" -a "\$STAPM" -b "\$FAST" -c "\$SLOW"
EOF
sudo chmod 755 /usr/local/sbin/ryzen-power-limit
sudo tee /etc/systemd/system/ryzen-power-limit.service >/dev/null <<'EOF'
[Unit]
Description=Set RyzenAdj power limits based on AC or battery state
After=multi-user.target
[Service]
Type=oneshot
ExecStart=/usr/local/sbin/ryzen-power-limit
EOF
sudo tee /etc/udev/rules.d/99-ryzen-power-limit.rules >/dev/null <<'EOF'
ACTION=="change", SUBSYSTEM=="power_supply", TAG+="systemd", ENV{SYSTEMD_WANTS}+="ryzen-power-limit.service"
EOF
sudo systemctl daemon-reload
sudo udevadm control --reload-rules
sudo systemctl enable --now ryzen-power-limit.service
sudo ryzenadj -i
sudo systemctl enable --now tuned

echo "=== Monitoring ==="
sudo snapper -c root create-config /
sudo snapper -c root create --description "Before changes"
sudo sensors-detect --auto

grep -q 'snapshots-list' ~/.bashrc || cat >> ~/.bashrc <<'EOF'
alias snapshots-list='sudo snapper -c root list'
alias makesnap='sudo snapper -c root create --description '
alias deletesnap='sudo snapper -c root delete '
mtop() {
  IF=$(ip route get 1.1.1.1 2>/dev/null | awk '{for (i=1;i<=NF;i++) if ($i=="dev") {print $(i+1); exit}}')
  while true; do
    clear
    echo "=== Ryzen power ==="; sudo ryzenadj --info | grep -E 'PPT VALUE|STAPM VALUE|THM VALUE'
    echo "=== Temperatures ==="; sensors 2>/dev/null | grep -Ei 'cpu|tctl|tdie|k10temp|edge|junction|amdgpu|gpu' || echo "No sensors"
    echo "=== RAM ==="; free -h | awk '/Mem:/ {printf "Used: %s / %s (%.1f%%)\n", $3, $2, ($3/$2)*100}'
    echo "=== CPU clock ==="; awk -F: '/cpu MHz/ {s += $2; n++} END {printf "Average: %.0f MHz\n", s/n}' /proc/cpuinfo
    echo "=== Network ($IF) ==="
    R1=$(cat "/sys/class/net/$IF/statistics/rx_bytes"); T1=$(cat "/sys/class/net/$IF/statistics/tx_bytes"); sleep 5
    R2=$(cat "/sys/class/net/$IF/statistics/rx_bytes"); T2=$(cat "/sys/class/net/$IF/statistics/tx_bytes")
    awk -v r=$((R2-R1)) -v t=$((T2-T1)) 'BEGIN {printf "Download: %.1f KB/s | Upload: %.1f KB/s\n", r/1024, t/1024}'
    sleep 1
  done
}
EOF

echo "=== /mnt/data ==="
DATA_UUID="93137e69-f559-468b-b045-57576895127c"
DATA_DEVICE="$(sudo blkid -U "$DATA_UUID" 2>/dev/null || true)"
[[ -n "$DATA_DEVICE" ]] || { echo "No device with UUID $DATA_UUID. Check: lsblk -f"; exit 1; }
DATA_FS="$(sudo blkid -o value -s TYPE "$DATA_DEVICE")"
[[ "$DATA_FS" == "ext4" ]] || { echo "$DATA_DEVICE is '$DATA_FS', not ext4"; exit 1; }
sudo mkdir -p /mnt/data
sudo cp /etc/fstab "/etc/fstab.backup.$(date +%Y%m%d-%H%M%S)"
sudo umount /mnt/data 2>/dev/null || true
sudo sed -i '\|[[:space:]]/mnt/data[[:space:]]|d' /etc/fstab
echo "UUID=$DATA_UUID /mnt/data ext4 defaults,nofail,x-gvfs-show 0 2" | sudo tee -a /etc/fstab >/dev/null
sudo findmnt --verify && sudo mount /mnt/data && findmnt /mnt/data


# ============ Sway (tiling WM) ============
echo "=== Installing Sway ==="
sudo dnf install -y sway swaylock swayidle swaybg foot wofi mako waybar \
  brightnessctl playerctl grim slurp wl-clipboard ranger \
  network-manager-applet xdg-desktop-portal-wlr

echo "=== Configuring Sway ==="
mkdir -p ~/.config/sway ~/Pictures
cat > ~/.config/sway/config <<'EOF'
# Sway config - Fedora style, Hyprland-like, no gaps
set $mod Mod4
set $term foot
set $menu wofi --show drun
set $lock swaylock -f -c 1a1b26

font pango:JetBrainsMono Nerd Font 10

default_border pixel 2
default_floating_border pixel 2
focus_follows_mouse no
gaps inner 0
gaps outer 0
smart_borders on

client.focused          #7aa2f7 #1a1b26 #c0caf5 #7aa2f7 #7aa2f7
client.focused_inactive #414868 #24283b #a9b1d6 #414868 #414868
client.unfocused        #24283b #1a1b26 #565f89 #24283b #24283b
client.urgent           #f7768e #1a1b26 #f7768e #f7768e #f7768e

output * bg ~/.config/sway/wallpaper.jpg fill
output * adaptive_sync on

bindsym $mod+Return exec $term
bindsym $mod+Q kill
bindsym $mod+D exec $menu
bindsym $mod+E exec $term -e ranger
bindsym $mod+B exec firefox
bindsym $mod+L exec $lock
bindsym $mod+Shift+C reload
bindsym $mod+Shift+E exec swaymsg exit

bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right
bindsym $mod+H focus left
bindsym $mod+J focus down
bindsym $mod+K focus up

bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right
bindsym $mod+Shift+H move left
bindsym $mod+Shift+J move down
bindsym $mod+Shift+K move up
bindsym $mod+Shift+L move right

bindsym $mod+V split v
bindsym $mod+C split h
bindsym $mod+F fullscreen toggle
bindsym $mod+A focus parent
bindsym $mod+S layout stacking
bindsym $mod+W layout tabbed
bindsym $mod+T layout toggle split
bindsym $mod+Space focus mode_toggle
bindsym $mod+Shift+Space floating toggle
bindsym $mod+Shift+Minus move scratchpad
bindsym $mod+Minus scratchpad show

bindsym $mod+1 workspace number 1
bindsym $mod+2 workspace number 2
bindsym $mod+3 workspace number 3
bindsym $mod+4 workspace number 4
bindsym $mod+5 workspace number 5
bindsym $mod+6 workspace number 6
bindsym $mod+7 workspace number 7
bindsym $mod+8 workspace number 8
bindsym $mod+9 workspace number 9
bindsym $mod+0 workspace number 10
bindsym $mod+Shift+1 move container to workspace number 1
bindsym $mod+Shift+2 move container to workspace number 2
bindsym $mod+Shift+3 move container to workspace number 3
bindsym $mod+Shift+4 move container to workspace number 4
bindsym $mod+Shift+5 move container to workspace number 5
bindsym $mod+Shift+6 move container to workspace number 6
bindsym $mod+Shift+7 move container to workspace number 7
bindsym $mod+Shift+8 move container to workspace number 8
bindsym $mod+Shift+9 move container to workspace number 9
bindsym $mod+Shift+0 move container to workspace number 10

bindsym XF86AudioRaiseVolume exec wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
bindsym XF86AudioLowerVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bindsym XF86AudioMute exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
bindsym XF86AudioMicMute exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
bindsym XF86MonBrightnessUp exec brightnessctl set +5%
bindsym XF86MonBrightnessDown exec brightnessctl set 5%-
bindsym XF86AudioPlay exec playerctl play-pause
bindsym XF86AudioNext exec playerctl next
bindsym XF86AudioPrev exec playerctl previous
bindsym Print exec grim -g "$(slurp)" ~/Pictures/$(date +%s).png

mode "resize" {
    bindsym Left resize shrink width 20px
    bindsym Down resize grow height 20px
    bindsym Up resize shrink height 20px
    bindsym Right resize grow width 20px
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym $mod+R mode "resize"

input type:keyboard {
    xkb_layout us
    xkb_options caps:escape
}
input type:touchpad {
    tap enabled
    natural_scroll enabled
}

exec swayidle -w timeout 600 '$lock' timeout 900 'swaymsg "output * dpms off"' resume 'swaymsg "output * dpms on"' before-sleep '$lock'
exec mako
exec nm-applet --indicator

bar {
    swaybar_command waybar
}
EOF

# Wallpaper fallback: solid color until you drop a wallpaper.jpg in place
if [[ ! -f ~/.config/sway/wallpaper.jpg ]]; then
    sed -i 's|^output \* bg .*|output * bg 1a1b26 solid_color|' ~/.config/sway/config
    echo "No wallpaper found — using solid color. Put one at ~/.config/sway/wallpaper.jpg"
fi




echo "=== Setup completed ==="
git config --global user.name 'KonuhovAND'
git config --global user.email 'andreykonuhov8@gmail.com'
ssh-keygen -t ed25519 -C "andreykonuhov8@gmail.com" -N "" -f ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
echo "Commands: tabswitcher | new_tab | new_tab_parent | mtop | makesnap | btop"
