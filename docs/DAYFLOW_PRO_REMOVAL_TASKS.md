# Dayflow Pro 移除任务拆分

日期：2026-07-02
适用分支：`codex/remove-account-local-tool-review` 及其后续任务分支
背景文档：`docs/LOCAL_NO_LOGIN_LIGHTWEIGHT_REVIEW.md`

## 总目标

优先移除 Dayflow Pro 相关特性，尤其是 AI Provider Routing 中的 Dayflow Pro / Dayflow Backend 路径。最终状态是：Dayflow 不再提供或推荐需要 Dayflow 账号、订阅、试用、推荐奖励或托管后端的功能；用户通过 Gemini API Key、ChatGPT/Claude CLI 或本地 Ollama/LM Studio 使用应用。

本任务集不是“完全离线版”任务集。PostHog/Sentry、Sparkle 更新、GitHub release、外部模型下载链接是否继续保留，另行决策。

## 执行原则

- 每个任务只修改该任务允许范围内的文件。
- 如果 `.codegraph/` 存在，先用 CodeGraph 理解目标文件和调用影响面。
- 不要把 Gemini、ChatGPT/Claude CLI、本地模型误判为 Dayflow Pro；它们是移除 Dayflow 登录后的替代运行方式。
- 对历史用户偏好必须做兼容迁移，不能让旧的 `dayflow` / `dayflowBackend` 状态静默落到不可用路径。
- 删除入口优先于保留半失效 paywall；Routing 中不能继续出现可选择的 Dayflow Pro provider。
- 若发现任务范围不足以通过编译，先报告需要扩展的文件；不要顺手扩大到无关功能。

## 任务总览

| 任务编号 | 标题 | 优先级 | 状态 | 主要目标 |
| --- | --- | --- | --- | --- |
| T10 | 移除 Provider Routing 中的 Dayflow Pro 可选路径 | P0 | Done | 让 Settings Providers 的 primary/backup routing 不再展示、选择或跳转 Dayflow Pro。 |
| T11 | 移除 Onboarding 中的 Dayflow Pro 选择和登录试用路径 | P0 | Done | 新用户不再看到 Dayflow Pro 卡片、验证码登录、推荐码、试用流程。 |
| T12 | 移除 Settings Account / Dayflow Pro 账号订阅入口 | P0 | Done | 设置页不再有账号 tab、登录 sheet、Stripe/试用/referral 用户入口。 |
| T13 | 移除 Referral deep link 和后台使用时长上报 | P0 | Done | 不再保存 referral code，不再后台调用 referral usage endpoint。 |
| T14 | 移除 Daily 中的 Dayflow Backend provider 路径 | P0 | Done | Daily provider picker 不再出现 Dayflow backend，旧值迁移到非 Dayflow provider。 |
| T15 | 移除 LLMService 中的 Dayflow Backend 生成路径 | P1 | Done | 时间线/文本生成不再构造 `DayflowBackendProvider` 或要求 Dayflow session token。 |
| T16 | 删除认证/计费/推荐残留模型与文档事件 | P1 | Done | 删除或隔离 `DayflowAuthManager`、Pro auth/referral analytics、release/backend URL 残留。 |
| T17 | 最终残留扫描与项目文件清理 | P1 | Done | 清理 dead files/assets/project references，确认 app 代码无 Dayflow Pro 可执行路径。 |

完成记录（2026-07-03）：

- T10-T16 已完成对应 routing、onboarding、settings account、referral、Daily、LLMService、auth/model/asset 清理。
- T17 残留扫描确认 app target 无 Dayflow Pro / Dayflow Backend / auth endpoint 可执行路径；剩余命中仅为 legacy migration 测试、兼容 enum case、历史评审/任务文档和非奖励系统的 onboarding 来源调查组件。
- Xcode project 未发现 `DayflowAuthManager`、`DayflowBackendProvider`、`ReferralCardBackground` 或 `DayflowBackendURL` 引用。

## T10：移除 Provider Routing 中的 Dayflow Pro 可选路径

目标：

- `Settings > AI 提供商` 不再展示 Dayflow Pro / Dayflow Backend provider。
- primary/backup routing 不能再选择、设置、编辑或跳转 Dayflow Pro。
- 历史 `selectedLLMProvider=dayflow`、`llmBackupProviderId=dayflow`、encoded `llmProviderType.dayflowBackend` 不再成为当前可用 routing。

允许范围：

