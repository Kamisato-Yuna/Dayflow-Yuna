# Dayflow v2.0.0 上游合并任务拆分

日期：2026-07-04
适用分支：`codex/liquid-glass-ui-refresh` 及后续任务分支
上游范围：`JerryZLiu/Dayflow` 的 `v1.14.1..v2.0.0`
目标读者：Codex 执行代理、代码审核者、人工验收者

## 启动提示词模板

复制下面整段作为新会话启动提示词。通常只需要修改第一行任务编号。

```text
任务编号：UV20-01

请在 /Users/yuna/ToolsProject-Github/Dayflow-Yuna 仓库、当前分支 codex/liquid-glass-ui-refresh 上执行 docs/UPSTREAM_V2_MERGE_TASKS.md 中上述任务编号对应的上游 v2.0.0 合并任务。

执行要求：
1. 开始前读取 CLAUDE.md、docs/UPSTREAM_V2_MERGE_TASKS.md、该任务允许范围内的现有文件。
2. 如果文档中找不到上述任务编号，停止并报告，不要猜测任务内容。
3. 如果仓库根目录存在 .codegraph/，先用 CodeGraph 理解目标 Swift 文件、调用关系和影响面，再做搜索或编辑。
4. 开发前先用中文复述本任务的实现方案、允许修改范围、验证命令；随后按方案执行。若发现任务范围不足以编译或达成验收，先报告需要扩展的文件，不要顺手扩大范围。
5. 只修改本任务允许范围内的文件；不要处理其他任务的残留，不要重构无关代码。
6. 如本地缺少上游引用，先只获取只读比较引用：
   git fetch https://github.com/JerryZLiu/Dayflow.git refs/tags/v1.14.1:refs/upstream/jerry/tags/v1.14.1 refs/tags/v2.0.0:refs/upstream/jerry/tags/v2.0.0
7. 上游补丁只能作为参考，不要整包 merge `v2.0.0`。禁止重新引入 Dayflow Pro、Dayflow Backend、账号登录、计费、referral、托管后端 URL、release/appcast 轨道。
8. 保留本地既有方向：简体中文 UI、Dayflow Pro/Backend 移除、Gemini / ChatGPT / Claude CLI / 本地 Ollama/LM Studio 路径、Liquid Glass 视觉系统。
9. 修改后运行本任务列出的验证命令；如果 GUI、SwiftPM、签名或完整 Xcode 验证无法运行，必须说明具体原因和替代验证。
10. 验证通过后按本任务建议提交信息提交本任务范围内的变更；如果工作区有无关改动，不要纳入提交。

交付说明必须包含：
- 修改文件列表
- 实现内容
- 验证结果
- 未合入的上游内容及原因
- 未解决问题
- 下一步建议
```

## 总目标

从上游 `v2.0.0` 中吸收对本地 fork 有价值、且不违背本地产品方向的改动。当前 fork 与上游同源于 `v1.14.1`，之后本地已有中文化、Dayflow Pro/Backend 移除、Liquid Glass UI 等本地提交；上游 `v2.0.0` 同期新增了 Chat 体验、组件拆分、空闲批次分类抽离、账号/后端配置和 release 配置。

本任务集采用手工移植或小范围 cherry-pick，不做整包合并。

## 当前评估结论

可以合并或整理：

1. Chat 体验增强：
   - Chat helper 拆分：`ChatModels.swift`、`ChatPromptBuilder.swift`、`ChatMetadataParser.swift`。
   - 对话历史存储：`StorageManager+ChatHistory.swift`、`chat_conversations`、`chat_messages`。
   - 历史面板、滚动支持、多行输入。
   - rich markdown 渲染。
2. 空闲批次分类整理：
   - 本地已经有 `AnalysisManager` 内联版空闲分类逻辑。
   - 可参考上游 `IdleBatchClassifier.swift` 做纯逻辑抽离，并补齐中文 Idle 卡片文案。
