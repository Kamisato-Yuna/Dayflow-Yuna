# 项目现状审计报告

审计日期：2026-07-01

更新：2026-07-03 完成 Dayflow Pro 移除 T10-T17 后，账号登录、Dayflow Pro/Backend provider、auth/billing/referral endpoint、referral asset 与相关 project references 已从 app 可执行路径中移除。本文保留原始审计证据，并在当前状态处标注已关闭项。

> 本报告以中文为主说明，保留代码路径、API 字段、命令行与事件名为原文，便于与代码一一对应。

审计范围：README、CLAUDE.md、docs、Xcode 工程配置、Swift 源码、CodeGraph 调用关系、数据库迁移、设置/路由/接口定义、测试文件与一次受控测试尝试。

约束：未修改核心代码。本次只新增本文档，并延续 `.gitignore` 中对 `.codegraph/` 的忽略规则。

## 1. 总体判断

Dayflow 当前是一个 macOS SwiftUI + AppKit 菜单栏应用，核心产品形态是“自动截图 -> 本地 SQLite/GRDB 存储 -> LLM 分析 -> Timeline/Daily/Weekly/Chat/Journal UI 展示”的本地优先工作日志。

核心链路已经成型，README 中的 Timeline、Daily Standup、Weekly Review、Chat、本地优先、AI provider choice 等能力在源码中均能找到对应实现。主要缺口集中在四类：

1. 产品闭环缺口：Journal 内部实现存在，但主入口与通知跳转未真正接通。
2. Provider 能力缺口：原始审计发现 Dayflow Backend 通用 `generateText` 半成品；T10-T17 已移除 Dayflow Backend 作为可用 provider，当前不再作为修复项。
3. 测试/可复现性缺口：StorageManager、AnalysisManager、LLMService、Journal、Auth/Account、UI 路由等核心面缺少覆盖测试；CLI 测试被 SwiftPM 依赖下载失败阻断。
4. 隐私/线上能力技术债：PostHog/Sentry、Sparkle、release survey 等非账号线上能力仍需单独决策；Dayflow Auth/Billing/Referral/Backend API 可执行路径已由 T10-T17 移除。

信息不足处均标注“无法确认”。

## 2. 项目结构图

```text
Dayflow-Yuna/
├── README.md
├── CLAUDE.md
├── docs/
│   ├── PROJECT_STATUS_AUDIT.md
│   └── images/
├── scripts/
│   └── release.sh
├── Dayflow/
│   ├── Dayflow.xcodeproj
│   ├── Dayflow/
│   │   ├── App/
│   │   ├── Core/
│   │   │   ├── AI/
│   │   │   ├── Access/
│   │   │   ├── Analysis/
│   │   │   ├── Net/
│   │   │   ├── Notifications/
│   │   │   ├── Recording/
│   │   │   ├── Security/
│   │   │   ├── Thumbnails/
│   │   │   └── Weekly/
│   │   ├── Menu/
│   │   ├── Models/
│   │   ├── System/
│   │   ├── Utilities/
│   │   ├── Views/
│   │   │   ├── Components/
│   │   │   ├── Onboarding/
│   │   │   └── UI/
│   │   ├── Assets.xcassets/
│   │   ├── Fonts/
│   │   └── Videos/
│   ├── DayflowTests/
│   └── DayflowUITests/
└── DayflowTests/
```

证据：

- 目录职责在 `CLAUDE.md:70-89` 有较完整说明。
- README 描述产品定位为 Mac 私有自动工作日志，见 `README.md:4-9`。
- README 功能表列出 Timeline、Daily、Chat、Weekly、Export、Local-first、AI provider choice，见 `README.md:56-71`。

## 3. 技术栈与依赖

