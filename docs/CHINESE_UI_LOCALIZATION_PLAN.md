# 界面全量中文化方案评估与任务拆解

日期：2026-07-01

目标读者：GPT-5.3-Codex-Spark 执行代理、代码审核者、人工验收者

范围：将 Dayflow macOS 应用中面向用户可见的界面语言统一改为简体中文，并拆成可独立执行、可验证、可回滚的小任务。本文只做方案评估与任务拆解，不实现代码改动。

## 1. 结论

建议采用“中文界面直改 + 严格排除内部协议字段 + 静态扫描兜底”的执行路线，而不是第一阶段就做完整多语言切换框架。

原因：

1. 当前需求是“界面语言全部修改为中文”，不是“中英文可切换”。
2. 仓库当前没有 `.lproj`、`.strings`、`.stringsdict`、`.xcstrings` 本地化资源；现有 UI 文案主要散落在 SwiftUI 源码里。
3. Xcode 工程已经启用 `LOCALIZATION_PREFERS_STRING_CATALOGS = YES`，并使用 `PBXFileSystemSynchronizedRootGroup`，未来支持 String Catalog 成本可控，但第一阶段若同时做全量抽取会显著扩大风险。
4. 应用内存在大量 analytics key、UserDefaults key、provider id、模型名、URL、命令、日志前缀，不能被“英文扫描后一律翻译”误伤。

推荐分两阶段：

1. 第一阶段：把所有面向用户的 UI 文案改为简体中文，保持内部标识不变，补充扫描脚本和关键路径验证。
2. 第二阶段：如果后续需要多语言切换，再把已中文化文案迁入 `.xcstrings`，并添加 `zh-Hans` / `en` 资源。

## 2. 当前事实与风险

### 2.1 代码现状

- 项目是 macOS SwiftUI + AppKit 菜单栏应用，CLI 构建和测试入口见 `CLAUDE.md`。
- README 已经主要是中文，但应用内 UI 仍大量英文。
- 文件系统未发现 `.lproj`、`.strings`、`.stringsdict`、`.xcstrings`。
- `Dayflow/Dayflow.xcodeproj/project.pbxproj` 中：
  - `developmentRegion = en`
  - `knownRegions = (en, Base)`
  - `LOCALIZATION_PREFERS_STRING_CATALOGS = YES`
  - app / test target 使用文件系统同步组。
- 粗略静态扫描结果：
  - 直接 SwiftUI 用户界面字面量命中 77 个 Swift 文件。
  - 其中 `Views/UI` 约 49 个文件，`Views/Onboarding` 约 14 个文件，`Views/Components` 约 12 个文件，`Menu` 约 1 个文件。
  - 计算属性、默认数据、通知、错误文案等英文字符串命中约 106 个 Swift 文件，需要人工分辨是否用户可见。

### 2.2 已知高风险区域

1. Onboarding：长文案多，包含 provider、API key、权限、职业/下载原因/推荐码等用户流程。
2. Settings：账号、存储、隐私、AI provider、其他设置里有大量标题、说明、按钮、alert。
3. Main UI：sidebar、timeline、activity card、review overlay、pause pill、status menu、空态和日期选择。
4. Daily / Weekly / Journal / Chat：包含锁定态、图表标题、提示、导出/复制、beta、debug/memory panel。
5. 默认类别与 onboarding 职业预设：`TimelineCategory` 中默认类别名和说明是用户可见数据，也会传入 LLM 分类提示。
6. 通知和系统弹窗：`NotificationService`、Journal reminder test notification、storage/reprocess/provider 切换 alert。
7. accessibility/help：`.help(...)`、`.accessibilityLabel(...)` 是界面语义的一部分，必须中文化。

### 2.3 不能翻译的内容

以下内容必须保留英文或原格式，除非任务明确要求：

- 产品名和第三方品牌：Dayflow、Dayflow Pro、Gemini、ChatGPT、Claude、Claude Code、Codex CLI、Ollama、LM Studio、Qwen3-VL、Google AI Studio、GitHub、macOS、Xcode。
- API / 协议 / 存储标识：UserDefaults key、analytics event name、provider raw value、JSON field、URL、bundle id、keychain service、notification identifier。
- 命令和示例参数：`curl`、`codex auth`、`claude login`、model id、base URL、API key 示例、email placeholder。
- 调试日志前缀、测试 fixture、注释。
- 图标/asset 名称和 SF Symbol 名称。

## 3. 中文文案规范

