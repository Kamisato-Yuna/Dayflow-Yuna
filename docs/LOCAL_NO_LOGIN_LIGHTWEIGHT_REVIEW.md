# Dayflow 本地免登录轻量化评审

日期：2026-07-02
分支：`codex/remove-account-local-tool-review`

更新：2026-07-03 已完成 `docs/DAYFLOW_PRO_REMOVAL_TASKS.md` T10-T17。Dayflow Pro / Dayflow Backend / auth-billing-referral 可执行路径已从 app 中移除；本文保留原始评审证据，供后续完全离线化或遥测/更新策略决策参考。

## 结论

可行，但不建议只删除登录 UI。当前账号机制绑定了四类能力：Dayflow Pro 登录/订阅、远端 Dayflow Backend provider、推荐奖励系统、Daily 的 legacy backend 路径。若目标是“不需要登录的本地工具”，应把账号能力视为一组线上商业化/托管能力整体裁剪，并将默认 AI 路线收敛到用户自带或本机提供商：Gemini API Key、ChatGPT/Claude CLI、本地 Ollama/LM Studio。

推荐方案：

1. 已完成：移除账号登录和 Dayflow Pro provider 的用户入口，并把旧的 `dayflow` / `dayflowBackend` 偏好迁移到非 Dayflow provider。
2. 已完成：移除后台 referral usage 上报和 referral deep link 写入，避免隐藏网络行为。
3. 已完成：删除 `DayflowAuthManager`、`DayflowBackendProvider`、billing/referral 数据结构和相关 analytics 字典的 app 可执行路径。
4. 待决策：是否进入“完全离线版”，即进一步裁剪 PostHog/Sentry、Sparkle 更新、release survey、外部下载入口。

## 当前账号机制证据

| 能力 | 当前实现 | 影响判断 |
| --- | --- | --- |
| 邮箱验证码登录 | `DayflowAuthManager.sendCode` 调 `/v1/auth/code/start`，`verifyCode` 调 `/v1/auth/code/verify`，成功后把 session token 写入 Keychain。 | 直接违反免登录目标，应移除或改成始终无账号状态。 |
| Session/entitlement | `DayflowAuthManager` 读取 Keychain `com.teleportlabs.dayflow.auth` / `session_token`，并通过 `/v1/me` 刷新 `DayflowEntitlement`。 | 如果保留 entitlement，会继续产生“本地工具但有账号状态”的二义性。 |
| Stripe/试用 | `openBillingCheckout`、`openBillingPortal`、`startNoCardTrial` 调 `/v1/billing/*`。 | 属于商业化账号能力，免登录版本应删除入口。 |
| Referral | 设置页、onboarding、deep link、AppDelegate usage heartbeat 都接入 referral。 | 不能只删设置页，否则仍会保存 pending referral code 或上报使用时长。 |
| Dayflow Backend provider | `LLMService` 通过 `DayflowAuthManager.storedSessionToken()` 创建 `DayflowBackendProvider`，远端处理截图转写和卡片生成。 | 这是最大的功能影响点：移除后要确保 provider 选择、失败提示和旧偏好迁移都有替代路径。 |
| Daily backend | `DailyRecapGenerator` 使用 `AnalyticsService.backendAuthToken()` 创建 `DayflowBackendProvider`，这是 legacy PostHog distinct-id token 路径，不是账号 session。 | 若目标只是免登录，可先迁移/隐藏 `.dayflow` Daily provider；若目标完全本地，需要彻底删除。 |
| Settings Account tab | `SettingsView` 默认选中 `.account`，渲染 `SettingsAccountSection`。 | 删除账号页时需要调整默认 tab、侧边栏和 `.openAccountSettings` 通知。 |
| Onboarding Dayflow Pro | `OnboardingPrototypeChooseProviderStep` 默认推荐 `dayflow`，内含登录、验证码、推荐码、试用步骤。 | 需要改成本地/自带 provider onboarding，否则新用户仍被引向登录。 |