| 层 | 当前状态 | 证据 |
| --- | --- | --- |
| App 框架 | macOS SwiftUI `App` 生命周期 + `NSApplicationDelegate` 混合 AppKit | `CLAUDE.md:29`, `Dayflow/Dayflow/App/DayflowApp.swift:111`, `Dayflow/Dayflow/App/AppDelegate.swift:50` |
| 持久化 | GRDB + SQLite，`StorageManager` 是单一持久化门面 | `CLAUDE.md:63-65`, `Dayflow/Dayflow/Core/Recording/StorageManager.swift:458` |
| 截图采集 | ScreenCaptureKit `SCScreenshotManager` 周期截图，默认 10 秒 | `CLAUDE.md:35-43`, `Dayflow/Dayflow/Core/Recording/ScreenRecorder.swift:20` |
| AI provider | Gemini、Ollama/LM Studio、ChatGPT/Claude CLI；legacy `dayflowBackend` 仅用于偏好解码迁移 | `CLAUDE.md:79-91`, `Dayflow/Dayflow/Core/AI/LLMTypes.swift` |
| 自动更新 | Sparkle | `Dayflow/Dayflow/Info.plist:24-37` |
| 遥测/错误 | PostHog + Sentry | `CLAUDE.md:31`, `Dayflow/Dayflow/System/AnalyticsService.swift:41` |
| 发布 | `scripts/release.sh` 负责版本、DMG、Sparkle、GitHub Release、appcast | `CLAUDE.md:99-103` |

工程配置风险：

- app target macOS deployment target 是 14.0，但 project/test 处存在 15.1，存在配置不一致：`Dayflow/Dayflow.xcodeproj/project.pbxproj:337`, `Dayflow/Dayflow.xcodeproj/project.pbxproj:426`。
- Release 配置 `ENABLE_HARDENED_RUNTIME = NO`，与分发安全预期不一致：`Dayflow/Dayflow.xcodeproj/project.pbxproj:450`。
- 测试 bundle id 仍是旧名 `AmiTimeTests/AmiTimeUITests`：`Dayflow/Dayflow.xcodeproj/project.pbxproj:480`, `Dayflow/Dayflow.xcodeproj/project.pbxproj:514`。
- 未提交实际 `.xcscheme` 文件，仅有 `xcuserdata/jerry.xcuserdatad/xcschemes/xcschememanagement.plist` 记录 `Dayflow`/`AmiTime` scheme：`Dayflow/Dayflow.xcodeproj/xcuserdata/jerry.xcuserdatad/xcschemes/xcschememanagement.plist:5-16`。

## 4. 启动流程与数据流

### 启动流程

1. `DayflowApp` 是 `@main` 入口，注入 `AppDelegate`，根据 onboarding 状态切换主界面或引导流程。证据：`Dayflow/Dayflow/App/DayflowApp.swift:111`。
2. `AppDelegate` 初始化 Sentry/PostHog、菜单栏、登录启动、deep link、录制与分析任务。证据：`Dayflow/Dayflow/App/AppDelegate.swift:50`, `Dayflow/Dayflow/App/AppDelegate.swift:79`, `Dayflow/Dayflow/App/AppDelegate.swift:87`, `Dayflow/Dayflow/App/AppDelegate.swift:150`。
3. 主界面 `MainView` 通过 sidebar tab 切换 Timeline/Daily/Weekly/Chat/Journal/Report/Settings。证据：`Dayflow/Dayflow/Views/UI/MainView/SidebarView.swift:18` 和 `Dayflow/Dayflow/Views/UI/MainView/Layout+Panels.swift:79`。

### 核心数据流

```text
ScreenRecorder
  -> StorageManager.saveScreenshotRecord / saveBatch
  -> AnalysisManager.processRecordings
  -> AnalysisManager.queueLLMRequest
  -> LLMService.processBatch
  -> Provider.transcribeScreenshots
  -> StorageManager.saveObservations
  -> Provider.generateActivityCards
  -> StorageManager.replaceTimelineCardsInRange
  -> Timeline/Daily/Weekly/Chat/Journal UI
```

证据：

- README 描述自动 timeline：`README.md:24-30`。
- CLAUDE 数据流图：`CLAUDE.md:33-44`。
- `AnalysisManager.queueLLMRequest` 检查 screenshots、状态写入、调用 LLMService：`Dayflow/Dayflow/Core/Analysis/AnalysisManager.swift:401-533`。
- `LLMService.processBatch` 执行截图转录、保存 observations、滑动窗口生成 cards、替换 timeline cards：`Dayflow/Dayflow/Core/AI/LLMService.swift:579-846`。
- 数据库迁移创建 screenshots、analysis_batches、timeline_cards、observations 等表：`Dayflow/Dayflow/Core/Recording/StorageManager.swift:458-649`。

