#!/usr/bin/env bash
# 一键安装 boot-windows（可选：顺带接入 noctalia 会话菜单）
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
NOCTALIA_CFG="${NOCTALIA_CFG:-$HOME/.config/noctalia/noctalia-config.toml}"

say()  { printf '\033[36m%s\033[0m\n' "$*"; }
ok()   { printf '\033[32m✓ %s\033[0m\n' "$*"; }
warn() { printf '\033[33m! %s\033[0m\n' "$*"; }
die()  { printf '\033[31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

# --- 前置检查 ---------------------------------------------------------------
command -v efibootmgr >/dev/null 2>&1 || die "缺少 efibootmgr（Arch: sudo pacman -S efibootmgr）"
[ -d /sys/firmware/efi ] || die "当前不是 UEFI 启动的系统，本工具用不了"

if ! efibootmgr -v 2>/dev/null | grep -qi "windows boot manager\|bootmgfw"; then
    warn "efibootmgr 里没看到 Windows 启动项。"
    warn "如果你装了 Windows 但没被固件识别，先在固件设置里手动建一个 Windows 启动项。"
fi

# --- 安装脚本 ---------------------------------------------------------------
mkdir -p "$BIN_DIR"
install -m 0755 "$SRC_DIR/boot-windows" "$BIN_DIR/boot-windows"
ok "已安装 $BIN_DIR/boot-windows"

# --- 可选：接入 noctalia 会话菜单 -------------------------------------------
if command -v noctalia >/dev/null 2>&1 && [ -f "$NOCTALIA_CFG" ]; then
    if grep -q 'label = "重启到 Windows"' "$NOCTALIA_CFG" 2>/dev/null; then
        ok "noctalia 会话菜单里已经有「重启到 Windows」了，跳过"
    else
        say "把「重启到 Windows」加进 noctalia 会话菜单……"
        NOCTALIA_CFG="$NOCTALIA_CFG" BIN_DIR="$BIN_DIR" python3 - <<'PY'
import os, re, sys

path = os.environ["NOCTALIA_CFG"]
bin_dir = os.environ["BIN_DIR"]
cmd = f"{bin_dir}/boot-windows --gui --yes"

with open(path, encoding="utf-8") as f:
    text = f.read()

entry = f'''[[shell.session.actions]]
action = "command"
command = "{cmd}"
countdown_seconds = 3.0
enabled = true
glyph = "brand-windows-filled"
label = "重启到 Windows"
lockscreen_shortcut = ""
shortcut = "6"
variant = "secondary"
'''

# 插到最后（追加到文件尾，noctalia 按顺序渲染）
if not text.endswith("\n"):
    text += "\n"
text += "\n" + entry

with open(path, "w", encoding="utf-8") as f:
    f.write(text)
print("  已写入配置")
PY
        noctalia msg config-reload >/dev/null 2>&1 || true
        ok "noctalia 会话菜单已更新"
    fi
else
    say "没检测到 noctalia，跳过菜单接入（脚本仍可命令行使用）"
fi

say ""
ok "完成。试试："
say "  boot-windows --status    查看状态"
say "  boot-windows --dry-run   看会做什么但不动手"
say "  boot-windows             切到 Windows"