## 裁剪范围

### P0 必做

1. 设置页入口
   - 删除或替换 `SettingsTab.account`。
   - 默认 tab 从 `.account` 改为 `.providers` 或 `.storage`。
   - 删除 `.openAccountSettings` 导航依赖，或把它安全重定向到 `.providers`。
   - 移除 `SettingsAccountSection`、`DayflowSignInSheet`、Pro 升级卡、referral card 的可见入口。

2. Provider 路由
   - 从 `LLMProviderType` 和 `LLMProviderID` 中移除或弃用 `.dayflowBackend` / `.dayflow`。
   - `LLMProviderType.load` 必须处理历史值：`llmProviderType == dayflowBackend` 或 `selectedLLMProvider == dayflow` 时迁移到保守默认值。
   - 建议默认值：已有 Gemini key 则 `gemini`，否则有本地配置则 `ollama`，否则 `gemini` 并进入 provider setup。
   - `ProvidersSettingsViewModel.providerCatalog` 删除 `Dayflow Pro` 项。
   - `SettingsProvidersTabView` 删除 dayflow 状态、升级账号按钮和 paywall 文案。

3. Onboarding
   - `OnboardingPrototypeChooseProviderStep` 删除 `Dayflow Pro` 卡片、登录面板、referral/trial 子步骤。
   - 推荐顺序调整为：已有付费 AI 用户优先 ChatGPT/Claude CLI；没有付费 AI 用户优先 Gemini；“本地”保留但不作为新手默认。
   - `OnboardingFlow` 删除 provider title 到 `dayflow` 的映射，以及 `selectedProvider == "dayflow"` 时跳过 `llmSetup` 的分支。

4. 隐藏网络行为
   - 删除 `AppDelegate.flushReferralUsage` 中对 `DayflowAuthManager.shared.reportReferralUsage` 的调用链。
   - `AppDeepLinkRouter` 删除 `referral/claim/r` action，或改为 no-op 并记录兼容日志。
   - 清理 `dayflowPendingReferralCode`、`dayflowAccountEmail`、Keychain session token 的读写路径。

### P1 建议

1. 删除 `DayflowAuthManager.swift` 及其模型，或先用小型 migration helper 清理旧 Keychain/UserDefaults 后删除。
2. 删除 `DayflowBackendProvider.swift`，前提是 Daily 的 `.dayflow` provider 也已移除或迁移。
3. `DailyRecapProvider` 删除 `.dayflow`，`migrateInitialSelection` 不再因为 `isDailyUnlocked` 选择远端 provider。
4. `DailyRecapGenerator` 删除 `makeDayflowProvider` 和 `resolvedDayflowEndpoint`。
5. `DailyProviderPicker` 和 `DailyProviderOnboardingView` 不再显示 Dayflow backend。
6. `TimelineFailureClassifier` 删除 `dayflowProRequired` 和 account destination，或改成 provider settings destination。
7. `AnalyticsEventDictionary.md` 删除 Dayflow Pro auth/referral 事件，或标记为历史事件。
8. release 脚本删除 `DayflowBackendURL` 注入，Info.plist/debug override 同步清理。

### P2 可选

1. 删除 What's New 里 Dayflow Pro/referral 旧发布文案或归档。
2. 删除 referral 图片资源。
3. 若定位为“完全离线”，再评估 PostHog/Sentry 默认 opt-in、Sparkle appcast、release survey、外部下载安装链接。

## 影响面

### 用户体验

- 设置页会少一个“账号”tab，第一屏需要改为 Providers 或 Storage。
- 新用户不再看到 Dayflow Pro 零配置路线，必须选择 Gemini、ChatGPT/Claude CLI 或本地模型。
- 已选择 Dayflow provider 的老用户首次启动后需要被迁移到可用 provider，并看到清晰提示，而不是静默失败。
- 推荐奖励、试用、管理账单、退出登录入口全部消失。

### 数据与隐私