## 5. 核心模块说明

| 模块 | 边界 | 真实状态 |
| --- | --- | --- |
| App | app lifecycle、menu bar、deep link、recording/analysis 启动 | 已实现 |
| Core/Recording | ScreenRecorder、StorageManager、JournalDayManager、迁移、存储维护 | 已实现，但 StorageManager 高耦合且缺测试 |
| Core/Analysis | timer-driven batch loop、idle shortcut、reprocess | 已实现，但状态字符串分散 |
| Core/AI | provider、prompt、LLMService、ChatService、DailyRecapGenerator | 主体完成；Dayflow Backend 运行时 provider 已移除 |
| Core/Weekly | Weekly dashboard builder 与图表聚合 | 已实现且有部分单测 |
| Views/UI/MainView | Timeline 主界面、sidebar、activity cards、review、copy/delete | 已实现 |
| Views/UI/Daily | Daily 解锁、standup、workflow grid、scheduler | 已实现 |
| Views/UI/Weekly | weekly analytics、PNG export | 已实现 |
| Views/UI/Chat | chat panel、streaming、tools、本地 DB 查询 | 已实现，range tool 半成品，beta analytics 记录问题全文 |
| Views/UI/Journal | Journal day flow、summary、reminders、lock/onboarding | 内部实现，但主入口断开 |
| Views/UI/Settings | Storage/Privacy/Providers/Export/Other | 已实现；Account 账号入口已移除 |

## 6. 已完成功能

1. 自动 timeline：截图采集、batch、LLM 分析、timeline card 持久化和 UI 展示已接线。证据：`ScreenRecorder.swift:20`, `AnalysisManager.swift:401`, `LLMService.swift:579`, `TimelineActivityLoader.swift:22`。
2. Daily：访问门槛、provider onboarding、standup 生成、复制、scheduler 已实现。证据：`Dayflow/Dayflow/Views/UI/DailyView.swift:55`, `Dayflow/Dayflow/Core/AI/DailyRecapGenerator.swift:197`, `Dayflow/Dayflow/Core/AI/DailyRecapScheduler.swift:72`。
3. Weekly：dashboard snapshot、donut/treemap/sankey/heatmap/overview、PNG export 已实现。证据：`Dayflow/Dayflow/Core/Weekly/WeeklyDashboardBuilder.swift:17`, `Dayflow/Dayflow/Views/UI/WeeklyView.swift:862`。
4. Chat：消息发送、streaming、tool execution、local DB 数据注入已实现。证据：`Dayflow/Dayflow/Core/AI/ChatService.swift:115`, `Dayflow/Dayflow/Core/AI/ChatToolExecutor.swift:30`。
5. Settings：Account/Storage/Privacy/Providers/Export/Other tabs 已实现。证据：`Dayflow/Dayflow/Views/UI/SettingsView.swift:11-30`。
6. 本地优先存储：README 标明默认数据路径，源码中 StorageManager 写 Application Support。证据：`README.md:83-87`, `Dayflow/Dayflow/Core/Recording/StorageManager.swift:200`。
7. Release/update：Sparkle Info.plist 配置存在。证据：`Dayflow/Dayflow/Info.plist:24-37`。

## 7. 待开发/半成品/未接线项

