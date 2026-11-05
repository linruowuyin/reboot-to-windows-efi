# boot-windows

在 Linux 上，一键**临时**切到 Windows —— 不用进 GRUB 菜单手动选。

Linux 仍然是你系统的默认启动项。这只是一次性切换：从 Windows 再开机会自动回到 Linux。

```
┌─── 正常开机 ───►  Linux（BootOrder 首位）
│
└─── 点「重启到 Windows」──► 固件直接跳到 Windows（跳过 GRUB 菜单）
                                    │
                                    └─── 在 Windows 里再开机 ───► 自动回到 Linux ✓
```

## 为什么用 EFI BootNext

UEFI 固件下次启动时会优先执行 `BootNext` 变量指向的启动项，**用完即弃**。

- **快**：固件直接跳转，完全跳过 GRUB 的倒计时菜单
- **一次性**：不影响默认启动顺序，Windows 里重启一次就回 Linux
- **安全**：如果 `BootNext` 指向的项失效，固件会自动回退到 `BootOrder`（你的 Linux）

> **为什么不�� `systemctl reboot --boot-loader-entry`？**
> 那个命令只认 systemd-boot / BLS。GRUB 用户用不了（实测报 `No boot loader entries discovered`）。
> 所以这里走 `efibootmgr --bootnext`。

## 安装

### Arch / CachyOS

```bash
sudo pacman -S efibootmgr
git clone https://github.com/<你的用户名>/boot-windows.git
cd boot-windows
./install/install.sh
```

安装脚本会：

1. 把 `boot-windows` 装到 `~/.local/bin/`
2. 如果检测到 [Noctalia](https://github.com/noctalia-app/noctalia-shell)，把「重启到 Windows」加进它的会话菜单

### 手动安装

```bash
install -m 0755 boot-windows ~/.local/bin/boot-windows
```

## 用法

```bash
boot-windows              # 设置 BootNext → Windows，然后重启
boot-windows --no-reboot  # 只设置 BootNext，不重启
boot-windows --gui        # 弹确认框（zenity）
boot-windows --status     # 查看启动项 / BootNext 状态
boot-windows --restore    # 清除 BootNext（下次开机回 Linux）
boot-windows --dry-run    # 只显示会做什么，不动手
```

## 接入桌面会话菜单

### Noctalia

`install/install.sh` 会自动配置。手动配置的话，在 `~/.config/noctalia/noctalia-config.toml` 里加：

```toml
[[shell.session.actions]]
action = "command"
command = "/home/你的用户名/.local/bin/boot-windows --gui --yes"
countdown_seconds = 3.0
enabled = true
glyph = "brand-windows-filled"
label = "重启到 Windows"
lockscreen_shortcut = ""
shortcut = "6"
variant = "secondary"
```

> **踩坑提示**（如果你要自己改）：
> - action 类型值是 **`command`**，不是 `custom`。写成 `custom` 会被静默跳过，按钮根本不渲染。
> - `enabled = true` 必须有，默认是 `false` 的占位槽。
> - 超过 6 项时单行会溢出被裁剪，加 `[shell.session]` `grid = true` + `grid_columns = 3`。
> - `glyph` 必须是字体里真实存在的字形名（`noctalia-tabler.ttf`），可用 `brand-windows-filled`。
> - Noctalia 的 `PATH` 里没有 `~/.local/bin`，**必须写绝对路径**。

### 其它桌面环境

写个 `.desktop` 放 `~/.local/share/applications/` 即可：

```ini
[Desktop Entry]
Type=Application
Name=重启到 Windows
Exec=/home/你的用户名/.local/bin/boot-windows --gui
Icon=preferences-system
Terminal=false
Categories=System;
```

## 权限

脚本会写 EFI 变量（需要 root）。两种方式：

1. **免密 sudo**（推荐，零配置）—— 在 sudoers 里加一行：

   ```
   <你的用户名> ALL=(ALL) NOPASSWD: /usr/bin/sh
   ```

   注意：**不要**写成 `/usr/bin/sh ""`。man sudoers 里 `""` 表示"只允许无参数调用"，会把带参数的调用全挡掉。

2. **交互式 sudo** —— 不配 sudoers 也能用，脚本会自动回退到输入密码。

重启走 `systemctl reboot`，不依赖 polkit 认证 agent（Wayland 桌面下 polkit agent 常常没跑）。

## 环境变量

| 变量 | 默认 | 说明 |
|---|---|---|
| `WINDOWS_PART` | 自动探测 | 指定要检测休眠状态的 NTFS 分区 |
| `REBOOT_DELAY` | `3` | 重启前等待秒数，留出通知显示时间 |

## 常见问题

### 切过去后 Windows 显示"恢复会话"而不是冷启动

Windows 的快速启动（Fast Startup）会让 NTFS 保持锁定状态。在 Windows 里以管理员身份开 PowerShell：

```powershell
powercfg /h off
```

脚本会在切换前检测并提示（读 NTFS boot sector 第 4 字节，`0xC1` = 处于休眠态）。

### 找不到 Windows 启动项

脚本按两种方式找：先按描述 `Windows Boot Manager`，找不到就按启动文件 `bootmgfw.efi` / `microsoft` 路径匹配（不受固件语言影响）。

如果都找不到，说明固件里没有 Windows 启动项 —— 在固件设置里手动建一个。

### 会不会改坏默认启动顺序？

不会。脚本只写 `BootNext`，**从不修改 `BootOrder`**。`boot-windows --status` 可以随时确认。

## License

MIT