- 本地历史时间线、截图、卡片、Daily/Weekly 数据不依赖账号机制，原则上不需要迁移。
- 需要清理的本地账号残留包括：
  - Keychain service `com.teleportlabs.dayflow.auth`
  - UserDefaults `dayflowAccountEmail`
  - UserDefaults `dayflowPendingReferralCode`
  - UserDefaults `selectedLLMProvider == dayflow`
  - Codable `llmProviderType == dayflowBackend`
  - Daily provider `dailyRecapProvider_v1 == dayflow`
- 如果只做“免登录”而非“完全离线”，Gemini/ChatGPT/Claude 仍可能访问外部服务；文案应避免承诺完全离线。

### 架构

- 账号机制当前是 UI、provider 路由、远端生成、analytics 和 deep link 的横向依赖，不是单文件删除。
- 删除 `.dayflowBackend` 会影响 `LLMService.processBatch`、`generateText`、Daily recap provider、provider fallback routing。
- `DayflowBackendProvider` 被 CodeGraph 标记为 39 个 indexed dependents，许多是类型/模型引用，删除时要按编译错误收口。
- `DayflowAuthManager.signOut` 只有设置页和 onboarding 原型调用，但 `DayflowAuthManager` 静态 session token 读取被 `LLMService` 直接使用，不能只按 UI caller 判断。

### 测试

T10-T15 已补充 provider、Daily 和 LLM routing 的 legacy 迁移测试。后续 smoke / 集成验证仍建议覆盖：

1. Onboarding：选择页不出现 Dayflow Pro，所有 provider 都进入正确 setup 或完成路径。
2. 静态扫描：`DayflowAuthManager`、`DayflowBackendProvider`、`/v1/auth`、`/v1/billing`、`/v1/referrals` 不再出现在 app 代码路径中。
3. 冒烟验证：首次启动、重置 onboarding、设置页打开、provider 切换、生成时间线失败提示、Daily provider picker。

## 建议实施顺序

1. 已完成：provider 偏好迁移和 UI 隐藏，让旧用户不会继续落到不可用的 Dayflow provider。
2. 已完成：account/referral/billing UI 和 background reporting 清理。
3. 已完成：`DayflowAuthManager`、`DayflowBackendProvider` 及模型清理。
4. 已完成：文档、analytics 字典、资源、release 脚本和 Info.plist key 清理。

## 不建议本轮包含

- 不建议同时重做 Daily/Weekly/Chat 产品结构。
- 不建议把 Gemini、ChatGPT/Claude CLI、本地模型也归为“账号机制”删除；它们是免 Dayflow 登录后的替代运行方式。
- 不建议在没有确认前删除 Sparkle 更新或 PostHog/Sentry；这是“完全离线版”范围，不是“免 Dayflow 登录”必需范围。

## 待确认问题

1. 目标是“免 Dayflow 登录”，还是“完全离线、无任何外部网络”？
2. 历史 `dayflow` provider 用户应默认迁移到 `gemini`、`local` 还是 `none`？
3. Daily 是否继续允许 Gemini/ChatGPT/Claude 这类外部 provider，还是只能本地模型？
4. Sparkle 自动更新和 `dayflow.so` appcast 是否保留？
5. PostHog/Sentry 是否保留为可关闭遥测，还是默认关闭/删除？

## 相关现有文档

- `docs/DAYFLOW_PRO_REMOVAL_TASKS.md` 将本评审拆成 T10 起的可执行任务，并记录 T10-T17 完成状态。
- `docs/PROJECT_STATUS_AUDIT.md` 已在第 9 节更新账号登录与线上能力移除状态，可作为背景审计文档。
- `Dayflow/Dayflow/AnalyticsEventDictionary.md` 已清理 Dayflow Pro onboarding/referral 相关事件；历史决策以任务文档和 git 记录追踪。
- `CLAUDE.md` 记录了本仓库本地 build/run/test 路径，后续代码实现完成后应用它做验证。