| 优先级 | 项 | 状态 | 证据 |
| --- | --- | --- | --- |
| P0 | UI 多语言配置框架 | 未实现。没有 `.lproj`、`.strings`、`.stringsdict`、`.xcstrings`；SwiftUI 文案大量硬编码英文。当前只有 LLM 输出语言 override。 | 资源搜索无结果；`SettingsOtherTabView.swift:19-80`; `LLMOutputLanguagePreferences.swift:3-29` |
| P0 | 账号登录相关线上能力后续移除 | 已完成 T10-T17：Account tab、邮箱验证码、session token、entitlements、Stripe、referral、Dayflow Backend token 可执行路径已移除；legacy 偏好迁移保留。 | `docs/DAYFLOW_PRO_REMOVAL_TASKS.md` T10-T17 完成记录 |
| P0 | Dayflow Backend 通用文本生成 | 已通过移除 Dayflow Backend provider 关闭该半成品路径。 | `docs/DAYFLOW_PRO_REMOVAL_TASKS.md` T15/T17 完成记录 |
| P1 | Journal 主入口 | 内部实现存在，但 sidebar 过滤 `.journal`，`.navigateToJournal` 实际跳到 Weekly。 | `SidebarView.swift:76-80`; `Layout+Panels.swift:89-91`; `Layout.swift:81-84` |
| P1 | Chat tool 日期范围 | schema 有 `startDate/endDate` future 字段，执行只支持单日 `date`。 | `ChatToolExecutor.swift:43-48`; `ChatToolExecutor.swift:129-139`; `ChatToolExecutor.swift:167-182` |
| P1 | batch 状态模型 | 多处自由字符串写入，存在 `"processing"`, `"completed"`, `"analyzed"`, `"failed_empty"`, `"skipped_short"` 等，缺少类型约束。 | `AnalysisManager.swift:409-437`; `AnalysisManager.swift:511-512`; `LLMService.swift:709-710`; `LLMService.swift:827-828`; `StorageManager+Chunks.swift:94-100` |
| P1 | StorageManager 测试覆盖 | CodeGraph blast radius 显示 `StorageManager` 被 41 处调用，但未找到覆盖测试。 | CodeGraph: `StorageManager` 41 callers; 现有测试列表不含 StorageManagerTests |
| P1 | 原型/legacy UI 清理 | 多个 UI 只在 preview/fixture 或无 caller。 | `OnboardingPrototypeFlow.swift:42`; `OnboardingLLMSelectionView.swift:11`; `JournalWeeklyView.swift:4`; `WeeklyInteractionGraphPrototypeSection.swift:4` |
| P2 | docs/images README | 陈旧，列出的文件名与 README 当前引用不一致。 | `docs/images/README.md:5-14`; `README.md:28-53` |
| P2 | 旧命名残留 | 测试 bundle id 仍是 AmiTime。 | `Dayflow.xcodeproj/project.pbxproj:480`; `Dayflow.xcodeproj/project.pbxproj:514` |

## 8. UI 多语言配置框架专项评估

结论：UI 多语言配置框架未实现。

证据：

- 文件系统未发现 `.lproj`、`.strings`、`.stringsdict`、`.xcstrings`。
- 设置页存在 “Output language override”，但它只保存 `llmOutputLanguageOverride`，用于提示 LLM 输出语言，不是 UI 本地化。证据：`Dayflow/Dayflow/Views/UI/Settings/SettingsOtherTabView.swift:76-114`, `Dayflow/Dayflow/Core/AI/LLMOutputLanguagePreferences.swift:3-29`。
- UI 文案硬编码英文，例如 Settings Other: `App preferences`, `Launch Dayflow at login`, `Output language override`。证据：`Dayflow/Dayflow/Views/UI/Settings/SettingsOtherTabView.swift:19-80`。
- DailyRecapGeneratorTests 覆盖的是 LLM 输出语言 prompt 与 backend request 字段，不是 UI localization。证据：`DayflowTests/DailyRecapGeneratorTests.swift:11-45`。

待开发建议：

1. P0：明确 UI 多语言范围，是仅设置页/主导航，还是全 UI。
2. P0：引入 `.xcstrings` 或 `Localizable.strings`，迁移 `Text("...")`、button title、placeholder、error/status 文案。
3. P1：增加语言切换配置或跟随系统语言策略。
4. P1：为关键设置页、sidebar、onboarding、Daily/Weekly/Chat 空态添加 snapshot 或字符串覆盖测试。

## 9. 账号登录与线上能力移除清单

用户明确提出“需要账号登陆的相关线上能力后续需要移除”。原始审计发现这些能力并非集中在一个文件；T10-T17 已按能力拆除，并保留 legacy 偏好迁移。

### 已移除或替换的入口