- `Dayflow/Dayflow/Core/AI/LLMTypes.swift`
- `Dayflow/Dayflow/Views/UI/Settings/ProvidersSettingsViewModel.swift`
- `Dayflow/Dayflow/Views/UI/Settings/SettingsProvidersTabView.swift`
- `Dayflow/DayflowTests/ProvidersSettingsViewModelTests.swift`

关键改动：

- 从 `providerCatalog` / `routingProviders` 的用户可选列表移除 `dayflow`。
- `beginProviderSetup`、`editProviderConfiguration`、`setPrimaryOrSetup`、`setSecondaryOrSetup` 不再打开账号页或 paywall。
- `loadCurrentProvider` 对历史 `.dayflowBackend` 做迁移，建议迁移到 `gemini`；如果本地模型已配置，也可迁移到 `ollama`，但策略必须在测试中固定。
- backup provider 读取到 `dayflow` 时必须清空并持久化删除。
- 删除或改写 `isDayflowProActive`、`shouldShowDayflowUpgradeAction`、`openDayflowUpgradeAccount`、`openAccountForDayflowPro` 在 routing 中的调用。
- 保留 `LLMProviderType.dayflowBackend` 作为临时 legacy decode 兼容是允许的，但不能被 UI 或 routing 写回。

验收标准：

- Provider 列表没有 Dayflow Pro。
- 设置 primary/backup 的路径不会产生 `selectedLLMProvider=dayflow` 或 `llmBackupProviderId=dayflow`。
- 旧偏好迁移后不会显示 Dayflow Pro 当前状态。
- `SettingsProvidersTabView` 中无“升级账号”“需要 Dayflow Pro”“Dayflow 后端”等 routing UI 文案。

强制测试验收：

- 必须新增或更新 `ProvidersSettingsViewModelTests`，覆盖旧 `selectedLLMProvider=dayflow` 的迁移结果；测试必须断言迁移后不会保留或写回 `dayflow`。
- 必须覆盖 encoded `llmProviderType.dayflowBackend` legacy 值的加载路径；测试必须断言当前 provider 被迁移到本任务选定的非 Dayflow 默认值。
- 必须覆盖 `llmBackupProviderId=dayflow`；测试必须断言 backup 被清空或迁移，并且持久化后的 UserDefaults 不再包含 `dayflow` backup。
- 必须覆盖 provider/routing 列表；测试必须断言用户可选 provider 中不存在 `dayflow` / `Dayflow Pro`。

建议验证：

```bash
rg -n 'Dayflow Pro|dayflowBackend|providerCatalog|openAccountForDayflow|isDayflowProActive|llmBackupProviderId|selectedLLMProvider' \
  Dayflow/Dayflow/Core/AI/LLMTypes.swift \
  Dayflow/Dayflow/Views/UI/Settings/ProvidersSettingsViewModel.swift \
  Dayflow/Dayflow/Views/UI/Settings/SettingsProvidersTabView.swift \
  Dayflow/DayflowTests/ProvidersSettingsViewModelTests.swift
```

建议提交信息：

```text
chore(providers): remove Dayflow Pro from provider routing
```

## T11：移除 Onboarding 中的 Dayflow Pro 选择和登录试用路径

目标：

- 新用户 onboarding 不再推荐或展示 Dayflow Pro。
- 删除 Dayflow Pro 登录、验证码、推荐码、免费试用、trial active 相关 UI 和状态。
- Onboarding provider selection 只进入 Gemini、ChatGPT/Claude CLI、本地 AI 的 setup/continue 路径。

允许范围：

- `Dayflow/Dayflow/Views/Onboarding/Prototype/OnboardingPrototypeChooseProviderStep.swift`
- `Dayflow/Dayflow/Views/Onboarding/OnboardingFlow.swift`
- `Dayflow/Dayflow/Views/Onboarding/LLMProviderSetupView.swift`（仅当 provider 流程需要同步文案或 guard）
- `Dayflow/Dayflow/AnalyticsEventDictionary.md`（仅删除/标记本任务移除的 onboarding Dayflow Pro 事件）

关键改动：

- 删除 `DayflowProOnboardingStep`、Dayflow Pro sign-in panel、referral/trial 子流程。
- `recommendedProviders` 不再返回 `dayflow`。
- “查看全部”中不再渲染 `compactCard(for: "dayflow")`。
- `selectButton` 不再拦截 `title == "Dayflow Pro"`。
- `OnboardingFlow` 删除 `"Dayflow Pro" -> "dayflow"` 映射、`LLMProviderType.dayflowBackend().persist()` 和 `selectedProvider == "dayflow"` 跳过 setup 的分支。