3. 低风险 refactor：
   - `ProvidersSettingsViewModel+PromptOverrides.swift` 将 prompt override 持久化逻辑从大 view model 中拆出。

暂不建议合并：

1. Dayflow Pro / Dayflow Backend / 账号 / 计费 / referral：
   - `DayflowBackendConfiguration.swift`
   - `DayflowBackendProvider.swift`
   - `DayflowAuthManager.swift`
   - `DayflowSignInSheet.swift`
   - `DayflowProOnboardingSignIn.swift`
   - `SettingsAccountSection.swift`
2. release 和分发轨道：
   - `docs/appcast.xml`
   - `Info.plist` 中 `DayflowBackendURL`
   - `scripts/release_dmg.sh` 要求后端 URL 的改动
   - `MARKETING_VERSION=2.0.0` / `CURRENT_PROJECT_VERSION=114`
3. 大面积 UI 文件拆分：
   - Day goal、category picker、timeline、journal、weekly sankey 等拆分本身有价值，但本地已经叠加中文化和 Liquid Glass 改造，直接移植容易回退文案和视觉系统。
   - 这些只在后续维护对应模块时按需局部参考，不作为本批合并任务。

## 通用执行原则

1. 每个任务只修改该任务允许范围内的文件。
2. `.codegraph/` 存在时，先用 CodeGraph 理解相关 Swift 文件和影响面。
3. 任何任务都不得重新引入 Dayflow Pro / Dayflow Backend 可执行路径。
4. 上游英文 UI 文案必须转为简体中文；品牌名、命令、模型名、provider raw value、analytics key、UserDefaults key、URL 保持原样。
5. 不直接套用上游 `project.pbxproj` 版本号、签名、release、xcuserdata 改动。
6. 新增 Swift 文件后必须确认 Xcode project / filesystem synchronized group 能纳入 target；如需改 `project.pbxproj`，只加入本任务文件或包依赖。
7. 数据库 schema 改动必须是向前兼容的 `CREATE TABLE IF NOT EXISTS` 或有显式列存在性检查。
8. 任务结束必须跑 `git diff --check` 和任务定义中的构建/扫描命令。

## 统一验证命令

多数代码任务至少运行 Debug build：

```bash
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig \
  GIT_ALLOW_PROTOCOL=file:https \
  xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow \
  -configuration Debug \
  -derivedDataPath build/local-derived \
  CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  build
```

通用残留防护：

```bash
rg -n 'Dayflow Pro|Dayflow Backend|dayflowBackend|DayflowAuthManager|DayflowBackendURL|/v1/auth|/v1/billing|/v1/referrals|/v1/dayflow' Dayflow/Dayflow Dayflow/Dayflow.xcodeproj scripts docs
```

中文 UI 防护：

```bash
bash scripts/audit-ui-english.sh Dayflow/Dayflow/Views/UI/Chat Dayflow/Dayflow/Core/Analysis Dayflow/Dayflow/Views/UI/Settings
```

Diff 自检：

```bash
git diff --check
git diff -- '*.swift' '*.pbxproj' '*.resolved' '*.sh' '*.md' '*.plist'
```

## 任务总览

| 任务编号 | 标题 | 优先级 | 主要目标 |
| --- | --- | --- | --- |
| UV20-01 | 抽离空闲批次分类器并中文化 Idle 卡片 | P0 | 将本地内联 idle classifier 收敛为上游式纯逻辑文件，保留现有行为并补齐中文文案。 |
| UV20-02 | 拆分 Settings prompt override 持久化逻辑 | P1 | 将 `ProvidersSettingsViewModel` 的 prompt override load/save 逻辑移入 extension，降低后续冲突。 |
| UV20-03 | 拆分 ChatService helper 类型和 prompt builder | P1 | 参考上游拆出 Chat shared models、metadata parser、prompt builder，不改变 Chat 行为。 |
| UV20-04 | 合入 Chat 对话历史存储 | P0 | 新增 chat conversation/message schema 与 StorageManager API，并把 ChatService 对话保存/加载接上。 |
| UV20-05 | 合入 Chat 历史面板、滚动和多行输入体验 | P1 | 在本地中文/Liquid Glass UI 基础上实现历史列表、新对话、删除、滚动和多行 composer。 |
| UV20-06 | 合入 rich markdown 渲染 | P2 | 引入 markdown 渲染能力和必要 SwiftPM 依赖，保持中文 UI 与构建可验证。 |

