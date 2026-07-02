# Chinese UI Localization Inventory

> 用于记录中文化任务清点与剩余英文待处理项。

## 当前状态（2026-07-01）

- 基线脚本：`scripts/audit-ui-english.sh`
- allowlist：`scripts/ui-english-allowlist.txt`
- 尚未完成中文化清单：待 `bash scripts/audit-ui-english.sh` 扫描后更新。

## T00 基线执行记录（2026-07-02）

- 运行命令：`bash scripts/audit-ui-english.sh`
- 执行范围：`Dayflow/Dayflow`（默认）
- 命中数量：`37`
- 处理结论：本次仅输出基线清单，未进行 Swift 文案修改，供后续 T01+ 任务逐步翻译。

### 当前剩余英文命中（可见文案优先）

- `Dayflow/Dayflow/App/DayflowApp.swift:267` `Check for Updates…`（待翻译：菜单/更新文案）
- `Dayflow/Dayflow/Views/Components/DayGoalFlowView.swift:203` `Yesterday’s review`（待翻译：标题/按钮）
- `Dayflow/Dayflow/Views/Components/DayGoalFlowView.swift:233` `Set today’s goals`（待翻译：入口按钮）
- `Dayflow/Dayflow/Views/Components/DayGoalHeader.swift:160` `Today’s targets`（待翻译：标题）
- `Dayflow/Dayflow/Views/Components/DayGoalHeader.swift:255` `Set today’s goals`（待翻译：入口按钮）
- `Dayflow/Dayflow/Views/Onboarding/APIKeyInputView.swift:93` `API Key 长度至少需要超过 10 个字符`（需确认：含保留品牌词，短语其余部分已中文）
- `Dayflow/Dayflow/Views/Onboarding/ChatCLIDetectionViews.swift:135` `Checking…`（待翻译：状态提示）
- `Dayflow/Dayflow/Views/Onboarding/ChatCLITestView.swift:19` `我们会给 CLI 发送一条简单的问题，确认它已可用且已登录。`（待确认：可见文案，含 CLI 保留术语）
- `Dayflow/Dayflow/Views/Onboarding/LLMProviderSetupView.swift:172` `选择本地 AI 引擎`（待确认：术语“AI”保留，描述需统一）
- `Dayflow/Dayflow/Views/Onboarding/LLMProviderSetupView.swift:544` `打开 Google AI Studio`（待翻译：动词+品牌名）
- `Dayflow/Dayflow/Views/Onboarding/LLMProviderSetupView.swift:547` `(aistudio.google.com)`（保留：URL）
- `Dayflow/Dayflow/Views/Onboarding/LLMProviderSetupView.swift:562` `在右上角点击“获取 API key”`（待确认：API Key 统一大小写）
- `Dayflow/Dayflow/Views/Onboarding/LLMProviderSetupView.swift:573` `生成新 API Key 并复制`（待确认：API Key 统一大小写）
- `Dayflow/Dayflow/Views/Onboarding/LLMProviderSetupView.swift:587` `打开 Google AI Studio`（待翻译：动词+品牌名）
- `Dayflow/Dayflow/Views/Onboarding/LocalLLMTestView.swift:123` `API Key（可选）`（待确认：API Key 统一大小写）
- `Dayflow/Dayflow/Views/Onboarding/OnboardingCategoryStepView.swift:77` `“\(category.name)” will be removed from your onboarding categories.`（待翻译：确认提示）
- `Dayflow/Dayflow/Views/Onboarding/OnboardingFlow.swift:898` `开启e quick question`（需修正文案错误拼写并中文化）
- `Dayflow/Dayflow/Views/UI/BugReportView.swift:67` `加入 Discord 社区`（待确认：Discord 品牌名保留，前置动词可保留中文）
- `Dayflow/Dayflow/Views/UI/ChatView+Content.swift:177` `清除 log`（待确认：可视化文案建议中文化为“清除日志”）
- `Dayflow/Dayflow/Views/UI/DailyAccessLockedViews.swift:121` `选择你的 Daily 提供商`（待翻译：Daily 统一翻译/保留规则）
- `Dayflow/Dayflow/Views/UI/DailyView+Provider.swift:83` `选择 Daily 如何生成复盘，或关闭生成功能。`（同上）
- `Dayflow/Dayflow/Views/UI/JournalDayView.swift:964` `Summarizing your day recorded on your timeline…`（待翻译：处理中提示）
- `Dayflow/Dayflow/Views/UI/JournalReminders.swift:212` `测试: Set your intentions`（待翻译：调试/提示文案）
- `Dayflow/Dayflow/Views/UI/JournalView.swift:251` `开始 onboarding`（待翻译：首字母混写）
- `Dayflow/Dayflow/Views/UI/Settings/SettingsDataTabView.swift:164` `注意：这可能消耗大量 API 调用。`（待确认：含 API 保留词）
- `Dayflow/Dayflow/Views/UI/Settings/SettingsDataTabView.swift:191` `重新处理 day?`（待翻译：day 为英文缩写）
- `Dayflow/Dayflow/Views/UI/Settings/SettingsOtherTabView.swift:83` `English`（待翻译：语言开关候选词）
- `Dayflow/Dayflow/Views/UI/Settings/SettingsProvidersTabView.swift:119` `dayflow`（保留/待核对：项目品牌写法）
- `Dayflow/Dayflow/Views/UI/Settings/SettingsProvidersTabView.swift:536` `升级到 Qwen3VL，可显著提升质量。`（保留：模型名）
- `Dayflow/Dayflow/Views/UI/Settings/SettingsProvidersTabView.swift:559` `保留 Qwen2.5`（同上）
- `Dayflow/Dayflow/Views/UI/Settings/SettingsReferralProgramCard.swift:40` `Pro`（保留：品牌 SKU）
- `Dayflow/Dayflow/Views/UI/TimelineReviewOverlay.swift:236` `全部 caught up!`（待翻译：状态文案）
- `Dayflow/Dayflow/Views/UI/VideoPlayerModal.swift:252` `\(Int(viewModel.playbackSpeed * 20))x`（保留：倍率数值显示）
- `Dayflow/Dayflow/Views/UI/VideoPlayerModal.swift:694` `\(Int(viewModel.playbackSpeed * 20))x`（同上）
- `Dayflow/Dayflow/Views/UI/Weekly/Sections/WeeklyApplicationInteractionsSection.swift:141` `分心 and rabbit holes`（待翻译：短语中英文混写）
- `Dayflow/Dayflow/Views/UI/Weekly/Sections/WeeklyFocusHeatmapSection.swift:565` `\(cell空档, format: .number.precision(.fractionLength(1))) pt`（待确认：pt 为单位）
- `Dayflow/Dayflow/Views/UI/Weekly/Sections/WeeklySankeySection.swift:65` `Figma 基线`（待确认：Figma 及 brand/图表名）

