# TUIC v5 One-Click Installer

> Probably the best TUIC v5 one-click installer. | 可能是最好用的 TUIC v5 一键安装脚本。

[English](#english) | [中文](#中文)

---

<a name="english"></a>

## English

A one-click installation & management script for [TUIC v5](https://github.com/EAimTY/tuic) proxy server on Linux.

### Features

- Automatic architecture detection (x86_64 / aarch64 / armv7 / i686)
- Self-hosted binary mirror — no dependency on upstream repo availability
- Self-signed certificate generation
- Systemd service with auto-start on boot
- Interactive & non-interactive (headless) installation modes
- **`tuic` shortcut command** — manage TUIC anytime by just typing `tuic`
- Built-in management: reinstall / modify / uninstall / show info / status / restart
- Outputs ready-to-use client URL (NekoBox / v2rayN / Clash Meta)
- All prompts in Chinese for ease of use

### Requirements

- Linux (Ubuntu / Debian / CentOS / RHEL)
- Root privileges
- Open UDP port on firewall (TUIC uses QUIC/UDP)

### Quick Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ccj241/tuic-v5-installer/main/tuic-installer.sh)
```

### Non-Interactive Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ccj241/tuic-v5-installer/main/tuic-installer.sh) --auto
```

Port and password will be randomly generated.

### Management

After installation, simply type `tuic` to open the management menu:

```
TUIC 已安装，请选择操作:

  1) 重新安装
  2) 修改配置 (端口/密码)
  3) 卸载
  4) 查看连接信息
  5) 查看运行状态
  6) 重启服务
  0) 退出
```

### Client Configuration

After installation, the script outputs a URL like:

```
tuic://UUID:PASSWORD@SERVER_IP:PORT/?congestion_control=bbr&alpn=h3,spdy/3.1&udp_relay_mode=native&allow_insecure=1
```

Import this URL directly into your client:

| Client | Platform |
|--------|----------|
| NekoBox / NekoRay | Windows / Linux / Android |
| v2rayN | Windows |
| Clash Meta (mihomo) | Cross-platform |
| Shadowrocket | iOS |
| Surge | iOS / macOS |

### Service Commands

```bash
systemctl status tuic      # Check status
systemctl restart tuic     # Restart
systemctl stop tuic        # Stop
journalctl -u tuic -f      # View logs
```

### File Locations

| File | Path |
|------|------|
| Binary | `/root/tuic/tuic-server` |
| Config | `/root/tuic/config.json` |
| Certificate | `/root/tuic/ca.crt` |
| Private Key | `/root/tuic/ca.key` |
| Systemd Service | `/etc/systemd/system/tuic.service` |
| Shortcut Command | `/usr/local/bin/tuic` |

---

<a name="中文"></a>

## 中文

可能是最好用的 [TUIC v5](https://github.com/EAimTY/tuic) 代理服务端一键安装脚本。

### 功能特性

- 自动检测系统架构（x86_64 / aarch64 / armv7 / i686）
- 自建二进制镜像，不依赖上游仓库可用性
- 自动生成自签名 SSL 证书
- 创建 systemd 服务，开机自启
- 支持交互式和非交互式（无人值守）安装
- **安装后输入 `tuic` 即可管理**，无需记住脚本路径
- 内置管理功能：重装 / 修改配置 / 卸载 / 查看连接信息 / 查看状态 / 重启服务
- 安装完成后直接输出客户端导入链接
- 全中文提示，使用更友好

### 系统要求

- Linux（Ubuntu / Debian / CentOS / RHEL）
- Root 权限
- 防火墙需放行对应 UDP 端口（TUIC 基于 QUIC/UDP）

### 一键安装

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ccj241/tuic-v5-installer/main/tuic-installer.sh)
```

### 无人值守安装

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ccj241/tuic-v5-installer/main/tuic-installer.sh) --auto
```

端口和密码将自动随机生成。

### 安装后管理

安装完成后，随时输入 `tuic` 即可打开管理菜单：

```
TUIC 已安装，请选择操作:

  1) 重新安装
  2) 修改配置 (端口/密码)
  3) 卸载
  4) 查看连接信息
  5) 查看运行状态
  6) 重启服务
  0) 退出
```

### 客户端配置

安装完成后，脚本会输出如下格式的链接：

```
tuic://UUID:PASSWORD@SERVER_IP:PORT/?congestion_control=bbr&alpn=h3,spdy/3.1&udp_relay_mode=native&allow_insecure=1
```

直接复制到客户端导入即可：

| 客户端 | 平台 |
|--------|------|
| NekoBox / NekoRay | Windows / Linux / Android |
| v2rayN | Windows |
| Clash Meta (mihomo) | 全平台 |
| Shadowrocket | iOS |
| Surge | iOS / macOS |

### 服务管理命令

```bash
systemctl status tuic      # 查看状态
systemctl restart tuic     # 重启服务
systemctl stop tuic        # 停止服务
journalctl -u tuic -f      # 查看日志
```

### 文件位置

| 文件 | 路径 |
|------|------|
| 可执行文件 | `/root/tuic/tuic-server` |
| 配置文件 | `/root/tuic/config.json` |
| 证书 | `/root/tuic/ca.crt` |
| 私钥 | `/root/tuic/ca.key` |
| 系统服务 | `/etc/systemd/system/tuic.service` |
| 快捷命令 | `/usr/local/bin/tuic` |

---

## License

MIT

## Credits

- [TUIC Protocol](https://github.com/EAimTY/tuic) by EAimTY