## UV20-01：抽离空闲批次分类器并中文化 Idle 卡片

目标：

- 参考上游 `a34552ad` / `ac11b2fb`，把当前 `AnalysisManager.swift` 内联的 `IdleBatchRules`、`IdleBatchAssessment`、`assessIdleBatch`、coverage merge/gap 逻辑抽到 `Dayflow/Dayflow/Core/Analysis/IdleBatchClassifier.swift`。
- 保持现有行为、analytics 字段和 `IdleCardMetadata` 存储结构不变。
- 将用户可见 Idle 卡片文案中文化，避免上游英文文案回流。

允许范围：

- `Dayflow/Dayflow/Core/Analysis/AnalysisManager.swift`
- `Dayflow/Dayflow/Core/Analysis/IdleBatchClassifier.swift`
- 如编译需要，限量修改 `Dayflow/Dayflow.xcodeproj/project.pbxproj`
- 如新增测试，限 `Dayflow/DayflowTests/`

上游参考：

```bash
git show refs/upstream/jerry/tags/v2.0.0:Dayflow/Dayflow/Core/Analysis/IdleBatchClassifier.swift
git diff refs/upstream/jerry/tags/v1.14.1 refs/upstream/jerry/tags/v2.0.0 -- Dayflow/Dayflow/Core/Analysis/AnalysisManager.swift
```

关键改动：

1. 新增 `IdleBatchClassifier.swift`，承载纯分类规则、assessment 和 coverage helper。
2. `AnalysisManager` 调用 `IdleBatchClassifier.assess(_:)`。
3. `AnalysisManager` 只保留业务编排：保存 idle card、合并相邻 idle card、analytics、batch status。
4. `makeIdleCard` 的 `category`、`title`、`summary`、`detailedSummary` 使用简体中文；若 analytics 或归一化逻辑依赖 `"Idle"`，必须明确保留内部比较兼容。

验收标准：

- `AnalysisManager.swift` 不再包含大段纯分类 helper。
- 空闲批次判定阈值与上游一致，且不改变现有 `IdleCardMetadata` 字段。
- 用户可见 idle card 不出现英文 UI 文案。
- Pro/backend 残留扫描没有新增命中。

验证命令：

```bash
rg -n 'IdleBatchRules|IdleBatchAssessment|assessIdleBatch|mergeCoverageSegments|invertedCoverageSegments|Idle period|You were idle|category: "Idle"|title: "Idle"' \
  Dayflow/Dayflow/Core/Analysis/AnalysisManager.swift \
  Dayflow/Dayflow/Core/Analysis/IdleBatchClassifier.swift

env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig \
  GIT_ALLOW_PROTOCOL=file:https \
  xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow \
  -configuration Debug \
  -derivedDataPath build/local-derived \
  CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  build

git diff --check
```

建议提交信息：

```text
refactor(analysis): extract idle batch classifier
```

## UV20-02：拆分 Settings prompt override 持久化逻辑

目标：

- 参考上游 `4a6227a9`，将 `ProvidersSettingsViewModel` 中 Ollama / Chat CLI prompt override 的 load/save/persist 逻辑拆到 `ProvidersSettingsViewModel+PromptOverrides.swift`。
- 不改变 provider routing、legacy migration、中文 UI 或 Dayflow Pro 移除结果。