## 处理原则

- 只翻译用户可见文案（标题、按钮、说明、提示、弹窗、状态文案）。
- 保留品牌名、命令、URL、provider raw value、模型名、analytics key、用户标识符、JSON key。
- 如确认为非用户可见文本，写入 allowlist 并注明原因。

## T01 配置与策略确认（2026-07-02）

- 目标：确认 T01 采用源码中文化，不引入运行时语言切换；仅在必要时最小化项目配置。
- 配置核验结果：
  - `Dayflow/Dayflow.xcodeproj/project.pbxproj`
    - `developmentRegion = en;`
    - `knownRegions = (en, Base);`
    - `LOCALIZATION_PREFERS_STRING_CATALOGS = YES;`（Debug/Release）
  - 仓库目前没有 `.lproj/.strings/.stringsdict/.xcstrings` 级别的中文化资源文件。
- 决策：
  - 继续采用“源码直改简体中文”策略，不新增语言切换逻辑，不修改 `project.pbxproj`。
  - 若后续决定引入 `.xcstrings`，再补充 `knownRegions` 与 target 资源打包校验。
- 验证命令：
  - `xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -showBuildSettings >/tmp/dayflow-build-settings.txt`
  - 结果：命令返回码 74，未成功生成可用的 build settings（包依赖解析阶段失败：`Operation not permitted` 写入 Package 缓存目录）。

## T09 全局剩余英文收口（2026-07-02）

- 目标：清理扫描脚本发现的剩余用户可见英文，并为保留项补齐 allowlist 原因。
- 已翻译：
  - Sparkle 更新菜单、待复盘卡片角标、分类环形图总计/单位、最长专注卡片、推荐来源反馈、时间线复盘摘要、Daily 入口文案、重试状态、开关无障碍状态、预览控件文案。
- allowlist 新增保留项：
  - `API`：技术术语，按计划保留。
  - `dayflow`：provider id / 内部路由标识。
  - `Qwen3VL`、`Qwen2.5`：模型名。
  - `Pro`：SKU / 品牌标识。
  - `\(Int(viewModel.playbackSpeed * 20))x`：播放倍率显示。
- 扫描结果：
  - `bash scripts/audit-ui-english.sh`：通过，无未分类英文。
- 剩余无法确认项：无。