1. 使用简体中文。
2. 默认用“你”，不要用“您”。
3. 保留 Dayflow 品牌名，组合词使用“Dayflow 时间线”“Dayflow 周报”“Dayflow Pro”。
4. 行为按钮短句优先：继续、返回、保存、重置、确认、取消、打开系统设置。
5. 页面标题使用名词短语：设置、时间线、每日复盘、周报、对话、日志。
6. 说明文案避免直译，优先自然中文。
7. 代码/命令/模型名保持英文原样。
8. 中文标点使用全角；括号可使用中文括号，代码和命令例外。
9. 单位统一：分钟、小时、天、GB。
10. 不要为了翻译改变业务语义、排序、ID、analytics 或持久化结构。

建议术语表：

| 英文 | 中文 |
| --- | --- |
| Timeline | 时间线 |
| Daily | 每日复盘 |
| Weekly | 周报 |
| Chat | 对话 |
| Journal | 日志 |
| Settings | 设置 |
| Recording | 录制 |
| Screen Recording | 屏幕录制 |
| Provider / Runtime | AI 提供商 / 运行方式 |
| Local AI | 本地 AI |
| API key | API Key |
| Recap | 复盘 |
| Standup | 站会更新 |
| Distraction | 分心 |
| Focus | 专注 |
| Idle | 空闲 |
| Storage | 存储 |
| Privacy | 隐私 |
| Referral code | 推荐码 |
| Access code | 访问码 |
| Unlock | 解锁 |

## 4. 执行总原则

每个 Spark 任务都必须遵守：

1. 开始前读取本文、`CLAUDE.md`、相关 Swift 文件；如果 `.codegraph/` 存在，先用 CodeGraph 理解涉及文件。
2. 只修改任务指定范围，不顺手重构 UI 结构。
3. 只翻译用户可见内容，不翻译内部 key、raw value、analytics、URL、命令、asset 名、test helper 名。
4. 修改后运行本任务指定的静态扫描和可用测试。
5. 若无法运行 GUI 或完整 Xcode 测试，必须在交付说明中写明“无法验证”的具体原因和已完成的替代验证。
6. 交付说明必须包含：修改文件列表、实现内容、验证结果、剩余英文命中、未解决问题。

建议每批提交大小：10 到 25 个 Swift 文件，优先按产品界面分组，不按机械搜索结果分组。

## 5. 可交给 Spark 的任务拆解

### T00：建立基线清单和扫描脚本

目标：先让后续任务有统一的“剩余英文”检查方式。

允许改动：

- `scripts/`
- `docs/`

建议实现：

1. 新增 `scripts/audit-ui-english.sh`。
2. 扫描 SwiftUI 入口：`Text("...")`、`Button("...")`、`Label("...")`、`TextField("...")`、`SecureField("...")`、`Toggle("...")`、`Picker("...")`、`.navigationTitle("...")`、`.help("...")`、`.accessibilityLabel("...")`、`.alert("...")`。
3. 扫描通知和 alert：`content.title = "..."`、`content.body = "..."`、`Alert(title: Text("..."))`。
4. 输出文件、行号、字符串内容，并支持 allowlist 文件，例如 `scripts/ui-english-allowlist.txt`。
5. 在 `docs/` 生成或更新一份剩余清单，例如 `docs/CHINESE_UI_LOCALIZATION_INVENTORY.md`。

验收标准：

- 脚本可在仓库根目录直接运行。
- 脚本不会把空结果误判为失败；有未处理英文时返回非零或明确输出 pending count。
- allowlist 中每条必须有原因：brand、command、internal-key、test-fixture、log、url、model-name。

验证命令：

```bash
bash scripts/audit-ui-english.sh
git diff -- docs scripts
```

### T01：中文化基础策略与项目配置检查

目标：确认第一阶段采用中文源码文案，不引入运行时语言切换；同时检查是否需要项目配置最小调整。

允许改动：

- `docs/`
- 如确需配置，限 `Dayflow/Dayflow.xcodeproj/project.pbxproj`

建议实现：

1. 不强制新增 `.xcstrings`，除非执行中发现必须通过资源解决。
2. 不修改 analytics、provider、UserDefaults、URL 等内部标识。
3. 如果新增 String Catalog，则必须确认 target 能打包资源，并将 `zh-Hans` 加入 `knownRegions`；否则不要做 project 配置改动。
4. 在 docs 中记录最终选择。

验收标准：

