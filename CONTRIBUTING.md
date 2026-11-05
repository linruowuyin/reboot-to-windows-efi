# 贡献指南

感谢参与。这个项目很小，但有几处约定值得说清楚。

## 开发环境

```bash
git clone https://github.com/linruowuyin/boot-windows.git
cd boot-windows
```

不需要额外的构建步骤 —— `boot-windows` 是单个 Bash 脚本，`install/install.sh` 是安装器。

## 提交前必做

```bash
bash -n boot-windows install/install.sh   # 语法检查
shellcheck -S warning boot-windows install/install.sh
```

CI 会跑同样的检查。`shellcheck` 的 `warning` 及以上级别必须为零告警。

## 代码约定

- **`set -euo pipefail`** —— 所有脚本必须开启
- **不要硬编码机器专属路径** —— 分区设备路径、用户名等一律通过环境变量或自动探测获取
- **破坏性操作前先确认** —— 写 EFI 变量、改引导配置这类操作要能被 `--dry-run` 完整预览
- **注释解释"为什么"，不解释"是什么"** —— 尤其是绕过某个坑的时候，要写清楚坑是什么

## 平台范围

主要面向 **Arch 系 + UEFI + GRUB**，但代码本身不依赖任何发行版专有工具。

新增功能时请保持：

- 不依赖 `os-prober`（它的输出顺序不稳定）
- 不依赖 `systemd-boot`（那是另一类用户）
- 固件交互只通过 `efibootmgr`

## 提交信息

用祈使句描述改动本身：

```
fix: 按 bootmgfw.efi 路径兜底匹配启动项
feat: 支持 WINDOWS_PART 指定休眠检测分区
docs: 补充 BootNext 与 BootOrder 的区别
```

## 报告问题

请附上：

```bash
efibootmgr -v
boot-windows --status
uname -r
```

`efibootmgr -v` 的输出包含分区 GUID 等信息，如果介意可以先打码。