验收标准：

- Onboarding 中无法选择 Dayflow Pro。
- Onboarding 不引用 `DayflowAuthManager.shared`。
- 新用户选择任一 provider 后路径可进入 setup 或下一步，不存在 dayflow 特判。

建议验证：

```bash
rg -n 'Dayflow Pro|dayflowPro|DayflowAuthManager|dayflowBackend|selectedProvider == "dayflow"|providerID = "dayflow"' \
  Dayflow/Dayflow/Views/Onboarding
```

建议提交信息：

```text
chore(onboarding): remove Dayflow Pro provider path
```

## T12：移除 Settings Account / Dayflow Pro 账号订阅入口

目标：

- 设置页不再有账号 tab。
- 用户无法打开登录、退出登录、Stripe checkout、billing portal、trial、referral UI。
- `.openAccountSettings` 不再作为可达设置导航目标；如仍有旧通知，安全重定向到 providers。

允许范围：

- `Dayflow/Dayflow/Views/UI/SettingsView.swift`
- `Dayflow/Dayflow/Views/UI/Settings/SettingsAccountSection.swift`
- `Dayflow/Dayflow/Views/UI/Settings/SettingsReferralProgramCard.swift`
- `Dayflow/Dayflow/App/DayflowApp.swift`
- `Dayflow/Dayflow/Views/UI/MainView/Layout.swift`（仅处理 toast destination 到 settings 的导航）
- `Dayflow/Dayflow/Core/AI/TimelineFailureClassifier.swift`（仅处理 account destination 文案/枚举）

关键改动：

- 删除 `SettingsTab.account` 或将其隐藏，并把默认 `selectedTab` 改为 `.providers`。
- 删除 `SettingsAccountSection()` 渲染。
- 删除 Account tab 相关 sheet 和登录 UI。
- 如果 `SettingsAccountSection.swift` / `SettingsReferralProgramCard.swift` 不再被引用，可删除文件并更新 Xcode project references。
- `.openAccountSettings` 如果还有编译期引用，应改为 providers 兼容路径；若无引用，删除 notification name。

验收标准：

- Settings sidebar 不显示“账号”。
- app 内没有可见的登录/升级/试用/管理账单/referral settings UI。
- 失败 toast 不再把用户导向 Account。

建议验证：

```bash
rg -n 'SettingsAccountSection|SettingsTab.account|openAccountSettings|DayflowSignInSheet|管理账单|开始 14 天试用|邀请好友|推荐码|退出登录|登录 Dayflow' \
  Dayflow/Dayflow
```

建议提交信息：

```text
chore(settings): remove Dayflow account surfaces
```

## T13：移除 Referral deep link 和后台使用时长上报

目标：

- App 不再处理 referral/claim/r deep link。
- AppDelegate 不再按 heartbeat/recording state 上报 referral usage。
- 不再写入 `dayflowPendingReferralCode`。

允许范围：

- `Dayflow/Dayflow/App/AppDeepLinkRouter.swift`
- `Dayflow/Dayflow/App/AppDelegate.swift`
- `Dayflow/Dayflow/System/DayflowAuthManager.swift`（仅删除或隔离 referral 相关方法，若 T16 未执行则保留编译所需 auth 壳）
- `Dayflow/Dayflow/AnalyticsEventDictionary.md`

关键改动：

- 删除 `Action.referral`、`saveReferralCode(from:)` 或改成明确 no-op 兼容。
- 删除 `referralUsageStartedAt`、`trackReferralUsageRecordingChange`、`flushReferralUsage` 和相关调用。
- 删除 `reportReferralUsage` 调用链。
- 删除 referral usage / claim / invite 事件字典。

验收标准：

- 启动、录制、心跳、退出不会触发 referral 网络调用。
- `dayflow://referral` 不会保存 pending code 或打开登录。
- AppDelegate 中无 `DayflowAuthManager.shared.reportReferralUsage`。

建议验证：

```bash
rg -n 'referral|Referral|reportReferralUsage|dayflowPendingReferralCode|/v1/referrals' \
  Dayflow/Dayflow/App \
  Dayflow/Dayflow/System \
  Dayflow/Dayflow/AnalyticsEventDictionary.md
```

建议提交信息：

```text
chore(referrals): remove Dayflow referral runtime hooks
```

## T14：移除 Daily 中的 Dayflow Backend provider 路径

目标：