- 后续任务能依据统一规范判断“翻译/不翻译”。
- 如果修改 project 文件，`xcodebuild` 至少能解析工程。

验证命令：

```bash
xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -showBuildSettings >/tmp/dayflow-build-settings.txt
```

### T02：Onboarding 主流程中文化

目标：中文化新用户首次启动路径。

允许改动：

- `Dayflow/Dayflow/Views/Onboarding/`
- `Dayflow/Dayflow/Views/Onboarding/Prototype/`
- 必要时 `Dayflow/Dayflow/Views/Components/ProviderCardComponents.swift`

覆盖内容：

- LLM 选择页、provider setup、API key 输入、CLI 检测与测试、local LLM 测试、安装指引。
- How it works、视频引导、下载原因、职业选择、推荐码、偏好选择、完成页。
- Screen Recording 权限引导。
- placeholder、按钮、alert、error/status label、help/accessibility label。

保留内容：

- Codex CLI、Claude Code、Gemini、Ollama、LM Studio、Google AI Studio、Qwen3-VL 等品牌/工具名。
- 终端命令、模型 ID、URL、API key 示例。
- analyticsName、rawValue、UserDefaults key。

验收标准：

- fresh onboarding 全路径无英文 UI，允许品牌、命令、模型名。
- 错误状态和“未安装/已安装/检查中”状态中文化。
- 长中文文案不挤压按钮、不截断主流程内容。

验证命令：

```bash
bash scripts/audit-ui-english.sh Dayflow/Dayflow/Views/Onboarding
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig \
  GIT_ALLOW_PROTOCOL=file:https \
  xcodebuild test -project Dayflow/Dayflow.xcodeproj -scheme Dayflow \
  -destination 'platform=macOS' \
  -derivedDataPath build/test-derived
```

手工验证：

- 重置 onboarding 状态后启动 app，逐页截图或记录：欢迎/视频、职业、下载原因、provider、API key/CLI/local、类别、权限、完成页。

### T03：默认类别、职业预设与分类文案中文化

目标：中文化用户可见默认分类和说明，同时避免破坏历史用户数据与 LLM 分类逻辑。

允许改动：

- `Dayflow/Dayflow/Models/TimelineCategory.swift`
- 直接依赖类别展示/编辑的组件：`Dayflow/Dayflow/Views/Components/TimelineCardColorPicker.swift`、`Dayflow/Dayflow/Views/Components/CategoryPickerView.swift`、`CategoryPickerOverlay.swift`、`DayCategorySelectionEditor.swift`
- 必要测试文件

覆盖内容：

- 默认类别：Work、Personal、Distraction、Idle。
- onboarding preset 类别名与 details。
- 新建类别默认名，例如 `New category`。
- 类别编辑 UI 里的标题、说明、按钮、accessibility label。

关键风险：

- `DayGoalPlan.defaultPlan` 当前通过英文 `distraction` / `distractions` 判断分心类别；中文化后必须支持中文“分心”等同义词，不能只依赖英文。
- 已保存用户类别不应被强制覆盖；新用户默认数据中文化即可。
- LLM 仍需要理解类别说明；中文 details 可以接受，但应保持语义完整。

验收标准：

- 新用户默认类别显示中文。
- 老用户已有类别不会被迁移覆盖，除非后续任务明确要求迁移。
- 分心类别检测同时支持英文历史值和中文新值。
- 相关单元测试更新或新增覆盖。

验证命令：

```bash
bash scripts/audit-ui-english.sh Dayflow/Dayflow/Models Dayflow/Dayflow/Views/Components
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig \
  GIT_ALLOW_PROTOCOL=file:https \
  xcodebuild test -project Dayflow/Dayflow.xcodeproj -scheme Dayflow \
  -destination 'platform=macOS' \
  -derivedDataPath build/test-derived \
  -only-testing:DayflowTests/WeeklyDashboardBuilderTests
```

### T04：主界面 Shell、菜单栏与 Timeline 中文化

目标：中文化主窗口第一层导航和时间线相关界面。

允许改动：

- `Dayflow/Dayflow/Menu/StatusMenuView.swift`
- `Dayflow/Dayflow/Views/UI/MainView/`
- `Dayflow/Dayflow/Views/UI/Timeline*`
- `Dayflow/Dayflow/Views/UI/CanvasTimelineDataView.swift`
- `Dayflow/Dayflow/Views/UI/PausePillView.swift`
- `Dayflow/Dayflow/Views/UI/Video*`
- 相关通用组件