| 能力 | 当前状态 | 证据 |
| --- | --- | --- |
| Settings Account tab | 已移除，设置默认进入非账号 tab | `docs/DAYFLOW_PRO_REMOVAL_TASKS.md` T12 |
| 邮箱验证码登录 | `/v1/auth/code/start`、`/v1/auth/code/verify` 可执行路径已移除 | `docs/DAYFLOW_PRO_REMOVAL_TASKS.md` T16 |
| session token Keychain | 账号 session 读取路径已移除；legacy provider 偏好迁移到非 Dayflow provider | `docs/DAYFLOW_PRO_REMOVAL_TASKS.md` T10/T15/T16 |
| entitlements/pro 状态 | Pro entitlement UI 与 manager 已移除 | `docs/DAYFLOW_PRO_REMOVAL_TASKS.md` T12/T16 |
| Stripe checkout/portal | `/v1/billing/*` 可执行路径已移除 | `docs/DAYFLOW_PRO_REMOVAL_TASKS.md` T12/T16 |
| Referral 系统 | deep link、pending code、usage heartbeat、reward UI 和 referral asset 已移除 | `docs/DAYFLOW_PRO_REMOVAL_TASKS.md` T13/T16 |
| Dayflow Backend provider | `/v1/daily` 与 `/v1/dayflow/*` 生成路径已移除 | `docs/DAYFLOW_PRO_REMOVAL_TASKS.md` T14/T15 |
| Dayflow provider UI 状态 | Provider routing / onboarding / Daily picker 不再展示 Dayflow Pro 或 Dayflow Backend | `docs/DAYFLOW_PRO_REMOVAL_TASKS.md` T10/T11/T14 |
| What's New 线上 survey | `/v1/release-survey` | `Dayflow/Dayflow/Views/UI/WhatsNewView.swift:616` |
| Sparkle/appcast 下载线上能力 | appcast feed `https://dayflow.so/appcast.xml` | `Dayflow/Dayflow/Info.plist:32-35` |

保留风险：

- `LLMProviderType.dayflowBackend` 和相关测试命中保留为 legacy decode / migration 兼容，不作为 UI 或 routing 可选项。
- `ReferralSurveyView` 是 onboarding 来源调查组件，不是 referral 奖励系统；当前仍有 caller，不按 dead file 删除。
- `docs/DAYFLOW_PRO_REMOVAL_TASKS.md`、本节和 `docs/LOCAL_NO_LOGIN_LIGHTWEIGHT_REVIEW.md` 保留历史关键词用于审计追踪。

无法确认：

- 后续目标是完全离线版、保留 Sparkle 更新、还是仅移除账号登录但保留匿名下载/更新：无法确认。

## 10. 高风险技术债

1. 隐私/遥测风险  
   Analytics 默认开启，且脱敏只按少数精确 key 过滤。聊天问题、反馈文本、activity summary 可通过非阻断 key 发送。证据：`AnalyticsService.swift:28-39`, `AnalyticsService.swift:203-207`, `AnalyticsService.swift:360-378`, `ChatView+Actions.swift:33-43`, `ChatView+Actions.swift:126-141`, `MainView/Actions.swift:46-53`, `MainView/Actions.swift:291-304`。

2. Keychain 日志风险  
   API key retrieve 会打印 service/account、长度、key prefix。证据：`KeychainManager.swift:56-119`。

3. LLM 调试日志风险  
   `LLMService` 打印 observations 和 category descriptions，可能包含敏感屏幕内容摘要。证据：`LLMService.swift:726-760`。

4. CLI provider 执行风险  
   ChatGPT/Claude CLI provider 会通过本地 CLI 执行，Claude 命令含 `--dangerously-skip-permissions`。证据：`ChatCLIProcessRunner.swift:690-710`。

5. Release 配置风险  
   Hardened Runtime 关闭、sandbox entitlement 为 false，且 network client/server 都开启。证据：`Dayflow.xcodeproj/project.pbxproj:450`, `Dayflow/Dayflow/Dayflow.entitlements:5-14`。

6. 存储层核心缺测试  
   StorageManager 管理所有持久化核心表，CodeGraph 显示调用面大，但现有测试未覆盖迁移、读写、状态更新、软删除、维护恢复。

## 11. 测试现状与本次测试

### 当前测试文件