允许范围：

- `Dayflow/Dayflow/Views/UI/Settings/ProvidersSettingsViewModel.swift`
- `Dayflow/Dayflow/Views/UI/Settings/ProvidersSettingsViewModel+PromptOverrides.swift`
- 如编译需要，限量修改 `Dayflow/Dayflow.xcodeproj/project.pbxproj`
- `Dayflow/DayflowTests/ProvidersSettingsViewModelTests.swift`（仅当现有测试需要同步访问级别或覆盖行为）

上游参考：

```bash
git show refs/upstream/jerry/tags/v2.0.0:Dayflow/Dayflow/Views/UI/Settings/ProvidersSettingsViewModel+PromptOverrides.swift
git diff refs/upstream/jerry/tags/v1.14.1 refs/upstream/jerry/tags/v2.0.0 -- Dayflow/Dayflow/Views/UI/Settings/ProvidersSettingsViewModel.swift
```

关键改动：

1. 移动 prompt override 相关方法，不移动 provider catalog、routing、Dayflow legacy migration。
2. 保持方法访问级别足够 extension 调用，但不额外公开。
3. 确认拆分后 `ProvidersSettingsViewModel.swift` 不重新出现 Dayflow provider 入口。

验收标准：

- Settings provider 行为不变。
- `ProvidersSettingsViewModel.swift` 行数下降，prompt override 逻辑集中在 extension 文件。
- `ProvidersSettingsViewModelTests` 仍通过。

验证命令：

```bash
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig \
  GIT_ALLOW_PROTOCOL=file:https \
  xcodebuild test -project Dayflow/Dayflow.xcodeproj -scheme Dayflow \
  -destination 'platform=macOS' \
  -derivedDataPath build/test-derived \
  -only-testing:DayflowTests/ProvidersSettingsViewModelTests

rg -n 'Dayflow Pro|dayflowBackend|providerCatalog|openAccountForDayflow|selectedLLMProvider' \
  Dayflow/Dayflow/Views/UI/Settings/ProvidersSettingsViewModel.swift \
  Dayflow/Dayflow/Views/UI/Settings/ProvidersSettingsViewModel+PromptOverrides.swift \
  Dayflow/DayflowTests/ProvidersSettingsViewModelTests.swift

git diff --check
```

建议提交信息：

```text
refactor(settings): split prompt override persistence
```

## UV20-03：拆分 ChatService helper 类型和 prompt builder

目标：

- 参考上游 `c17292aa`，把 `ChatService.swift` 中可纯拆分的 shared models、metadata parser、prompt builder 移到独立文件。
- 本任务只做结构拆分，不新增历史持久化、不改 UI、不改 provider 行为。

允许范围：

- `Dayflow/Dayflow/Core/AI/ChatService.swift`
- `Dayflow/Dayflow/Core/AI/ChatModels.swift`
- `Dayflow/Dayflow/Core/AI/ChatPromptBuilder.swift`
- `Dayflow/Dayflow/Core/AI/ChatMetadataParser.swift`
- 如编译需要，限量修改 `Dayflow/Dayflow.xcodeproj/project.pbxproj`

上游参考：

```bash
git show refs/upstream/jerry/tags/v2.0.0:Dayflow/Dayflow/Core/AI/ChatModels.swift
git show refs/upstream/jerry/tags/v2.0.0:Dayflow/Dayflow/Core/AI/ChatPromptBuilder.swift
git show refs/upstream/jerry/tags/v2.0.0:Dayflow/Dayflow/Core/AI/ChatMetadataParser.swift
git diff refs/upstream/jerry/tags/v1.14.1 refs/upstream/jerry/tags/v2.0.0 -- Dayflow/Dayflow/Core/AI/ChatService.swift
```

关键改动：