覆盖内容：

- Sidebar tab label、date picker、timeline empty/loading state。
- activity card 操作、review overlay、feedback modal、rate summary、screenshot/video playback。
- 状态菜单：暂停、恢复、时长、设置入口、退出等。
- tooltips、accessibility label、clipboard/export header 中用户会看到的标题。

保留内容：

- 应用名、app/site 名称、窗口标题、用户生成的 timeline card title/summary。
- 日志、analytics、internal notification name。

验收标准：

- 主界面无未解释英文 UI。
- 暂停/恢复菜单与主窗口状态一致。
- 时间线无数据、有数据、review、视频播放四种状态都能显示中文。

验证命令：

```bash
bash scripts/audit-ui-english.sh Dayflow/Dayflow/Menu Dayflow/Dayflow/Views/UI/MainView Dayflow/Dayflow/Views/UI
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig \
  GIT_ALLOW_PROTOCOL=file:https \
  xcodebuild test -project Dayflow/Dayflow.xcodeproj -scheme Dayflow \
  -destination 'platform=macOS' \
  -derivedDataPath build/test-derived
```

手工验证：

- 启动 Debug app，检查 sidebar、timeline 空态、时间线卡片操作、暂停菜单、review 弹层、视频播放器。

### T05：Settings 全页中文化

目标：中文化所有设置页和设置相关弹窗。

允许改动：

- `Dayflow/Dayflow/Views/UI/SettingsView.swift`
- `Dayflow/Dayflow/Views/UI/Settings/`
- 必要时 provider setup 共用组件

覆盖内容：

- Settings tab：Account、Storage、Recording/Privacy、Providers、Data、Other。
- Section title/subtitle、row label/subtitle、badge/status、按钮、alert。
- Output language override：如果界面已全中文，该设置文案应明确它控制的是“AI 输出语言”，不是 UI 语言。
- 存储限制、重处理、隐私 app block list、provider upgrade/local runtime、account/referral。

保留内容：

- email placeholder、referral code 示例、model name、runtime name、URL、billing/Stripe 内部字段。

验收标准：

- 设置页所有 tab 在可见状态无未解释英文。
- “AI 输出语言”不再让用户误解为界面语言。
- storage/reprocess/provider/account 相关 alert 中文化。
- 状态 badge 中文短词一致：已启用、未启用、检查中、失败、已保存等。

验证命令：

```bash
bash scripts/audit-ui-english.sh Dayflow/Dayflow/Views/UI/Settings Dayflow/Dayflow/Views/UI/SettingsView.swift
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig \
  GIT_ALLOW_PROTOCOL=file:https \
  xcodebuild test -project Dayflow/Dayflow.xcodeproj -scheme Dayflow \
  -destination 'platform=macOS' \
  -derivedDataPath build/test-derived \
  -only-testing:DayflowTests/ProvidersSettingsViewModelTests
```

### T06：Daily、Journal、通知与目标流程中文化

目标：中文化每日复盘、日志、提醒、目标设定与相关通知。

允许改动：

- `Dayflow/Dayflow/Views/UI/Daily*`
- `Dayflow/Dayflow/Views/UI/Journal*`
- `Dayflow/Dayflow/Views/Components/DayGoal*`
- `Dayflow/Dayflow/Views/Components/DaySummaryView.swift`
- `Dayflow/Dayflow/Core/Notifications/NotificationService.swift`
- `Dayflow/Dayflow/Core/Notifications/NotificationPreferences.swift`

覆盖内容：

- Daily locked/unlocked、standup、workflow、provider access flow。
- Journal onboarding/access/reminders/intention/reflection/weekly。
- Day goal setup、yesterday review、focus/distraction summary。
- 通知 title/body、test notification、通知权限说明。

保留内容：

- 用户生成的 summary、standup 内容、LLM 输出内容。
- notification identifier、analytics event、UserDefaults key。

验收标准：

- 每日复盘、日志、目标弹窗、通知权限路径中文化。
- 通知标题/正文中文化，但 identifier 不变。
- 复制到剪贴板的模板标题中文化，用户生成内容保持原样。

验证命令：

```bash
bash scripts/audit-ui-english.sh Dayflow/Dayflow/Views/UI/Journal Dayflow/Dayflow/Views/UI/Daily Dayflow/Dayflow/Views/Components Dayflow/Dayflow/Core/Notifications
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig \
  GIT_ALLOW_PROTOCOL=file:https \
  xcodebuild test -project Dayflow/Dayflow.xcodeproj -scheme Dayflow \
  -destination 'platform=macOS' \
  -derivedDataPath build/test-derived
```