- `Dayflow/DayflowTests/ProvidersSettingsViewModelTests.swift`
- `Dayflow/DayflowTests/TimeParsingTests.swift`
- `Dayflow/DayflowTests/WeeklyDashboardBuilderTests.swift`
- `Dayflow/DayflowUITests/DayflowUITests.swift`
- `Dayflow/DayflowUITests/DayflowUITestsLaunchTests.swift`
- `DayflowTests/ChatCLIProcessRunnerTests.swift`
- `DayflowTests/DailyRecapGeneratorTests.swift`

实质覆盖：

- Daily recap prompt/source resolver/output language request。
- Weekly dashboard builder 的 Idle 排除、Sendable、Sankey Other 合并。
- Chat CLI fallback/config path 逻辑。
- Provider settings view model 的本地 model settings 刷新。
- 时间解析。

缺失覆盖：

- StorageManager migration/read/write/maintenance。
- AnalysisManager batching/idle shortcut/status transitions。
- LLMService provider failover、legacy Dayflow provider migration 防回归。
- Journal route/summary/reminders。
- Account/Auth/Billing/Referral 移除后的残留扫描与防回归。
- UI 多语言。
- Settings tab 路由、deep link、Sparkle/release。

### 本次测试尝试

命令：

```bash
xcodebuild test -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -destination platform=macOS -derivedDataPath /private/tmp/dayflow-deriveddata -only-testing:DayflowTests
```

结果：未进入编译/测试执行，失败在 SwiftPM package resolve / clone 阶段。

关键错误：

```text
xcodebuild: error: Could not resolve package dependencies
Failed to clone repository https://github.com/groue/GRDB.swift
error: RPC failed; curl 18 Transferred a partial file
fatal: early EOF
fatal: fetch-pack: invalid index-pack output
```

同时环境输出 CoreSimulator 版本不匹配：

```text
CoreSimulator is out of date. Current version (1051.50.0) is older than build version (1051.55.0).
```

测试结论：

- 当前代码是否可编译：无法确认。
- 当前单测是否通过：无法确认。
- 已确认的是测试可复现性受 SwiftPM 依赖下载/网络稳定性影响；未提交共享 `.xcscheme` 也会降低 CI/CLI 可复现性。

## 12. 推荐开发优先级

### P0

1. 实现 UI 多语言配置框架，至少引入本地化资源文件与关键 UI 文案迁移。
2. 修复隐私/遥测风险：默认 opt-in 策略、敏感字段脱敏、聊天问题全文上报、feedback 文本、activity summary、LLM debug print、Keychain prefix print。
3. 建立可复现测试路径：提交共享 scheme，固定依赖获取策略，给 `xcodebuild test` 提供 CI 友好命令。
4. 给 StorageManager 和 AnalysisManager 加最小集成测试，覆盖迁移、batch status、timeline card 替换。

### P1

1. Journal：明确上线/隐藏策略；上线则接通 sidebar 与 `.navigateToJournal`，隐藏则清理 badge/通知入口。
2. Chat tools：实现日期范围查询或移除 `startDate/endDate` schema。
3. batch status：收敛为 enum/常量，避免 `"completed"` 与 `"analyzed"` 混用。
4. 清理原型和 legacy UI，尤其是 Onboarding Prototype、legacy provider selection、JournalWeeklyView、weekly interaction prototype。

### P2

1. 修复 docs/images README 陈旧内容。
2. 清理 AmiTime 旧命名。
3. 扩展 UI tests，从 launch 模板推进到 Settings/Timeline/Daily/Journal smoke test。
4. 审视 Sparkle、PostHog、Sentry 是否保留；如果产品目标是完全本地离线，需要一起降级或移除。

## 13. 无法确认清单

- 当前完整 test suite 是否通过：未在 T17 全量运行；Debug build 已在 2026-07-03 通过。
- 后续线上能力移除是否包括 Sparkle 更新、PostHog/Sentry、dayflow.so 下载链接：需求未明确。
- UI 多语言目标语言、覆盖范围、是否允许运行时切换：需求未明确。
- 原型视图是否仍被设计/手动调试流程依赖：CodeGraph 未发现生产 caller，但外部使用无法确认。