1. 先用 CodeGraph 理解本地 `ChatService` 的 CLI session、memory、tool call、debug panel、feedback 逻辑。
2. 只抽离没有业务行为变化的类型和 helper。
3. 上游 helper 中的英文 prompt 是否属于 LLM 内部提示要逐条判断；用户可见文案必须保持本地中文规范。
4. 不引入 `DayflowBackendConfiguration` 或任何 backend endpoint。

验收标准：

- Chat 发消息、Gemini/CLI provider、memory invalidation、tool status 行为保持不变。
- `ChatService.swift` 中不再承载明显可复用的 parser/prompt builder 大块代码。
- 编译通过。

验证命令：

```bash
rg -n 'DayflowBackend|DayflowAuthManager|Dayflow Pro|/v1/dayflow|DayflowBackendURL' Dayflow/Dayflow/Core/AI

env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig \
  GIT_ALLOW_PROTOCOL=file:https \
  xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow \
  -configuration Debug \
  -derivedDataPath build/local-derived \
  CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  build

git diff --check
```

建议提交信息：

```text
refactor(chat): split service helpers
```

## UV20-04：合入 Chat 对话历史存储

目标：

- 参考上游 `21c83e68`，新增对话历史表和 StorageManager API。
- 将 ChatService 当前对话保存、加载、删除接入本地 Chat provider 体系。
- 保持已有 Chat beta、dashboard memory、CLI session 行为不被破坏。

允许范围：

- `Dayflow/Dayflow/Core/Recording/StorageManager.swift`
- `Dayflow/Dayflow/Core/Recording/StorageManager+ChatHistory.swift`
- `Dayflow/Dayflow/Core/AI/ChatService.swift`
- `Dayflow/Dayflow/Models/ChatMessage.swift`
- 如 UV20-03 已完成，可同步使用：
  - `Dayflow/Dayflow/Core/AI/ChatModels.swift`
  - `Dayflow/Dayflow/Core/AI/ChatPromptBuilder.swift`
  - `Dayflow/Dayflow/Core/AI/ChatMetadataParser.swift`
- 如编译需要，限量修改 `Dayflow/Dayflow.xcodeproj/project.pbxproj`

上游参考：

```bash
git show refs/upstream/jerry/tags/v2.0.0:Dayflow/Dayflow/Core/Recording/StorageManager+ChatHistory.swift
git diff refs/upstream/jerry/tags/v1.14.1 refs/upstream/jerry/tags/v2.0.0 -- Dayflow/Dayflow/Core/Recording/StorageManager.swift Dayflow/Dayflow/Models/ChatMessage.swift Dayflow/Dayflow/Core/AI/ChatService.swift
```

关键改动：

1. `migrate()` 中新增 `chat_conversations` 和 `chat_messages`，使用 `CREATE TABLE IF NOT EXISTS`。
2. 新增 `ChatConversationRecord` 和保存/读取/删除 API。
3. ChatService 在用户消息、助手消息、清空、加载历史时持久化一致。
4. provider 存储使用本地 `DashboardChatProvider.rawValue`，不引入上游 Dayflow backend provider。
5. 对话标题生成可以参考上游，但面板可见标题需要保持自然中文或用户原文。

验收标准：

- 首次启动会自动创建 chat history 表，不破坏旧数据库。
- 一段对话完成后能保存为 conversation record。
- 删除 conversation 会删除对应 messages。
- 切换 provider 的既有确认/重置语义不被破坏。

验证命令：

```bash
rg -n 'chat_conversations|chat_messages|saveChatConversation|fetchChatConversations|fetchChatMessages|deleteChatConversation' \
  Dayflow/Dayflow/Core/Recording \
  Dayflow/Dayflow/Core/AI/ChatService.swift \
  Dayflow/Dayflow/Models/ChatMessage.swift

env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig \
  GIT_ALLOW_PROTOCOL=file:https \
  xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow \
  -configuration Debug \
  -derivedDataPath build/local-derived \
  CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  build

git diff --check
```