手工验证：

- Daily locked state、通知权限页、standup copy。
- Journal reminders 设置、test notification。
- Day goal setup 和 yesterday review。

### T07：Weekly 仪表盘中文化

目标：中文化周报页面、图表标题、legend、空态和导出相关可见文本。

允许改动：

- `Dayflow/Dayflow/Views/UI/Weekly/`
- `Dayflow/Dayflow/Core/Weekly/`
- `Dayflow/DayflowTests/WeeklyDashboardBuilderTests.swift`

覆盖内容：

- Weekly header、access locked view。
- Overview、donut、treemap、sankey、workflow、heatmap、context charts、application interactions、suggestions/highlights。
- fallback snapshot label，例如 `Timeline data`、`Other`、day label、empty state。

关键风险：

- `Other` 可能是 overflow bucket，也可能是真实 app/category 名；中文化时要保持 ID 去重和测试语义。
- 图表空间紧张，中文标签可能换行或遮挡。
- 单测中英文 fixture 不一定是 UI 文案，更新时要保留测试意图。

验收标准：

- Weekly 各 section 可见英文已处理或加入 allowlist。
- `WeeklyDashboardBuilderTests` 通过，并覆盖 `Other` bucket 语义。
- 宽度较小的图表中文不明显溢出。

验证命令：

```bash
bash scripts/audit-ui-english.sh Dayflow/Dayflow/Views/UI/Weekly Dayflow/Dayflow/Core/Weekly
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig \
  GIT_ALLOW_PROTOCOL=file:https \
  xcodebuild test -project Dayflow/Dayflow.xcodeproj -scheme Dayflow \
  -destination 'platform=macOS' \
  -derivedDataPath build/test-derived \
  -only-testing:DayflowTests/WeeklyDashboardBuilderTests
```

### T08：Chat、WhatsNew、Beta 与反馈路径中文化

目标：中文化对话页、调试面板、记忆面板、Beta 解锁、What's New 和反馈。

允许改动：

- `Dayflow/Dayflow/Views/UI/Chat*`
- `Dayflow/Dayflow/Views/Components/ToolCallBubble.swift`
- `Dayflow/Dayflow/Views/UI/WhatsNewView.swift`
- `Dayflow/Dayflow/Views/UI/BugReportView.swift`
- 相关 access locked views

覆盖内容：

- Chat welcome、suggestions、composer placeholder、debug/memory panel、copy/clear/save/reload。
- tool call status、thinking/answering/follow up。
- Beta unlock、privacy note、feedback/survey。
- What's New release UI。

保留内容：

- 用户消息、assistant 消息、tool JSON、debug log 原文、provider 名。
- release note 如果来自远端或 markdown 内容，除非本地硬编码且用户可见。

验收标准：

- Chat 页静态 UI 中文化。
- Debug/memory 面板按钮中文化，但 log 内容不被翻译。
- 反馈选项中文自然，不影响提交字段。

验证命令：

```bash
bash scripts/audit-ui-english.sh Dayflow/Dayflow/Views/UI/Chat Dayflow/Dayflow/Views/UI/WhatsNewView.swift Dayflow/Dayflow/Views/UI/BugReportView.swift
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig \
  GIT_ALLOW_PROTOCOL=file:https \
  xcodebuild test -project Dayflow/Dayflow.xcodeproj -scheme Dayflow \
  -destination 'platform=macOS' \
  -derivedDataPath build/test-derived
```

### T09：全局剩余英文清理与 allowlist 审核

目标：完成全仓 UI 英文收口，确保剩余英文都有理由。

允许改动：

- 全仓 Swift 源码中剩余用户可见英文
- `scripts/ui-english-allowlist.txt`
- `docs/CHINESE_UI_LOCALIZATION_INVENTORY.md`

执行步骤：

1. 运行扫描脚本。
2. 对每个剩余命中判断：
   - 用户可见且非品牌/命令/模型名：翻译。
   - 非用户可见：加入 allowlist，并写原因。
   - 无法确认：记录到 inventory，不要盲改。
3. 复查 `.help`、`.accessibilityLabel`、alert、notification、clipboard/export。
4. 复查 `return "..."` 中的 computed UI label，例如 status label、buttonTitle、displayName、subtitle。