- Daily provider picker 不再展示 Dayflow backend。
- 历史 `dailyRecapProvider_v1=dayflow` 和 `isDailyUnlocked` 不再迁移到 `.dayflow`。
- Daily generation 不再使用 legacy PostHog distinct-id backend auth token。

允许范围：

- `Dayflow/Dayflow/Core/AI/DailyRecapModels.swift`
- `Dayflow/Dayflow/Core/AI/DailyRecapGenerator.swift`
- `Dayflow/Dayflow/Core/AI/DailyRecapScheduler.swift`
- `Dayflow/Dayflow/Views/UI/DailyView+Provider.swift`
- `Dayflow/Dayflow/Views/UI/DailyAccessLockedViews.swift`
- `Dayflow/Dayflow/Views/UI/DailyView+Access.swift`
- 相关 `Dayflow/DayflowTests/*Daily*Tests.swift`（必须新增/更新迁移测试；若新增测试文件，同步更新 project references）

关键改动：

- `DailyRecapProvider.allCases` 删除 `.dayflow`。
- `DailyRecapProvider.load` 对旧 raw value `"dayflow"` 做明确迁移。
- 删除 `usesDayflowInputs` 或确保它恒为 false/不再需要。
- 删除 `DailyStandupGenerationMetadata.legacyDayflow` 或改成兼容 legacy display，不作为新生成 provider。
- `DailyRecapGenerator` 删除 `makeDayflowProvider` 和 `resolvedDayflowEndpoint`。
- Provider availability 不再检查 Dayflow backend。

验收标准：

- Daily provider picker 不显示 Dayflow backend。
- Daily 自动生成不会访问 `/v1/daily`。
- 旧 Daily provider 存储值不会导致生成失败或空白 UI。

强制测试验收：

- 必须新增或更新 Daily 相关 XCTest，覆盖 `dailyRecapProvider_v1=dayflow` 的加载迁移；测试必须断言结果不是 `.dayflow`，并且持久化值不再写回 `"dayflow"`。
- 必须覆盖 `isDailyUnlocked` legacy 状态；测试必须断言它不会触发 `.dayflow` 作为初始 Daily provider。
- 必须覆盖 `DailyRecapProvider.allCases` 或 provider picker 使用的数据源；测试必须断言用户可选 Daily provider 中不存在 `.dayflow` / Dayflow backend。
- 如果保留 legacy metadata display，必须有测试确认它只用于历史展示，不会作为新生成 provider。

建议验证：

```bash
rg -n 'DailyRecapProvider|dayflow|Dayflow backend|/v1/daily|backendAuthToken|makeDayflowProvider|legacyDayflow' \
  Dayflow/Dayflow/Core/AI/DailyRecapModels.swift \
  Dayflow/Dayflow/Core/AI/DailyRecapGenerator.swift \
  Dayflow/Dayflow/Core/AI/DailyRecapScheduler.swift \
  Dayflow/Dayflow/Views/UI/Daily*
```

建议提交信息：

```text
chore(daily): remove Dayflow backend provider
```

## T15：移除 LLMService 中的 Dayflow Backend 生成路径

目标：

- 时间线批处理和普通文本生成不再创建 `DayflowBackendProvider`。
- `LLMProviderType.dayflowBackend` 不再作为活跃 provider 参与 `LLMService` switch。
- `DayflowBackendProvider.swift` 如不再被 Daily 使用，可以在本任务删除；否则等 T14 完成后删除。

允许范围：

- `Dayflow/Dayflow/Core/AI/LLMTypes.swift`
- `Dayflow/Dayflow/Core/AI/LLMService.swift`
- `Dayflow/Dayflow/Core/AI/DayflowBackendProvider.swift`
- `Dayflow/Dayflow/Core/AI/TimelineFailureClassifier.swift`
- `Dayflow/Dayflow/System/AnalyticsService.swift`（仅删除 Dayflow backend auth token 专用逻辑）
- `scripts/release_dmg.sh`（仅删除 `DayflowBackendURL` 注入）
- `Dayflow/Dayflow/Info.plist` / project build settings（仅删除 Dayflow backend URL 配置，若存在）
- 相关 `Dayflow/DayflowTests/*LLM*Tests.swift` / `Dayflow/DayflowTests/*Provider*Tests.swift`（必须新增/更新迁移测试；若新增测试文件，同步更新 project references）

关键改动：