建议提交信息：

```text
feat(chat): persist conversation history
```

## UV20-05：合入 Chat 历史面板、滚动和多行输入体验

目标：

- 参考上游 `b6eff773`、`dfd89ef1`、`48e5de34`、`cf829761`，在本地 Chat 页面加入历史面板、滚动到底部、新对话、删除历史、多行输入。
- 基于本地 Liquid Glass / 中文 UI 风格重写，不直接带回上游白底/英文面板。

允许范围：

- `Dayflow/Dayflow/Views/UI/ChatView.swift`
- `Dayflow/Dayflow/Views/UI/ChatView+Actions.swift`
- `Dayflow/Dayflow/Views/UI/ChatView+Content.swift`
- `Dayflow/Dayflow/Views/UI/ChatComposerTextField.swift`
- `Dayflow/Dayflow/Views/UI/ChatHistoryPanel.swift`
- `Dayflow/Dayflow/Views/UI/ChatScrollSupport.swift`
- `Dayflow/Dayflow/Views/UI/ChatMessageViews.swift`
- `Dayflow/Dayflow/Views/UI/DayflowSurfaceStyles.swift`（仅当需要复用现有 surface token，不新增无关视觉系统）
- 如编译需要，限量修改 `Dayflow/Dayflow.xcodeproj/project.pbxproj`

前置条件：

- 建议先完成 UV20-04。若未完成，本任务只能实现 UI 壳和内存态，不应假装已持久化。

上游参考：

```bash
git show refs/upstream/jerry/tags/v2.0.0:Dayflow/Dayflow/Views/UI/ChatHistoryPanel.swift
git show refs/upstream/jerry/tags/v2.0.0:Dayflow/Dayflow/Views/UI/ChatScrollSupport.swift
git diff refs/upstream/jerry/tags/v1.14.1 refs/upstream/jerry/tags/v2.0.0 -- Dayflow/Dayflow/Views/UI/ChatView.swift Dayflow/Dayflow/Views/UI/ChatView+Actions.swift Dayflow/Dayflow/Views/UI/ChatView+Content.swift Dayflow/Dayflow/Views/UI/ChatComposerTextField.swift
```

关键改动：

1. 新增历史面板开关和列表。
2. 历史分组文案中文化：今天、昨天、本周、更早。
3. 新对话、删除对话、加载对话需禁用正在处理状态。
4. 多行输入必须稳定：Enter 发送、Shift+Enter 换行，或按本地现有快捷键约定实现并在代码中保持清晰。
5. 保持 message body 视觉可读，不把内容层过度玻璃化。

验收标准：

- Chat 空态、消息态、处理中、历史为空、历史列表、有当前会话、高亮、删除状态都能渲染。
- 中文扫描不新增未说明英文 UI。
- Reduce Motion / Reduce Transparency 不出现明显不可读状态。

验证命令：

```bash
bash scripts/audit-ui-english.sh Dayflow/Dayflow/Views/UI/ChatView.swift Dayflow/Dayflow/Views/UI/ChatView+Content.swift Dayflow/Dayflow/Views/UI/ChatHistoryPanel.swift Dayflow/Dayflow/Views/UI/ChatComposerTextField.swift

env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig \
  GIT_ALLOW_PROTOCOL=file:https \
  xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow \
  -configuration Debug \
  -derivedDataPath build/local-derived \
  CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  build

git diff --check
```

建议提交信息：

```text
feat(chat): add conversation history panel
```

## UV20-06：合入 rich markdown 渲染

目标：

- 参考上游 `6b10fb7a` 和 `90d8e1d9`，改进 Chat markdown 渲染，支持更稳定的 streamed markdown block 和富文本回复。
- 如必须引入 `swift-markdown-ui`，只引入必要 SwiftPM 包和 target product，不带上游版本号、backend URL 或 release 改动。

允许范围：