验收标准：

- 扫描脚本输出中没有未分类英文。
- allowlist 每条有稳定原因。
- inventory 中只保留无法在当前任务安全处理的问题。

验证命令：

```bash
bash scripts/audit-ui-english.sh
git diff --check
```

### T10：构建、测试与人工验收

目标：完成中文化后的整体验证。

自动验证：

```bash
cat >/private/tmp/dayflow-gitconfig <<'EOF'
[url "file:///Users/yuna/ToolsProject-Github/SQLiteLib"]
	insteadOf = https://github.com/swiftlyfalling/SQLiteLib.git
[protocol "file"]
	allow = always
EOF

env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig \
  GIT_ALLOW_PROTOCOL=file:https \
  xcodebuild test -project Dayflow/Dayflow.xcodeproj -scheme Dayflow \
  -destination 'platform=macOS' \
  -derivedDataPath build/test-derived 2>&1 | tee xcodebuild.log

env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig \
  GIT_ALLOW_PROTOCOL=file:https \
  xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow \
  -configuration Debug \
  -derivedDataPath build/local-derived \
  CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  build
```

人工验证矩阵：

| 区域 | 必测状态 |
| --- | --- |
| Onboarding | fresh onboarding、provider 选择、API key/CLI/local、类别、屏幕录制权限、完成页 |
| Status Menu | 录制中、暂停、恢复、时长、打开设置、退出 |
| Main Timeline | 空态、有卡片、日期切换、activity card 操作、review、视频播放 |
| Settings | 每个 tab、alert、provider setup、storage limit、privacy app list、account/referral |
| Daily | locked state、provider access、standup、copy、通知权限 |
| Weekly | locked state、overview、donut、treemap、sankey、workflow、heatmap、interactions、导出 |
| Chat | welcome、suggestions、发送中、answering、debug、memory、copy/clear |
| Journal | access/onboarding、intention、reflection、reminders、test notification |
| Accessibility | 关键按钮 VoiceOver label、hover help |

验收标准：

- Debug app 可构建。
- 单元测试通过；如果 UI test 仍为模板，至少 launch test 可跑或说明无法验证原因。
- 人工验证矩阵每项都有“通过/无法验证/待修复”。
- 中文文案无明显截断、重叠、语义不通。

## 6. 推荐执行顺序

1. T00：扫描脚本与基线。
2. T01：策略确认。
3. T02：Onboarding。
4. T03：默认类别与分类文案。
5. T05：Settings。
6. T04：Main UI 与菜单栏。
7. T06：Daily / Journal / 通知 / 目标。
8. T07：Weekly。
9. T08：Chat / WhatsNew / Feedback。
10. T09：剩余英文收口。
11. T10：整体验证。

这个顺序优先处理新用户路径和基础数据，再处理高频主界面，最后做图表、对话和全局收口。

## 7. Spark 任务提示模板

给 Spark 分派每个任务时建议使用以下模板：

```text
你是 GPT-5.3-Codex-Spark。请在 /Users/yuna/ToolsProject-Github/Dayflow-Yuna 中执行任务 <Txx>。

先读取：
- docs/CHINESE_UI_LOCALIZATION_PLAN.md
- CLAUDE.md
- 本任务允许改动范围内的相关 Swift 文件

要求：
- 如果 .codegraph/ 存在，先用 CodeGraph 理解目标文件。
- 只修改本任务允许范围。
- 只翻译用户可见文案，保留内部 key、analytics、URL、命令、provider raw value、asset 名、模型名和品牌名。
- 简体中文，默认用“你”。
- 修改后运行任务指定扫描/测试命令。

交付：
- 修改文件列表
- 实现内容
- 测试结果
- 剩余英文命中及处理理由
- 未解决问题
```

## 8. 总体验收定义

该项目可以判定“界面全量中文化完成”的条件：

1. 所有 SwiftUI 文案入口、alert、notification、help、accessibility label、clipboard/export header 已中文化或被 allowlist 明确排除。
2. 默认类别和新用户 onboarding preset 显示中文，历史用户数据不被无提示覆盖。
3. `scripts/audit-ui-english.sh` 无未分类英文命中。
4. `xcodebuild test` 通过，或失败项与中文化无关且有日志证据。
5. Debug app 构建成功。
6. 人工验证矩阵覆盖核心路径，无明显排版破损。
7. 文档记录剩余无法确认项，而不是用猜测替代。