- 删除 `LLMService.makeDayflowProvider` 和 `.dayflow` batch/text provider cases。
- `LLMProviderID.from` 不再返回 `.dayflow`。
- `LLMProviderRoutingPreferences` 不再接受 `.dayflow` backup provider。
- 删除 `DayflowBackendProvider.swift` 后更新 Xcode project references。
- 删除 `DayflowBackendURL` override/config 注入。

验收标准：

- 时间线生成路径只支持 Gemini、local、ChatGPT/Claude CLI。
- 无 session token 缺失导致的 “Dayflow provider unavailable”。
- app 代码不再出现 `/v1/dayflow/transcribe` 或 `/v1/dayflow/generate-cards`。

强制测试验收：

- 必须新增或更新 LLM/provider 相关 XCTest，覆盖 `LLMProviderID.from` 或等效 provider ID 映射；测试必须断言 `.dayflowBackend` 不会映射成可用 routing provider。
- 必须覆盖 `LLMProviderRoutingPreferences` 或等效 routing 偏好清洗逻辑；测试必须断言 legacy `dayflow` backup 不会进入 `LLMService` 的活跃 provider 列表。
- 必须覆盖 legacy `.dayflowBackend` 配置进入生成链路前的迁移/拒绝行为；测试必须断言不会要求 `DayflowAuthManager.storedSessionToken()`。
- 如果 `DayflowBackendProvider.swift` 被删除，必须通过测试构建验证 project references 已清理；如果暂时保留，必须有测试或扫描证明没有活跃调用路径。

建议验证：

```bash
rg -n 'DayflowBackendProvider|dayflowBackend|DayflowBackendURL|/v1/dayflow|storedSessionToken|Dayflow provider unavailable' \
  Dayflow/Dayflow scripts
```

建议提交信息：

```text
chore(ai): remove Dayflow backend generation path
```

## T16：删除认证/计费/推荐残留模型与文档事件

目标：

- 删除不再可达的 auth/billing/referral models 和 manager。
- 删除 Dayflow Pro auth/referral analytics 事件说明。
- 删除 Whats New 中宣传 Dayflow Pro/referral 的当前展示内容或改为历史不可达内容。

允许范围：

- `Dayflow/Dayflow/System/DayflowAuthManager.swift`
- `Dayflow/Dayflow/AnalyticsEventDictionary.md`
- `Dayflow/Dayflow/Views/UI/WhatsNewView.swift`
- `Dayflow/Dayflow.xcodeproj/project.pbxproj`
- `Dayflow/Dayflow/Assets.xcassets/ReferralCardBackground.imageset/*`（仅当无引用）
- `scripts/ui-english-allowlist.txt`（仅当删除文案导致 allowlist 需要更新）

关键改动：

- 删除 `DayflowAuthManager.swift` 或将其缩成一次性 migration helper 后再删除。
- 删除 Auth/Billing/Referral Codable structs、endpoint response/request models。
- 删除 Dayflow Pro onboarding/referral 事件字典。
- 清理 project file 中删除文件的引用。

验收标准：

- `DayflowAuthManager` 不再被 app target 引用。
- `/v1/auth`、`/v1/billing`、`/v1/referrals` 不再出现在 app code。
- referral asset 无引用时被删除。

建议验证：

```bash
rg -n 'DayflowAuthManager|DayflowAuthUser|DayflowEntitlement|DayflowReferral|/v1/auth|/v1/billing|/v1/referrals|Stripe|ReferralCardBackground' \
  Dayflow/Dayflow Dayflow/Dayflow.xcodeproj scripts docs
```

建议提交信息：

```text
chore(auth): remove Dayflow Pro account models
```

## T17：最终残留扫描与项目文件清理

目标：

- 确认 app 代码中没有 Dayflow Pro 可执行路径。
- 清理 dead code、dead assets、project references、docs 中的当前能力描述。
- 更新审计/任务文档的完成状态。

允许范围：

- `docs/LOCAL_NO_LOGIN_LIGHTWEIGHT_REVIEW.md`
- `docs/DAYFLOW_PRO_REMOVAL_TASKS.md`
- `docs/PROJECT_STATUS_AUDIT.md`
- `CLAUDE.md`（仅当 provider 架构说明已不准确）
- `README.md`（仅当公开功能说明已不准确）
- `Dayflow/Dayflow.xcodeproj/project.pbxproj`
- 前序任务遗留的 dead files/assets

关键改动：

