<div align="center">
  <img src="docs/images/dayflow_header.png" alt="Dayflow" width="380">

  <p><strong>一款面向 Mac 的本地优先自动化工作日志。</strong></p>

  <p>
    Dayflow 会理解你在 Mac 上的工作内容，并自动整理成清晰的每日时间线。
    它从一开始就以隐私为设计前提，开源、优先本地化，并可完全运行在本地 AI 下。
  </p>

  <p>
    <a href="https://trendshift.io/repositories/17458" target="_blank" rel="noreferrer">
      <img src="https://trendshift.io/api/badge/repositories/17458" alt="JerryZLiu/Dayflow | Trendshift" width="250" height="55">
    </a>
  </p>

  <p>
    <a href="https://dayflow.so/api/download?source=github_readme_top">
      <img src="docs/images/download_dayflow_button.png" alt="在 Mac 下载 Dayflow" width="352">
    </a>
  </p>
</div>

## 自动时间线

Dayflow 会将原始屏幕活动转化为按时间顺序的日常记录，帮助你不依赖计时器和手写笔记，也能完整还原一天的工作过程。

<p align="center">
  <img src="docs/images/hero_animation_1080p.gif" alt="Dayflow 自动时间线界面" width="900">
</p>

## 每日站会

你可以看到类似 GitHub 风格的当日活动网格，并自动呈现昨日高亮、今日优先级与阻塞项，直接进入站会场景。

<p align="center">
  <img src="docs/images/daily.png" alt="Dayflow 每日视图和站会页" width="900">
</p>

## 周度回顾

快速查看本周全景：哪些时间段高效、时间主要花在哪里、哪些应用占比最高、哪些行为导致偏离计划。

<p align="center">
  <img src="docs/images/weekly.png" alt="Dayflow 周报与分析视图" width="900">
</p>

## 与工作日志对话

你可以直接围绕“今天/本周/全年”提问，由时间线驱动回答，而不是反复翻笔记、截图或记忆。

<p align="center">
  <img src="docs/images/chat.gif" alt="Dayflow 对话功能回答工作日问题" width="900">
</p>

## Dayflow 能做什么

Dayflow 在后台静默运行，并基于你的屏幕活动构建可用的工作记录。

| 功能 | 实现方式 | 为什么有用 |
| --- | --- | --- |
| 自动时间线 | Dayflow 以轻量截图片段抓取屏幕内容，通过你选择的 AI 提供商分析后生成活动卡片。 | 无需手工开工时计时器或写备注，即可获得更准确的工作日志。 |
| 上下文感知摘要 | 不只看应用名，而是分析你在屏幕上实际在做的事情。 | 像 Cursor、Chrome、YouTube、Slack 等都能转为明确的工作上下文。 |
| 每日站会 | 从时间线提取昨日重点、今日任务与阻塞项。 | 你可以更快产出更新，减少依赖记忆。 |
| 与日志对话 | 围绕时间线和最近活动进行自然语言提问。 | 可以快速找回细节、解释时间去向，并从原始活动提炼结论。 |
| 周度复盘 | 将时间线聚合为专注模式、类别、应用使用和交互图。 | 一眼看懂一周状态，发现帮助或拖累效率的行为习惯。 |
| 分心追踪 | 自动识别分散注意力的时段，并与专注时段并列显示。 | 无需手动标注休息，即可提前发现偏移。 |
| 时间线导出 | 支持按日期范围导出 Markdown。 | 便于状态汇报、客户说明、个人复盘或保存可检索记录。 |
| 本地优先存储 | 录屏、时间线数据、应用数据库默认保存在本机。 | 你可完全掌控敏感屏幕记录，并随时清理。 |
| AI 提供商选择 | 支持本地模型、Gemini、ChatGPT 或 Claude（按隐私与质量需求自由选择）。 | 在隐私、成本、速度与效果之间灵活取舍。 |
| 自动清理 | 配置存储上限，自动清理旧录屏。 | 享受日志价值，不会无限占用磁盘。 |

## 为什么值得使用

多数时间追踪工具只告诉你“打开了哪个应用”，Dayflow 更关心“你正在做什么”。

你在 Cursor 中持续两小时，可能是交付功能、调试鉴权、审查 PR，或卡在环境配置。Dayflow 尝试恢复真实语境，而不只是窗口标题。

## 隐私

Dayflow 是本地优先且开源的项目。

你的录屏、时间线和数据库默认存储在本机：

```text
~/Library/Application Support/Dayflow/
```

你可以选择以下 AI 分析方式：

- 通过 Ollama 或 LM Studio 运行本地模型
- 使用 Gemini 并配置自己的 API Key
- 通过本地 CLI 使用 ChatGPT 或 Claude

如果使用云端提供商，分析所需活动数据会发送给该服务；选择本地模型时，分析过程则保持在本机完成。

## 安装

### 下载

在 GitHub Releases 下载最新版 `Dayflow.dmg`：

<p>
  <a href="https://dayflow.so/api/download?source=github_readme_install">
    <img src="docs/images/download_dayflow_button.png" alt="在 Mac 下载 Dayflow" width="352">
  </a>
</p>

打开 DMG 后将 Dayflow 拖入 Applications，并在提示时授予 macOS 屏幕与系统音频录制权限。

### Homebrew

```bash
brew install --cask dayflow
```

## 系统要求

- macOS 14+
- macOS 屏幕录制与系统音频录制权限
- 可选：Gemini API Key、Ollama、LM Studio、Codex CLI 或 Claude Code（按你选择的 AI 提供商）

## 从源码构建

```bash
git clone https://github.com/JerryZLiu/Dayflow.git
cd Dayflow
open Dayflow/Dayflow.xcodeproj
```

在 Xcode 中选择 Dayflow scheme 并运行。

## 参与贡献

欢迎提交 Issue 和 Pull Request。若是较大改动，建议先开 Issue 明确需求范围。

## 许可证

Dayflow 使用 MIT 许可证。