- `Dayflow/Dayflow/Views/UI/ChatMarkdownRenderer.swift`
- `Dayflow/Dayflow/Views/UI/ChatMessageViews.swift`
- `Dayflow/Dayflow.xcodeproj/project.pbxproj`
- `Dayflow/Dayflow.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- 如 UI 需要极小适配，限 `Dayflow/Dayflow/Views/UI/ChatView+Content.swift`

上游参考：

```bash
git diff refs/upstream/jerry/tags/v1.14.1 refs/upstream/jerry/tags/v2.0.0 -- Dayflow/Dayflow/Views/UI/ChatMarkdownRenderer.swift Dayflow/Dayflow/Views/UI/ChatMessageViews.swift Dayflow/Dayflow.xcodeproj/project.pbxproj Dayflow/Dayflow.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
```

关键改动：

1. 先判断是否可以在现有 renderer 上增强；只有确有收益时才引入 `MarkdownUI`。
2. 如果引入 SwiftPM 依赖，只加入：
   - `https://github.com/gonzalezreal/swift-markdown-ui`
   - 对应解析出的 transitive pins
   - app target 的 `MarkdownUI` product
3. 不复制上游 `MARKETING_VERSION`、`CURRENT_PROJECT_VERSION`、`DayflowBackendURL`、`Config/Dayflow.xcconfig`。
4. streaming 中未闭合代码块、列表、引用块要有稳定 fallback。

验收标准：

- 普通段落、列表、代码块、链接、粗体/斜体、streaming 未闭合 block 渲染稳定。
- 编译通过，SwiftPM resolution 不破坏现有依赖。
- 不新增 Dayflow backend / release 配置。

验证命令：

```bash
rg -n 'MarkdownUI|swift-markdown-ui|NetworkImage|swift-cmark|MARKETING_VERSION|CURRENT_PROJECT_VERSION|DayflowBackendURL|DAYFLOW_BACKEND_URL' \
  Dayflow/Dayflow.xcodeproj/project.pbxproj \
  Dayflow/Dayflow.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved \
  Dayflow/Dayflow/Views/UI/ChatMarkdownRenderer.swift

env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig \
  GIT_ALLOW_PROTOCOL=file:https \
  xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow \
  -configuration Debug \
  -derivedDataPath build/local-derived \
  CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
  build

git diff --check
```

建议提交信息：

```text
feat(chat): render rich markdown replies
```

## 暂缓候选

以下上游提交暂不拆成当前可执行任务。需要维护对应区域时，可回到本节参考。

| 上游提交 | 内容 | 暂缓原因 |
| --- | --- | --- |
| `027f0b89`、`8382eac2`、`35325a80`、`98aab5b2` | Day goal 组件拆分 | 本地已中文化并做 Liquid Glass 迁移，直接移植会产生大量视觉和文案冲突。 |
| `9d550656`、`6069f7b1`、`0ab6c589` | Category / color picker 拆分 | 同上；后续修改 category UI 时局部参考。 |
| `f013e8b1`、`3c77aaa5`、`6f7fd406` | Timeline canvas/grid/slideshow 拆分 | 本地 timeline surface 已迁移，建议按具体 bug/refactor 单独拆。 |
| `7f23d61f`、`b599f733` | Journal layout/editor/components 拆分 | Journal 本地视觉和中文化冲突面大，暂缓。 |
| `e33716e4`、`c37e263c` | Weekly Sankey model/drawing 拆分 | Weekly 本地已有中文化和图表视觉迁移，需单独设计任务。 |
| `56e9af2f`、`686c62aa` | Dayflow Pro onboarding/sign-in/account sheet | 与本地 Pro/Backend 移除方向冲突，禁止合入。 |
| `bba18846`、`a1f64414`、`eb793346`、`861e9ad3` | backend endpoint、release config、version/appcast | 与 fork 发布轨道和 backend 移除方向冲突，禁止整包合入。 |