- 将已完成任务标记为 done，记录验证结果。
- 更新 CLAUDE 的 AI Provider Architecture，删除 Dayflow Backend 行。
- 如 README 提到 Dayflow Pro/referral，改为本地免登录定位。
- 做全仓 residual scan，确认剩余命中都是历史文档或明确保留的品牌描述。
- 本次扫描中 README 未命中 Dayflow Pro/referral 当前能力描述，因此未修改 README。

验收标准：

- app target 无 Dayflow Pro / Dayflow Backend / auth endpoint 可执行路径。
- 文档与当前架构一致。
- Xcode project 不引用已删除文件。

建议验证：

```bash
rg -n 'Dayflow Pro|Dayflow Backend|dayflowBackend|DayflowAuthManager|/v1/auth|/v1/billing|/v1/referrals|/v1/dayflow|DayflowBackendURL|ReferralCardBackground' .
```

建议提交信息：

```text
chore(local): finalize Dayflow Pro removal cleanup
```

## 通用任务启动样板

复制以下内容到新会话，只修改第一行任务编号即可。

```text
任务编号：T10

在 /Users/yuna/ToolsProject-Github/Dayflow-Yuna 中执行上述任务编号对应的 Dayflow Pro 移除任务。任务定义以 docs/DAYFLOW_PRO_REMOVAL_TASKS.md 为准，背景评审参考 docs/LOCAL_NO_LOGIN_LIGHTWEIGHT_REVIEW.md 和 docs/PROJECT_STATUS_AUDIT.md。完成验证后提交。

开始前读取：
- docs/DAYFLOW_PRO_REMOVAL_TASKS.md
- docs/LOCAL_NO_LOGIN_LIGHTWEIGHT_REVIEW.md
- docs/PROJECT_STATUS_AUDIT.md
- CLAUDE.md
- 本任务允许范围内的相关 Swift / project / script / docs 文件

执行规则：
- 如果 .codegraph/ 存在，先用 CodeGraph 理解目标文件和调用影响面。
- 只修改本任务允许范围；若文档中找不到该任务编号，停止并报告。
- 优先移除 Dayflow Pro / Dayflow Backend / Dayflow 账号相关可执行路径，不保留半失效 paywall。
- Routing 中不得继续展示、选择、写回或 fallback 到 Dayflow Pro / Dayflow Backend。
- 保留 Gemini、ChatGPT/Claude CLI、本地 Ollama/LM Studio 作为非 Dayflow 登录的替代路径。
- 处理历史 UserDefaults / Keychain / Codable 偏好时必须有明确迁移或兼容策略，不允许静默落到不可用状态。
- 不要顺手重构与任务无关的 UI、数据模型、analytics 或 release 流程。
- 不要用全局替换；字符串、provider id、analytics key、UserDefaults key、JSON key、asset 名、URL、命令、模型名、品牌名必须按任务目标逐个判断。

提交前自检：
1. 查看 Swift/project/script/docs diff：
   git diff -- '*.swift' '*.pbxproj' '*.sh' '*.md' '*.plist'

2. 确认 diff 只改了本任务允许范围，没有顺手修改无关功能。

3. 运行任务定义中的建议验证命令；如果命中仍存在，逐条说明是已保留、历史文档、还是待后续任务处理。

4. 至少运行一次残留扫描：
   rg -n 'Dayflow Pro|Dayflow Backend|dayflowBackend|DayflowAuthManager|/v1/auth|/v1/billing|/v1/referrals|/v1/dayflow|DayflowBackendURL|ReferralCardBackground' Dayflow scripts docs

5. 按 CLAUDE.md 运行相关构建或测试。默认至少运行：
   env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig GIT_ALLOW_PROTOCOL=file:https xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -configuration Debug -derivedDataPath build/local-derived CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build

   如任务包含测试或迁移逻辑，补充运行相关 XCTest；若因环境、签名、SwiftPM 或 UI runner 失败，说明失败阶段和已完成的替代验证。

提交：
- 通过自检后提交。
- commit message 使用任务定义中的建议提交信息，或使用同等清晰英文信息。

交付报告：
- 修改文件列表
- 实现内容
- 测试/扫描结果
- 剩余 Dayflow Pro / Dayflow Backend 命中及处理理由
- 历史偏好迁移策略
- 是否发现并修复超范围改动
- 未解决问题
```

## 执行顺序建议

首批建议按 T10 -> T11 -> T12 -> T13 -> T14 执行。这样先切断用户可见 routing 和 onboarding，再移除账号/referral/daily 远端路径，风险最小。

T15-T17 建议在前五个任务编译通过后执行，因为它们更容易触发跨文件 project reference 和 dead code 清理。
