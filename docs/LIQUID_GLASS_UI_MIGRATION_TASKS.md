# Dayflow Liquid Glass UI 迁移任务拆分

日期：2026-07-03
适用分支：`codex/liquid-glass-ui-refresh`
目标读者：Codex 执行代理、代码审核者、人工视觉验收者

## 启动提示词模板

复制下面整段作为新会话启动提示词。通常只需要修改第一行的任务编号。

```text
任务编号：LG00

请在 /Users/yuna/ToolsProject-Github/Dayflow-Yuna 仓库、当前分支 codex/liquid-glass-ui-refresh 上执行 docs/LIQUID_GLASS_UI_MIGRATION_TASKS.md 中上述任务编号对应的任务。

执行要求：
1. 开始前读取 CLAUDE.md、docs/LIQUID_GLASS_UI_MIGRATION_TASKS.md、该任务允许范围内的现有文件。
2. 如果文档中找不到上述任务编号，停止并报告，不要猜测任务内容。
3. 如果仓库根目录存在 .codegraph/，先用 CodeGraph 理解目标文件、调用关系和影响面，再做搜索或编辑。
4. 开发前先用中文复述本任务的实现方案、允许修改范围、验证命令；随后按方案执行。若发现任务范围不足以编译或达成验收，先报告需要扩展的文件，不要顺手扩大范围。
5. 只修改本任务允许范围内的文件；不要处理其他任务的残留，不要重构无关代码。
6. macOS 最低版本按 15.1 处理；macOS 15 路径使用 Codex 桌面应用式的中性半透明 material 风格；macOS 26+ 路径使用 Liquid Glass API。macOS 26 API 必须集中在兼容封装或明确的 #available(macOS 26.0, *) 分支内。
7. 只裁掉 bundled 引导 mp4 动画；不要删除或破坏运行时录屏、视频回放、视频处理、转写相关 mp4 链路。
8. 遵守 Apple HIG：Liquid Glass 用于导航、工具栏、popover、sheet、浮动控件等功能层；内容层优先使用 standard material、轻透明 fill、边框和清晰层级，不要全屏玻璃化。
9. 修改后运行本任务列出的验证命令；如果 GUI 或完整 Xcode 验证无法运行，必须说明具体原因和替代验证。
10. 验证通过后按本任务建议提交信息提交本任务范围内的变更；如果工作区有无关改动，不要纳入提交。

交付说明必须包含：
- 修改文件列表
- 实现内容
- 验证结果
- macOS 15 / macOS 26 视觉路径说明
- 未解决问题
- 下一步建议
```

## 总目标

将 Dayflow macOS 应用迁移到统一的现代桌面设计系统：

- 最低支持版本提升为 macOS 15.1。
- macOS 15.1 到 15.7 使用 Codex 桌面应用式的中性半透明工具感：灰白中性、半透明面板、轻边框、克制阴影、内容优先、低饱和状态色。
- macOS 26+ 在同一套语义 surface/token 下大规模使用 Liquid Glass API：导航、工具栏、浮动控件、popover、sheet、重点按钮和相邻 glass 元素使用系统 glass 行为。
- 只移除 bundled 引导 mp4 动画，改为 SwiftUI/Canvas/TimelineView 线条实时动画。
- 移除主窗口图片背景和大面积暖色背景，替换为统一 glass/material surface。
- 迁移全 UI 到统一设计系统，逐步收敛散落的白底、米色底、橙棕色装饰和自定义 chrome。

## 非目标

- 不移除运行时录屏和回放能力。`StorageManager+Chunks`、`VideoProcessingService`、`VideoPlayerModal`、timeline review media 等业务视频链路不是 bundled 引导动画。
- 不引入 iOS/iPadOS 设计模式；本项目是 macOS 菜单栏应用。
- 不把内容阅读区、图表卡片和数据卡片全部 glass 化。
- 不改变 AI provider、录制、分析、存储、Sparkle、Sentry、PostHog 等业务行为。
- 不做品牌重命名。

## 执行原则

1. 每个任务只修改该任务允许范围内的文件。
2. `.codegraph/` 存在时，先用 CodeGraph 理解相关 Swift 文件和调用关系。
3. macOS 26 API 必须由统一封装承载，页面代码不应散落大量 `#available(macOS 26.0, *)`。
4. macOS 15 路径是一等视觉路径，不是简陋 fallback。
5. 使用系统色、vibrancy、standard material 和 semantic token，避免固定低对比颜色。
6. 减少大面积暖色/米色背景，保留橙色只作为 Dayflow 品牌强调或语义状态色。
7. 所有动画必须尊重 `accessibilityReduceMotion`。
8. 需要考虑 Reduce Transparency 和 Increase Contrast；至少不要让文字依赖透明背景才能看清。
9. 不要在内容层滥用 Liquid Glass。功能层和内容层要有明确层级。
10. 每个任务结束必须说明 macOS 15 和 macOS 26 的视觉路径差异。

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

如果任务涉及测试覆盖，使用：

```bash
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig \
  GIT_ALLOW_PROTOCOL=file:https \
  xcodebuild test -project Dayflow/Dayflow.xcodeproj -scheme Dayflow \
  -destination 'platform=macOS' \
  -derivedDataPath build/test-derived
```

提交前建议运行：

```bash
git diff --check
```

若 `/private/tmp/dayflow-gitconfig` 不存在，按 `CLAUDE.md` 的 Build & Test 部分先创建 SQLiteLib 本地 mirror override。

## 任务总览

| 任务编号 | 标题 | 优先级 | 主要目标 |
| --- | --- | --- | --- |
| LG00 | UI 迁移基线清单与视觉验收框架 | P0 | 建立当前 UI surface、视频资源、截图验收清单，不改 Swift UI。 |
| LG01 | 提升最低版本并建立 glass/material 设计系统封装 | P0 | 设置 macOS 15.1 target，新增统一 surface/token/availability 封装。 |
| LG02 | bundled 引导 mp4 替换为线条实时动画 | P0 | 删除 3 个 bundled 引导 mp4 路径，保留回调和 analytics。 |
| LG03 | 主窗口背景与主面板材质迁移 | P0 | 移除 `MainUIBackground` 与米色 overlay，主框架接入统一 surface。 |
| LG04 | 侧边栏、导航和 timeline header 迁移 | P1 | 把主导航和顶部控件迁移到 Codex-like / Liquid Glass 功能层。 |
| LG05 | Timeline 内容、activity card 和 inspector 迁移 | P1 | 迁移时间线核心内容层，保证内容可读且不过度 glass 化。 |
| LG06 | Onboarding 外壳与早期步骤迁移 | P1 | 迁移 intro 后的 role/download/referral/preferences 等早期步骤。 |
| LG07 | Onboarding provider、category、permission 步骤迁移 | P1 | 迁移 LLM setup、category、screen permission、completion。 |
| LG08 | Settings 全面板迁移 | P1 | 迁移设置页 storage/privacy/provider/data 等面板。 |
| LG09 | Chat 面板迁移 | P1 | 迁移 Chat panel、消息、composer、tool/status surfaces。 |
| LG10 | Daily 页面迁移 | P1 | 迁移 Daily lock/unlock、standup、workflow、goal surfaces。 |
| LG11 | Weekly 外壳与 overview 迁移 | P1 | 迁移 Weekly page shell、overview、access locked、主要容器。 |
| LG12 | Weekly 图表和 section card 迁移 | P2 | 迁移 Sankey、Treemap、Heatmap、Workflow、Context chart 等 section。 |
| LG13 | Journal 页面迁移 | P2 | 迁移 Journal hero、day/week、reminder、onboarding entry surfaces。 |
| LG14 | 弹层、popover、modal 与共享控件收口 | P2 | 迁移 category picker、calendar popover、feedback、What's New、视频 modal 外壳。 |
| LG15 | 可访问性、残留扫描与最终文档更新 | P0 | 验证 Reduce Motion/Transparency/Contrast，清理残留背景和旧资源引用。 |
| LG16 | Liquid Glass 封装强化 | P0 | 扩展 surface/button 封装，补齐 shape、interactive、grouping 与 macOS 26 button 入口。 |
| LG17 | 统一按钮体系迁移 | P0 | 迁移 DayflowSurfaceButton/DayflowButton，移除旧白底按钮体系。 |
| LG18 | Popover、modal 与 floating controls 分组收口 | P1 | 让跨页面浮层和相邻控件共享合理 GlassEffectContainer。 |
| LG19 | 主壳残留旧 surface 清理 | P1 | 清理 notice、bug report、timeline review card 等旧白底/暖色 surface。 |
| LG20 | Daily goal flow 迁移收口 | P1 | 将 goal flow overlay、画布、按钮和面板迁到 Daily/Content semantic surface。 |
| LG21 | Settings 与 Chat 控件 OS26 补齐 | P2 | 为 settings/chat 的 composer、provider toggle、control surface 补齐 glass path。 |
| LG22 | Onboarding 控件统一收口 | P2 | 将 onboarding CTA/provider/category/permission 控件统一到新 surface/button 体系。 |
| LG23 | 最终视觉 QA 与文档收口 | P0 | 对 LG16-LG22 后状态做残留扫描、视觉验收清单和文档更新。 |

## LG00：UI 迁移基线清单与视觉验收框架

目标：

- 建立迁移前的 UI surface、背景、视频资源和页面验收清单。
- 明确哪些 mp4 是 bundled 引导动画，哪些是运行时视频链路。
- 为后续任务提供可复用的残留扫描命令和截图检查点。

允许范围：

- `docs/`
- `scripts/`（如需要新增只读扫描脚本）

关键改动：

1. 新增或更新 UI 迁移 inventory，建议文件：`docs/LIQUID_GLASS_UI_MIGRATION_INVENTORY.md`。
2. 记录 bundled 引导 mp4：
   - `Dayflow/Dayflow/Videos/DayflowAnimation.mp4`
   - `Dayflow/Dayflow/Videos/DayflowOnboarding.mp4`
   - `Dayflow/Dayflow/Videos/JournalOnboardingVideo.mp4`
3. 记录禁止误删的运行时视频链路：
   - `Dayflow/Dayflow/Core/Recording/StorageManager+Chunks.swift`
   - `Dayflow/Dayflow/Core/Recording/VideoProcessingService.swift`
   - `Dayflow/Dayflow/Views/UI/VideoPlayerModal.swift`
   - `Dayflow/Dayflow/Views/UI/TimelineReviewMediaViews.swift`
4. 建立截图验收清单：launch、onboarding、timeline、daily、weekly、journal、chat、settings、popover、modal。
5. 建立残留扫描命令，覆盖 hard-coded background、mp4 bundle reference、Liquid Glass availability。

验收标准：

- 文档能指导后续任务判断 scope。
- 清楚区分 bundled 引导动画和运行时视频。
- 后续任务能直接复用截图清单和扫描命令。

验证命令：

```bash
rg -n 'DayflowAnimation|DayflowOnboarding|JournalOnboardingVideo|MainUIBackground|Color\(red: 0\.98|Color\.white|FBF6EF|F7F3F0' Dayflow/Dayflow docs
git diff --check
```

建议提交信息：

```text
docs(ui): add Liquid Glass migration inventory
```

## LG01：提升最低版本并建立 glass/material 设计系统封装

目标：

- 将 app target 最低部署版本提升到 macOS 15.1。
- 建立统一设计系统封装，让页面代码使用语义 surface，而不是直接散写 material/glass/color。
- macOS 15 使用 Codex-like 中性 translucent/material 风格；macOS 26+ 使用 Liquid Glass API。

允许范围：

- `Dayflow/Dayflow.xcodeproj/project.pbxproj`
- `Dayflow/Dayflow/Views/UI/DayflowUIStyles.swift`
- 可新增 `Dayflow/Dayflow/Views/UI/DayflowSurfaceStyles.swift`
- 可新增 `Dayflow/Dayflow/Views/Components/DayflowGlassSurface.swift`
- `Dayflow/DayflowTests/`（仅当新增纯逻辑 token/availability 测试）

关键改动：

1. 将 app target 的 `MACOSX_DEPLOYMENT_TARGET` 从 `14.0` 提升到 `15.1`；测试 target 是否同步提升按编译需要决定。
2. 新增语义 token：
   - window background
   - sidebar surface
   - content panel
   - inspector panel
   - floating control
   - popover surface
   - modal surface
   - separator/border
   - primary/secondary/status accent
3. 新增 view modifier 或 wrapper：
   - `dayflowWindowBackground`
   - `dayflowContentPanel`
   - `dayflowSidebarSurface`
   - `dayflowFloatingControl`
   - `dayflowPopoverSurface`
   - `dayflowModalSurface`
4. macOS 26+ 分支使用 Liquid Glass API，例如 `glassEffect`、`GlassEffectContainer`、glass button style。若 API 名称与当前 SDK 不匹配，停止并报告，不要用自制 blur 假装完成。
5. macOS 15 分支使用 `.regularMaterial` / `.ultraThinMaterial` / neutral translucent fill / system colors。
6. 避免页面业务代码散落 `#available(macOS 26.0, *)`；availability 主要在封装层。

验收标准：

- 工程最低版本为 macOS 15.1。
- 新封装可在 macOS 15 target 下编译。
- 没有无保护的 macOS 26 API 直接散落到业务页面。
- 不改变现有 UI 结构和业务逻辑。

验证命令：

```bash
rg -n 'MACOSX_DEPLOYMENT_TARGET|glassEffect|GlassEffect|DayflowSurface|dayflowContentPanel|dayflowSidebarSurface' \
  Dayflow/Dayflow.xcodeproj/project.pbxproj Dayflow/Dayflow
git diff --check
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig GIT_ALLOW_PROTOCOL=file:https xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -configuration Debug -derivedDataPath build/local-derived CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

建议提交信息：

```text
feat(ui): add macOS glass surface system
```

## LG02：bundled 引导 mp4 替换为线条实时动画

目标：

- 只裁掉 bundled 引导 mp4 动画。
- 用 SwiftUI/Canvas/TimelineView 实现线条实时动画。
- 保留现有完成回调、过渡节奏、analytics 事件和 reduce motion 行为。

允许范围：

- `Dayflow/Dayflow/Views/Onboarding/OnboardingFlow.swift`（仅 intro video 接线和 analytics payload）
- `Dayflow/Dayflow/Views/Onboarding/Prototype/OnboardingPrototypeFlow.swift`（仅 intro video 接线和 analytics payload）
- `Dayflow/Dayflow/Views/Onboarding/VideoLaunchView.swift`
- `Dayflow/Dayflow/Views/Onboarding/Prototype/OnboardingPrototypeVideoIntroStep.swift`
- `Dayflow/Dayflow/Views/UI/JournalView.swift`（仅 `JournalOnboardingVideoView` 相关）
- `Dayflow/Dayflow/App/DayflowApp.swift`（仅 overlay 接线需要时）
- 可新增 `Dayflow/Dayflow/Views/Onboarding/LineAnimation/`
- `Dayflow/Dayflow/Videos/DayflowAnimation.mp4`
- `Dayflow/Dayflow/Videos/DayflowOnboarding.mp4`
- `Dayflow/Dayflow/Videos/JournalOnboardingVideo.mp4`
- `Dayflow/Dayflow.xcodeproj/project.pbxproj`（仅资源引用需要时）
- `Dayflow/Dayflow/AnalyticsEventDictionary.md`（仅 asset 名称说明需要同步时）

禁止范围：

- `Dayflow/Dayflow/Core/Recording/`
- `Dayflow/Dayflow/Views/UI/VideoPlayerModal.swift`
- `Dayflow/Dayflow/Views/UI/TimelineReviewMediaViews.swift`
- 任何用户录屏、视频处理、转写、回放业务逻辑。

关键改动：

1. 将启动视频、onboarding intro 视频、Journal onboarding 视频替换为实时线条动画组件。
2. 动画应是客户端实时绘制，不依赖 mp4/mov/gif。
3. 保留 `onVideoComplete` / `onPlaybackCompleted` / `onComplete` 语义。
4. 更新 `OnboardingFlow` 和 `OnboardingPrototypeFlow` 中的 intro video 接线，不再传递 `DayflowOnboarding` / `DayflowOnboarding.mp4` 这类 bundled asset 名称；如仍需 payload，改为动画语义命名，例如 `dayflow_onboarding_line_animation`。
5. 保留或等价迁移 analytics：
   - `onboarding_video_started` 可以改成 animation started，但 event key 是否改名需谨慎；若改名必须更新事件字典。
   - completed reason 保留 missing/failure 的等价信息或明确不再可能发生。
6. reduce motion 下显示低动效或静态线条，并在短延迟后进入下一步。
7. 删除 bundled mp4 文件和引用。

验收标准：

- 仓库内不再包含 3 个 bundled 引导 mp4。
- 启动、onboarding intro、Journal onboarding 都能自动完成并进入下一步。
- 运行时视频回放和录屏相关代码没有被删除或改坏。
- reduce motion 下不会出现长时间卡住。

验证命令：

```bash
find Dayflow/Dayflow/Videos -iname '*.mp4' -o -iname '*.mov' -o -iname '*.m4v'
rg -n 'DayflowAnimation|DayflowOnboarding|JournalOnboardingVideo|Bundle\.main\.url\(forResource:.*mp4|AVPlayerItem\(url:' \
  Dayflow/Dayflow/Views/Onboarding Dayflow/Dayflow/Views/UI/JournalView.swift Dayflow/Dayflow/App/DayflowApp.swift
git diff --check
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig GIT_ALLOW_PROTOCOL=file:https xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -configuration Debug -derivedDataPath build/local-derived CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

建议提交信息：

```text
feat(onboarding): replace bundled videos with line animations
```

## LG03：主窗口背景与主面板材质迁移

目标：

- 移除主窗口图片背景和米色 overlay。
- 将主窗口、主内容面板和 inspector 外壳接入统一 surface。
- 建立 macOS 15/26 两条视觉路径的主框架基线。

允许范围：

- `Dayflow/Dayflow/App/DayflowApp.swift`
- `Dayflow/Dayflow/Views/UI/MainView/MainView.swift`
- `Dayflow/Dayflow/Views/UI/MainView/Layout+Panels.swift`
- LG01 新增的 surface/style 文件
- `Dayflow/Dayflow/Assets.xcassets/MainUIBackground.imageset/`（仅确认无引用后删除）
- `Dayflow/Dayflow.xcodeproj/project.pbxproj`（仅资源引用需要时）

关键改动：

1. 删除 `MainUIBackground` 和主窗口米色 `Color(red: 0.98, green: 0.96, blue: 0.93)` overlay。
2. 主窗口背景改为统一 `dayflowWindowBackground`。
3. `mainPanelBackground` 改为 `dayflowContentPanel` 或等价封装。
4. timeline inspector 背景改为 semantic inspector surface。
5. 维持当前 layout 尺寸、圆角和导航结构，不在本任务重做页面内部卡片。
6. macOS 15 上呈现 Codex-like 中性半透明工具面板；macOS 26+ 使用 Liquid Glass surface。

验收标准：

- 主窗口不再依赖 `MainUIBackground`。
- 主面板没有纯白硬底作为唯一视觉基础。
- timeline/sidebar/content 层级清楚，文字仍可读。
- 不影响 onboarding/video overlay 出现顺序。

验证命令：

```bash
rg -n 'MainUIBackground|Color\(red: 0\.98, green: 0\.96, blue: 0\.93\)|mainPanelBackground|timelineInspectorWidth' \
  Dayflow/Dayflow/App/DayflowApp.swift Dayflow/Dayflow/Views/UI/MainView
git diff --check
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig GIT_ALLOW_PROTOCOL=file:https xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -configuration Debug -derivedDataPath build/local-derived CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

建议提交信息：

```text
feat(ui): migrate main window shell surfaces
```

## LG04：侧边栏、导航和 timeline header 迁移

目标：

- 将主导航、sidebar、timeline header、模式切换和浮动导航控件迁移到统一功能层 surface。
- macOS 26+ 使用 Liquid Glass 的功能层体验；macOS 15 使用中性半透明控件。

允许范围：

- `Dayflow/Dayflow/Views/UI/MainView/SidebarView.swift`
- `Dayflow/Dayflow/Views/UI/MainView/Layout+TimelineHeader.swift`
- `Dayflow/Dayflow/Views/UI/MainView/Layout+Panels.swift`（仅与 header/sidebar surface 接线相关）
- `Dayflow/Dayflow/Views/UI/SunriseGlassPillToggleStyle.swift`
- `Dayflow/Dayflow/Views/Components/DayflowButton.swift`
- LG01 新增的 surface/style 文件

关键改动：

1. Sidebar icon group 使用统一 sidebar/floating control surface。
2. timeline 日期导航、day/week toggle、copy/review/scroll-to-now 等功能控件接入统一 button/surface style。
3. macOS 26+ 相邻 glass controls 需要共享合理的 `GlassEffectContainer`。
4. icon tint 只表达状态和语义，不为装饰随意上色。
5. 控件尺寸稳定，不因 hover/press 造成布局跳动。

验收标准：

- Sidebar 和 header 视觉上属于功能层，和 timeline 内容层区分清楚。
- macOS 15 上半透明控件仍有足够对比度。
- macOS 26+ 不散落多个彼此冲突的 glass container。

验证命令：

```bash
rg -n 'SidebarView|SunriseGlassPillToggleStyle|dayflowFloatingControl|GlassEffectContainer|Color\.white|Color\(hex:' \
  Dayflow/Dayflow/Views/UI/MainView Dayflow/Dayflow/Views/UI/SunriseGlassPillToggleStyle.swift Dayflow/Dayflow/Views/Components/DayflowButton.swift
git diff --check
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig GIT_ALLOW_PROTOCOL=file:https xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -configuration Debug -derivedDataPath build/local-derived CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

建议提交信息：

```text
feat(ui): refresh navigation glass surfaces
```

## LG05：Timeline 内容、activity card 和 inspector 迁移

目标：

- 迁移 timeline 内容层、activity card、day/week grid、inspector、review prompt。
- 保持内容层可读，不把所有数据卡片变成 Liquid Glass。

允许范围：

- `Dayflow/Dayflow/Views/UI/CanvasTimelineDataView.swift`
- `Dayflow/Dayflow/Views/UI/MainView/WeekTimelineGridView.swift`
- `Dayflow/Dayflow/Views/UI/MainView/ActivityCard.swift`
- `Dayflow/Dayflow/Views/UI/MainView/ScreenshotSlideshow.swift`
- `Dayflow/Dayflow/Views/UI/MainView/Layout+Panels.swift`
- `Dayflow/Dayflow/Views/Components/DaySummaryView.swift`
- `Dayflow/Dayflow/Views/Components/CardsToReviewBadge.swift`
- `Dayflow/Dayflow/Views/Components/TimelineReviewSummaryCard.swift`
- LG01 新增的 surface/style 文件

关键改动：

1. Activity card 使用 content-layer standard material 或 semantic card fill。
2. Inspector 使用 inspector surface，弱化硬白底。
3. Screenshot slideshow 保留媒体可读性，不用 clear glass 影响图片判断。
4. Review prompt 和浮动操作可使用功能层 glass/floating surface。
5. 保留 category color 语义，降低背景暖色主导感。

验收标准：

- Timeline day/week 在空态、普通卡片、选中 activity、inspector 展开时都可读。
- 卡片层级清楚，hover/press 不跳动。
- 不影响 activity selection、review、screenshot preview 交互。

验证命令：

```bash
rg -n 'Color\.white|Color\(red: 0\.98|Color\(hex: "FAF3EB"|backgroundColor|dayflowContentPanel|dayflowCard' \
  Dayflow/Dayflow/Views/UI/CanvasTimelineDataView.swift \
  Dayflow/Dayflow/Views/UI/MainView \
  Dayflow/Dayflow/Views/Components/DaySummaryView.swift \
  Dayflow/Dayflow/Views/Components/CardsToReviewBadge.swift \
  Dayflow/Dayflow/Views/Components/TimelineReviewSummaryCard.swift
git diff --check
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig GIT_ALLOW_PROTOCOL=file:https xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -configuration Debug -derivedDataPath build/local-derived CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

建议提交信息：

```text
feat(timeline): migrate timeline content surfaces
```

## LG06：Onboarding 外壳与早期步骤迁移

目标：

- 迁移 onboarding intro 之后的早期步骤到统一 Codex-like / Liquid Glass 设计系统。
- 保留 onboarding 流程、analytics、UserDefaults、步骤迁移逻辑。

允许范围：

- `Dayflow/Dayflow/Views/Onboarding/OnboardingFlow.swift`
- `Dayflow/Dayflow/Views/Onboarding/SetupSidebarView.swift`
- `Dayflow/Dayflow/Views/Onboarding/SetupContinueButton.swift`
- `Dayflow/Dayflow/Views/Onboarding/Prototype/OnboardingPrototypeRoleSelectionStep.swift`
- `Dayflow/Dayflow/Views/Onboarding/Prototype/OnboardingPrototypeDownloadReasonStep.swift`
- `Dayflow/Dayflow/Views/Onboarding/Prototype/OnboardingPrototypeReferralStep.swift`
- `Dayflow/Dayflow/Views/Onboarding/Prototype/OnboardingPrototypePreferencesStep.swift`
- `Dayflow/Dayflow/Views/Onboarding/HowItWorksView.swift`
- LG01 新增的 surface/style 文件

关键改动：

1. 替换 onboarding 全局图片/暖色背景为 semantic onboarding/window surface。
2. Early-step option card 使用 content material，不用大面积米色/橙棕装饰。
3. Sidebar/progress 使用功能层 surface。
4. 继续/返回按钮接入统一 button style。
5. 保留文案和业务选择语义，不重写 onboarding 数据结构。

验收标准：

- role、download reason、referral、preferences 步骤布局稳定。
- 15 路径有中性半透明工具感；26 路径功能控件使用 Liquid Glass。
- 不改变 onboarding step 存储和推进逻辑。

验证命令：

```bash
rg -n 'OnboardingBackground|OnboardingBackgroundv2|Color\(hex: "492304"|Color\(hex: "89380E"|Color\.white|background\(' \
  Dayflow/Dayflow/Views/Onboarding
git diff --check
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig GIT_ALLOW_PROTOCOL=file:https xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -configuration Debug -derivedDataPath build/local-derived CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

建议提交信息：

```text
feat(onboarding): refresh early onboarding surfaces
```

## LG07：Onboarding provider、category、permission 步骤迁移

目标：

- 迁移 provider setup、API key、CLI detection、category、color、screen recording permission、completion 等后半段 onboarding。
- 保持输入框、检测状态、权限提示和 category 编辑体验可用。

允许范围：

- `Dayflow/Dayflow/Views/Onboarding/OnboardingLLMSelectionView.swift`
- `Dayflow/Dayflow/Views/Onboarding/LLMProviderSetupView.swift`
- `Dayflow/Dayflow/Views/Onboarding/APIKeyInputView.swift`
- `Dayflow/Dayflow/Views/Onboarding/ChatCLIDetectionViews.swift`
- `Dayflow/Dayflow/Views/Onboarding/LocalLLMTestView.swift`
- `Dayflow/Dayflow/Views/Onboarding/OnboardingCategoryStepView.swift`
- `Dayflow/Dayflow/Views/Onboarding/ScreenRecordingPermissionView.swift`
- `Dayflow/Dayflow/Views/Onboarding/TerminalCommandView.swift`
- `Dayflow/Dayflow/Views/Components/ProviderCardComponents.swift`
- `Dayflow/Dayflow/Views/Components/TimelineCardColorPicker.swift`（仅 onboarding presentation 相关）
- LG01 新增的 surface/style 文件

关键改动：

1. Provider card、API key field、CLI status card、category card 统一 content/control surface。
2. 输入框和命令块在 material 背景上保持可读。
3. Screen recording permission 的系统设置引导保持高对比和清晰层级。
4. Category color picker 保留颜色操作语义，不把色彩 token 化到不可辨认。
5. Completion 页面接入统一窗口和 action style。

验收标准：

- 所有后半段 onboarding 步骤可推进。
- API key 和 CLI detection 状态清晰。
- Category 编辑、删除、颜色选择交互不退化。

验证命令：

```bash
rg -n 'Color\.white|Color\(hex: "402B00"|Color\(hex: "492304"|Color\(hex: "FFF|Color\(red: 0\.98|OnboardingBackground' \
  Dayflow/Dayflow/Views/Onboarding Dayflow/Dayflow/Views/Components/ProviderCardComponents.swift Dayflow/Dayflow/Views/Components/TimelineCardColorPicker.swift
git diff --check
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig GIT_ALLOW_PROTOCOL=file:https xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -configuration Debug -derivedDataPath build/local-derived CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

建议提交信息：

```text
feat(onboarding): refresh setup and permission surfaces
```

## LG08：Settings 全面板迁移

目标：

- 迁移 Settings 的 tab、section、provider card、storage/privacy/data surfaces。
- Settings 要更接近 Codex 桌面工具设置感：紧凑、清晰、中性、可扫描。

允许范围：

- `Dayflow/Dayflow/Views/UI/SettingsView.swift`
- `Dayflow/Dayflow/Views/UI/Settings/`
- `Dayflow/Dayflow/Views/Components/ProviderCardComponents.swift`
- `Dayflow/Dayflow/Views/Components/DayflowButton.swift`
- LG01 新增的 surface/style 文件

关键改动：

1. Settings shell 使用 semantic content panel。
2. Sidebar/tab selection 使用功能层 surface 或 standard list treatment。
3. Provider cards、privacy/storage/data rows 收敛到统一 card/list token。
4. 移除大面积硬白和暖色说明底。
5. 保留所有 provider routing、keychain、privacy、storage 操作逻辑。

验收标准：

- Settings 各 tab 可进入，按钮/开关/菜单可辨认。
- Provider 状态、错误、primary/backup 语义清楚。
- macOS 15 和 26 路径都不依赖硬编码白底。

验证命令：

```bash
rg -n 'Color\.white|Color\(red: 0\.98|Color\(hex: "FFF|Color\(hex: "F7|Color\(hex: "FAF|background\(' \
  Dayflow/Dayflow/Views/UI/Settings Dayflow/Dayflow/Views/UI/SettingsView.swift
git diff --check
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig GIT_ALLOW_PROTOCOL=file:https xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -configuration Debug -derivedDataPath build/local-derived CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

建议提交信息：

```text
feat(settings): migrate settings material surfaces
```

## LG09：Chat 面板迁移

目标：

- 迁移 Chat panel、message bubbles、composer、tool/status bubbles、welcome cards。
- 呈现 Codex-like 工具对话感：中性、清晰、输入框稳、消息可读。

允许范围：

- `Dayflow/Dayflow/Views/UI/ChatView+Content.swift`
- `Dayflow/Dayflow/Views/UI/ChatMessageViews.swift`
- `Dayflow/Dayflow/Views/UI/ChatComposerTextField.swift`
- `Dayflow/Dayflow/Views/UI/ChatMarkdownRenderer.swift`
- `Dayflow/Dayflow/Views/UI/ChatStylesAndDebug.swift`
- `Dayflow/Dayflow/Views/UI/ChatWelcomeComponents.swift`
- `Dayflow/Dayflow/Views/UI/ChatWorkStatusViews.swift`
- `Dayflow/Dayflow/Views/Components/ToolCallBubble.swift`
- LG01 新增的 surface/style 文件

关键改动：

1. Chat container 接入 content panel。
2. Composer 使用 translucent input surface，保证 focus ring/placeholder 可见。
3. User/assistant/tool/status bubble 使用中性层级，不靠米色背景区分。
4. Markdown code block 保持高对比。
5. macOS 26+ 可对 composer/floating tools 使用 Liquid Glass，消息内容层保持 standard material。

验收标准：

- 长消息、代码块、tool call、空态、输入焦点均可读。
- Composer 不因透明背景丢失边界。
- Debug/status 面板不破坏主视觉。

验证命令：

```bash
rg -n 'Color\.white|Color\(hex: "FAF|Color\(hex: "FFF8|backgroundColor|ToolCallBubble|Composer' \
  Dayflow/Dayflow/Views/UI/Chat* Dayflow/Dayflow/Views/Components/ToolCallBubble.swift
git diff --check
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig GIT_ALLOW_PROTOCOL=file:https xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -configuration Debug -derivedDataPath build/local-derived CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

建议提交信息：

```text
feat(chat): migrate chat material surfaces
```

## LG10：Daily 页面迁移

目标：

- 迁移 Daily lock/unlock、standup、workflow、goal prompt、provider picker surfaces。
- 让 Daily 更像工具面板而不是暖色 landing page。

允许范围：

- `Dayflow/Dayflow/Views/UI/DailyView.swift`
- `Dayflow/Dayflow/Views/UI/DailyView+Provider.swift`
- `Dayflow/Dayflow/Views/UI/DailyView+Standup.swift`
- `Dayflow/Dayflow/Views/UI/DailyView+Workflow.swift`
- `Dayflow/Dayflow/Views/UI/DailyWorkflowGrid.swift`
- `Dayflow/Dayflow/Views/UI/DailyAccessLockedViews.swift`
- `Dayflow/Dayflow/Views/UI/DailyStandupComponents.swift`
- `Dayflow/Dayflow/Views/Components/DayGoalFlowView.swift`
- `Dayflow/Dayflow/Views/Components/DayGoalHeader.swift`
- `Dayflow/Dayflow/Views/Components/DayFocusSummarySection.swift`
- `Dayflow/Dayflow/Views/Components/DayCategorySelectionEditor.swift`
- `Dayflow/Dayflow/Views/Components/CategoryPickerView.swift`
- `Dayflow/Dayflow/Views/Components/CategoryPickerOverlay.swift`
- LG01 新增的 surface/style 文件

关键改动：

1. Daily root 和 card surfaces 接入 semantic panel/card token。
2. Lock screen 权限/进度控件保持清晰功能层。
3. Standup editor、copy/regenerate controls 使用统一 input/control surface。
4. Daily provider button 和 provider picker 使用统一 floating/popover surface，保留 provider availability、selection、disabled 状态语义。
5. Workflow grid 的 cell、active state、tooltip/hover 相关 surface 接入统一 content/card token，保留 focus/distraction/status 语义色。
6. Goal flow overlay 需要保留足够视觉重点，但降低大面积暖色背景。
7. Category picker 作为 popover/overlay 应与 LG14 风格兼容。

验收标准：

- Locked 和 unlocked Daily 都可读。
- Standup 文本区、workflow grid、goal flow 操作不退化。
- Provider picker 和 category picker 浮层层级清楚。

验证命令：

```bash
rg -n 'Color\.white|Color\(hex: "F7|Color\(hex: "FFF|Color\(red: 0\.98|backgroundTop|backgroundBottom|backgroundColor' \
  Dayflow/Dayflow/Views/UI/Daily* Dayflow/Dayflow/Views/Components/Day* Dayflow/Dayflow/Views/Components/CategoryPicker*
git diff --check
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig GIT_ALLOW_PROTOCOL=file:https xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -configuration Debug -derivedDataPath build/local-derived CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

说明：上述 `rg` 是残留审查命令，不是机械的零输出断言。允许范围内的命中应迁移到语义 surface/token，或在交付说明中逐项解释为什么保留为语义文字、状态色、分隔线或高对比辅助色；允许范围外出现会影响 LG10 验收的旧 surface 命中时，应停止并报告范围缺口。

建议提交信息：

```text
feat(daily): migrate daily material surfaces
```

## LG11：Weekly 外壳与 overview 迁移

目标：

- 迁移 Weekly root、access locked、overview、highlights 等主要外壳。
- 先建立 Weekly 的整体中性 material 基调，再由 LG12 处理具体图表 section。

允许范围：

- `Dayflow/Dayflow/Views/UI/Weekly/WeeklyView.swift`
- `Dayflow/Dayflow/Views/UI/Weekly/WeeklyAccessLockedView.swift`
- `Dayflow/Dayflow/Views/UI/Weekly/Sections/WeeklyOverviewSection.swift`
- `Dayflow/Dayflow/Views/UI/Weekly/Sections/WeeklyHighlightsSection.swift`
- `Dayflow/Dayflow/Views/UI/Weekly/Sections/WeeklySuggestionsSection.swift`
- LG01 新增的 surface/style 文件

关键改动：

1. Weekly root 不再使用大面积 `FBF6EF` 暖色背景。
2. Overview/highlight/suggestion section card 使用统一 section/card token。
3. Access locked 的 visual hero 降低装饰性，保留清晰解锁行动。
4. 保持图表配色语义，不在本任务重写 chart internals。

验收标准：

- Weekly 页面整体背景、顶部、overview section 进入新设计系统。
- 仍能清楚区分 focus/distraction/context 等语义色。
- 不破坏 Weekly data loading 和 copy/export 行为。

验证命令：

```bash
rg -n 'FBF6EF|F7F3F0|Color\.white|Color\(hex: "FAF|Color\(red: 0\.98|background' \
  Dayflow/Dayflow/Views/UI/Weekly/WeeklyView.swift \
  Dayflow/Dayflow/Views/UI/Weekly/WeeklyAccessLockedView.swift \
  Dayflow/Dayflow/Views/UI/Weekly/Sections/WeeklyOverviewSection.swift \
  Dayflow/Dayflow/Views/UI/Weekly/Sections/WeeklyHighlightsSection.swift \
  Dayflow/Dayflow/Views/UI/Weekly/Sections/WeeklySuggestionsSection.swift
git diff --check
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig GIT_ALLOW_PROTOCOL=file:https xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -configuration Debug -derivedDataPath build/local-derived CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

建议提交信息：

```text
feat(weekly): migrate weekly shell surfaces
```

## LG12：Weekly 图表和 section card 迁移

目标：

- 迁移 Weekly 的图表 section、section card、legend、footer、preview 背景。
- 图表内部色彩保留数据语义，但容器收敛到统一设计系统。

允许范围：

- `Dayflow/Dayflow/Views/UI/Weekly/Sections/`
- `Dayflow/Dayflow/Views/UI/Weekly/WeeklyView.swift`（仅 section 接线需要时）
- `Dayflow/Dayflow/Views/Components/CategoryDonutChart.swift`
- `Dayflow/Dayflow/Views/Components/LongestFocusCard.swift`
- LG01 新增的 surface/style 文件

关键改动：

1. Sankey、Treemap、Heatmap、Workflow、Context chart、Application interactions 等 section 的外壳使用统一 section surface。
2. Legend、chip、tooltip、empty/loading/error states 使用统一 token。
3. 图表绘制区域可以保留 neutral content background，但避免暖色页面底。
4. 保持 chart 可读性优先，不为了 glass 牺牲数据辨识。

验收标准：

- Weekly section 背景和边界一致。
- 图表在 light/dark system appearance 和透明窗口下仍可读。
- 不改变 Weekly builder/data model。

验证命令：

```bash
rg -n 'FBF6EF|F7F3F0|FAF7F5|Color\.white|Color\(red: 0\.98|backgroundColor|static let background' \
  Dayflow/Dayflow/Views/UI/Weekly/Sections Dayflow/Dayflow/Views/Components/CategoryDonutChart.swift Dayflow/Dayflow/Views/Components/LongestFocusCard.swift
git diff --check
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig GIT_ALLOW_PROTOCOL=file:https xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -configuration Debug -derivedDataPath build/local-derived CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

建议提交信息：

```text
feat(weekly): migrate weekly chart surfaces
```

## LG13：Journal 页面迁移

目标：

- 迁移 Journal hero、day view、weekly view、reminders、onboarding entry。
- 替换 Journal 中残留暖色和硬白卡片，保留日志阅读舒适度。

允许范围：

- `Dayflow/Dayflow/Views/UI/JournalView.swift`
- `Dayflow/Dayflow/Views/UI/JournalHeroView.swift`
- `Dayflow/Dayflow/Views/UI/JournalDayView.swift`
- `Dayflow/Dayflow/Views/UI/JournalWeeklyView.swift`
- `Dayflow/Dayflow/Views/UI/JournalReminders.swift`
- LG01 新增的 surface/style 文件

关键改动：

1. Journal root 和 hero 使用统一 panel/background token。
2. Day entry cards 使用 content material，保证长文本阅读对比。
3. Weekly journal surfaces 与 Weekly 页面基调一致。
4. Reminder controls 使用 floating/control surface。
5. 不改 Journal 数据加载、提醒调度和文本生成逻辑。

验收标准：

- Journal onboarding entry、day、week、reminder 都可读。
- 长文本和 wet ink/typewriter 效果在 material 背景上不糊。
- 没有残留 Journal bundled mp4 依赖。

验证命令：

```bash
rg -n 'JournalOnboardingVideo|Color\.white|FFF2DB|Color\(red: 1\.0, green: 0\.93|background|thickMaterial' \
  Dayflow/Dayflow/Views/UI/Journal*
git diff --check
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig GIT_ALLOW_PROTOCOL=file:https xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -configuration Debug -derivedDataPath build/local-derived CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

建议提交信息：

```text
feat(journal): migrate journal material surfaces
```

## LG14：弹层、popover、modal 与共享控件收口

目标：

- 迁移跨页面浮层和共享控件，避免主页面已迁移但弹层仍是旧白底/暖色底。
- macOS 26+ 对 popover/sheet/floating control 使用 Liquid Glass；macOS 15 使用稳定 material。

允许范围：

- `Dayflow/Dayflow/Views/UI/MainView/TimelineCalendarPopover.swift`
- `Dayflow/Dayflow/Views/UI/TimelineFeedbackModal.swift`
- `Dayflow/Dayflow/Views/UI/TimelineReviewOverlay.swift`
- `Dayflow/Dayflow/Views/UI/VideoPlayerModal.swift`（仅 modal chrome/scrubber/header 背景，不改播放器业务）
- `Dayflow/Dayflow/Views/UI/WhatsNewView.swift`
- `Dayflow/Dayflow/Views/Components/TimelineCardColorPicker.swift`
- `Dayflow/Dayflow/Views/Components/CategoryPickerView.swift`
- `Dayflow/Dayflow/Views/Components/CategoryPickerOverlay.swift`
- `Dayflow/Dayflow/Views/Components/PausePillView.swift`
- `Dayflow/Dayflow/Menu/StatusMenuView.swift`
- LG01 新增的 surface/style 文件

关键改动：

1. Calendar popover、feedback modal、timeline review overlay、What's New sheet 统一 modal/popover surface。
2. Video modal 只迁移 header/scrubber/chrome 背景；不删除 `WhiteBGVideoPlayer`，不改播放逻辑。
3. Pause pill、category picker、color picker 使用 floating/control surface。
4. Sheet backdrop 避免旧式黑色重遮罩压住系统 material；必要时保留轻 dimming layer 保证可读。
5. Status menu 保持 macOS 菜单栏上下文里的标准 material。

验收标准：

- 所有常见浮层视觉上属于同一设计系统。
- Video player 仍可播放用户录屏，scrubber 可拖动。
- macOS 26 glass grouping 不分散。

验证命令：

```bash
rg -n 'Color\.white|Color\.black\.opacity\(0\.4\)|Color\(hex: "FAF|Color\(hex: "FFF|background\(|WhiteBGVideoPlayer' \
  Dayflow/Dayflow/Views/UI/MainView/TimelineCalendarPopover.swift \
  Dayflow/Dayflow/Views/UI/TimelineFeedbackModal.swift \
  Dayflow/Dayflow/Views/UI/TimelineReviewOverlay.swift \
  Dayflow/Dayflow/Views/UI/VideoPlayerModal.swift \
  Dayflow/Dayflow/Views/UI/WhatsNewView.swift \
  Dayflow/Dayflow/Views/Components/TimelineCardColorPicker.swift \
  Dayflow/Dayflow/Views/Components/CategoryPicker* \
  Dayflow/Dayflow/Views/Components/PausePillView.swift \
  Dayflow/Dayflow/Menu/StatusMenuView.swift
git diff --check
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig GIT_ALLOW_PROTOCOL=file:https xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -configuration Debug -derivedDataPath build/local-derived CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

建议提交信息：

```text
feat(ui): unify modal and popover surfaces
```

## LG15：可访问性、残留扫描与最终文档更新

目标：

- 验证并修复全迁移后的可访问性、残留背景、旧资源引用、Liquid Glass availability 问题。
- 更新迁移 inventory 和最终状态说明。

允许范围：

- `Dayflow/Dayflow/`（仅修复本任务扫描发现的 UI surface/accessibility 残留）
- `Dayflow/Dayflow.xcodeproj/project.pbxproj`（仅清理确认无引用资源）
- `docs/`
- `scripts/`

关键改动：

1. 扫描并清理无意残留的主背景、旧 bundled mp4 引用、大面积暖色背景。
2. 检查所有 macOS 26 API 都有 availability 保护或位于封装层。
3. 增补 reduce motion、reduce transparency、increase contrast 的 UI 处理。
4. 更新 `docs/LIQUID_GLASS_UI_MIGRATION_INVENTORY.md`：已迁移、保留原因、未解决问题。
5. 若需要，新增或更新只读扫描脚本，帮助后续防回归。

验收标准：

- 无 bundled 引导 mp4 资源和引用。
- app target 最低版本是 15.1。
- `glassEffect` 等 macOS 26 API 不在未保护路径中。
- 主要页面在 macOS 15 material path 和 macOS 26 Liquid Glass path 都有说明。
- 文档记录剩余硬编码背景的保留理由，不能留下无法解释的散点。

验证命令：

```bash
find Dayflow/Dayflow -iname '*.mp4' -o -iname '*.mov' -o -iname '*.m4v'
rg -n 'DayflowAnimation|DayflowOnboarding|JournalOnboardingVideo|MainUIBackground' Dayflow/Dayflow Dayflow/Dayflow.xcodeproj docs
rg -n 'glassEffect|GlassEffect|GlassButtonStyle|GlassProminentButtonStyle|backgroundExtensionEffect' Dayflow/Dayflow
rg -n 'Color\(red: 0\.98|FBF6EF|F7F3F0|FAF3EB|Color\.white\)|background\(Color\.white' Dayflow/Dayflow
rg -n 'MACOSX_DEPLOYMENT_TARGET = ' Dayflow/Dayflow.xcodeproj/project.pbxproj
git diff --check
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig GIT_ALLOW_PROTOCOL=file:https xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -configuration Debug -derivedDataPath build/local-derived CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

建议提交信息：

```text
chore(ui): finalize glass migration cleanup
```

## LG16：Liquid Glass 封装强化

目标：

- 强化 Dayflow 的 macOS 26 glass 封装，让 surface 支持明确 shape、interactive、grouping，而不只是默认 `content.glassEffect()`。
- 为后续按钮、popover、modal 迁移提供统一入口。

允许范围：

- `Dayflow/Dayflow/Views/UI/DayflowSurfaceStyles.swift`
- `Dayflow/Dayflow/Views/Components/DayflowGlassSurface.swift`
- 可新增 `Dayflow/Dayflow/Views/Components/DayflowGlassButtonStyle.swift` 或同级小型封装文件
- `docs/LIQUID_GLASS_UI_MIGRATION_INVENTORY.md`（仅记录本任务新增封装）

关键改动：

1. macOS 26 API 必须集中在封装层。
2. `floatingControl`、`popoverSurface`、`modalSurface`、`sidebarSurface` 的行为支持 shape / interactive。
3. 增加明确的 button style 入口，供后续 `DayflowSurfaceButton` 迁移复用。
4. 不把 `contentPanel`、card、chart 等内容层全部 glass 化。

验收标准：

- `glassEffect`、`GlassEffectContainer`、button glass 入口都集中在封装层。
- macOS 15 fallback 仍是中性 material/control surface。
- 页面业务代码不新增散落 `#available(macOS 26.0, *)`。

验证命令：

```bash
rg -n 'glassEffect|GlassEffectContainer|GlassButtonStyle|GlassProminentButtonStyle|interactive|#available\(macOS 26' \
  Dayflow/Dayflow/Views/UI/DayflowSurfaceStyles.swift Dayflow/Dayflow/Views/Components
git diff --check
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig GIT_ALLOW_PROTOCOL=file:https xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -configuration Debug -derivedDataPath build/local-derived CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

建议提交信息：

```text
feat(ui): strengthen liquid glass surface wrappers
```

## LG17：统一按钮体系迁移

目标：

- 迁移 `DayflowSurfaceButton`，移除默认硬白/硬黑旧按钮体系。
- macOS 26+ 优先走系统 glass / glass-prominent 或 LG16 新封装；macOS 15 保持中性 material/control surface。

允许范围：

- `Dayflow/Dayflow/Views/Components/DayflowSurfaceButton.swift`
- `Dayflow/Dayflow/Views/Components/DayflowButton.swift`
- `Dayflow/Dayflow/Views/UI/DayflowUIStyles.swift`
- LG16 新增/修改的 button/surface 封装文件

关键改动：

1. 保持现有 call site API 尽量兼容，避免一次性改几十个页面。
2. primary、secondary、destructive、disabled 状态使用语义枚举或 token，而不是传 `Color.white`。
3. `DayflowSurfaceButton` 不再默认白底黑字。
4. Reduce Motion 仍生效。

验收标准：

- `DayflowSurfaceButton` 没有默认 `Color.white` / `Color.black` 旧 surface。
- 常见调用点无需大规模改动即可得到新视觉。
- macOS 26 button path 不绕开 Liquid Glass 封装。

验证命令：

```bash
rg -n 'var background: Color = \.white|Color\.white|Color\.black|background: Color\.white|DayflowSurfaceButton\(' \
  Dayflow/Dayflow/Views/Components/DayflowSurfaceButton.swift \
  Dayflow/Dayflow/Views/Components/DayflowButton.swift \
  Dayflow/Dayflow/Views/UI/DayflowUIStyles.swift \
  Dayflow/Dayflow/Views
git diff --check
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig GIT_ALLOW_PROTOCOL=file:https xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -configuration Debug -derivedDataPath build/local-derived CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

建议提交信息：

```text
feat(ui): migrate shared buttons to glass surfaces
```

## LG18：Popover、modal 与 floating controls 分组收口

目标：

- 让相邻 popover、modal、floating controls 在 macOS 26+ 共享合理 `GlassEffectContainer`。
- 修复 LG14 后仍然“单个 `glassEffect` 分散”的问题。

允许范围：

- `Dayflow/Dayflow/Views/UI/MainView/TimelineCalendarPopover.swift`
- `Dayflow/Dayflow/Views/UI/TimelineFeedbackModal.swift`
- `Dayflow/Dayflow/Views/UI/TimelineReviewOverlay.swift`
- `Dayflow/Dayflow/Views/UI/VideoPlayerModal.swift`（只改 chrome，不改播放器业务）
- `Dayflow/Dayflow/Views/UI/WhatsNewView.swift`
- `Dayflow/Dayflow/Views/Components/CategoryPickerView.swift`
- `Dayflow/Dayflow/Views/Components/CategoryPickerOverlay.swift`
- `Dayflow/Dayflow/Views/Components/TimelineCardColorPicker.swift`
- `Dayflow/Dayflow/Views/Components/PausePillView.swift`
- LG16 surface 封装文件

关键改动：

1. 统一 popover/modal/floating groups 的 glass container 边界。
2. 保留轻 dimming layer，但避免厚黑遮罩压住系统 material。
3. 不删除 `WhiteBGVideoPlayer`，不破坏 runtime 视频播放和 scrubber 拖动。

验收标准：

- 常见浮层属于同一套 glass grouping。
- 视频 modal 仍可播放用户录屏，scrubber 可拖动。
- `GlassEffectContainer` 的使用不只停留在 sidebar/header。

验证命令：

```bash
rg -n 'GlassEffectContainer|dayflowPopoverSurface|dayflowModalSurface|dayflowFloatingControl|Color\.black\.opacity\(0\.4\)|WhiteBGVideoPlayer' \
  Dayflow/Dayflow/Views/UI/MainView/TimelineCalendarPopover.swift \
  Dayflow/Dayflow/Views/UI/TimelineFeedbackModal.swift \
  Dayflow/Dayflow/Views/UI/TimelineReviewOverlay.swift \
  Dayflow/Dayflow/Views/UI/VideoPlayerModal.swift \
  Dayflow/Dayflow/Views/UI/WhatsNewView.swift \
  Dayflow/Dayflow/Views/Components/CategoryPicker* \
  Dayflow/Dayflow/Views/Components/TimelineCardColorPicker.swift \
  Dayflow/Dayflow/Views/Components/PausePillView.swift
git diff --check
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig GIT_ALLOW_PROTOCOL=file:https xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -configuration Debug -derivedDataPath build/local-derived CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

建议提交信息：

```text
feat(ui): group glass popovers and floating controls
```

## LG19：主壳残留旧 surface 清理

目标：

- 清理主窗口 notice/toast、BugReport、TimelineReviewCard 中明显不符合中性 glass/material 的旧白底/暖色 surface。

允许范围：

- `Dayflow/Dayflow/Views/UI/MainView/Layout.swift`
- `Dayflow/Dayflow/Views/UI/BugReportView.swift`
- `Dayflow/Dayflow/Views/UI/TimelineReviewCard.swift`
- `Dayflow/Dayflow/Views/UI/TimelineReviewChrome.swift`（仅 icon/content contrast 必要处）
- `Dayflow/Dayflow/Views/Components/DistractionSummaryCard.swift`（仅非 preview shipping surface；preview 可说明保留）
- LG16/LG17 surface/button 封装文件（仅必要调用）

关键改动：

1. `Layout.swift` 权限 notice 不再使用 `FFF8F2` 暖色旧卡。
2. `BugReportView` 不再使用硬白按钮堆。
3. `TimelineReviewCard` 卡片 chrome 接入语义 card/content surface。
4. 媒体/截图/视频内容层的白色可保留，但 UI 卡片背景不应是旧硬白或 `FFF8F2`。

验收标准：

- 主壳残留不再像旧 landing/warm surface。
- 媒体内容对比度保持可读。
- 不改 timeline review 播放/评分业务逻辑。

验证命令：

```bash
rg -n 'Color\(hex: "FFF8F2"|Color\(hex: "F3D9C2"|background: Color\.white|\.fill\(Color\.white\)|DayflowSurfaceButton\(' \
  Dayflow/Dayflow/Views/UI/MainView/Layout.swift \
  Dayflow/Dayflow/Views/UI/BugReportView.swift \
  Dayflow/Dayflow/Views/UI/TimelineReviewCard.swift \
  Dayflow/Dayflow/Views/UI/TimelineReviewChrome.swift \
  Dayflow/Dayflow/Views/Components/DistractionSummaryCard.swift
git diff --check
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig GIT_ALLOW_PROTOCOL=file:https xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -configuration Debug -derivedDataPath build/local-derived CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

建议提交信息：

```text
fix(ui): remove legacy shell surfaces
```

## LG20：Daily goal flow 迁移收口

目标：

- 将 DayGoalFlow 的 overlay、主画布、按钮、category pool、setup panels 从固定 Figma 色块迁移到 Daily/Content semantic surface。

允许范围：

- `Dayflow/Dayflow/Views/Components/DayGoalFlowView.swift`
- `Dayflow/Dayflow/Views/Components/DayGoalHeader.swift`
- `Dayflow/Dayflow/Views/Components/DayFocusSummarySection.swift`
- `Dayflow/Dayflow/Views/Components/DayCategorySelectionEditor.swift`
- LG16/LG17 surface/button 封装文件（仅必要调用）

关键改动：

1. `DayGoalFlowOverlay` 不再使用沉重旧遮罩。
2. Goal flow 主操作按钮改用统一按钮/surface。
3. category pool、setup panel、duration picker 周边 chrome 接入 Daily/Content token。
4. 保留 focus/distraction 语义色，不重写 goal 业务、拖放逻辑、analytics。

验收标准：

- Daily goal flow 与 Daily 页面视觉系统一致。
- 固定 canvas 可保留，但视觉 chrome 不再像独立 Figma mock。
- setup/review 两个 screen 都可读可操作。

验证命令：

```bash
rg -n 'Color\(hex: "FCFCFC"|Color\(hex: "E7DFDF"|Color\(hex: "FF8046"|foregroundColor\(\.white\)|background\(Design|primaryButton|secondaryButton|DayflowDailyToken|DayflowContentToken|dayflow' \
  Dayflow/Dayflow/Views/Components/DayGoalFlowView.swift \
  Dayflow/Dayflow/Views/Components/DayGoalHeader.swift \
  Dayflow/Dayflow/Views/Components/DayFocusSummarySection.swift \
  Dayflow/Dayflow/Views/Components/DayCategorySelectionEditor.swift
git diff --check
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig GIT_ALLOW_PROTOCOL=file:https xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -configuration Debug -derivedDataPath build/local-derived CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

建议提交信息：

```text
feat(daily): align goal flow with glass surfaces
```

## LG21：Settings 与 Chat 控件 OS26 补齐

目标：

- Settings 和 Chat 已有 macOS 15 material/token 风格，但控件层缺少 macOS 26 glass 分支；补齐局部 control surface。

允许范围：

- `Dayflow/Dayflow/Views/UI/Settings/SettingsComponents.swift`
- `Dayflow/Dayflow/Views/UI/SettingsView.swift`
- `Dayflow/Dayflow/Views/UI/Settings/*.swift`
- `Dayflow/Dayflow/Views/UI/ChatStylesAndDebug.swift`
- `Dayflow/Dayflow/Views/UI/ChatView+Content.swift`
- `Dayflow/Dayflow/Views/UI/ChatMessageViews.swift`
- `Dayflow/Dayflow/Views/UI/ChatWorkStatusViews.swift`
- `Dayflow/Dayflow/Views/Components/ToolCallBubble.swift`
- LG16/LG17 surface/button 封装文件（仅必要调用）

关键改动：

1. Settings control surface 保持“三种按钮 treatment”原则，同时补齐 macOS 26 path。
2. Chat composer、provider toggle、debug/tools controls 可使用 floating/control glass。
3. 消息内容层不要全 glass 化，保持 material/card 可读。

验收标准：

- Settings controls 在 macOS 15/26 路径都有清晰说明和实现。
- Chat composer/provider/tool controls 与全局 glass 系统一致。
- 长消息、代码块、tool call 可读性不退化。

验证命令：

```bash
rg -n 'settingsControlSurface|chatMessageSurface|ProviderTogglePill|BetaButtonStyle|PressScaleButtonStyle|glassEffect|GlassEffectContainer|dayflowFloatingControl|Color\(hex: "F4A867"|Color\(hex: "E5D8CA"' \
  Dayflow/Dayflow/Views/UI/SettingsView.swift \
  Dayflow/Dayflow/Views/UI/Settings \
  Dayflow/Dayflow/Views/UI/Chat* \
  Dayflow/Dayflow/Views/Components/ToolCallBubble.swift
git diff --check
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig GIT_ALLOW_PROTOCOL=file:https xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -configuration Debug -derivedDataPath build/local-derived CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

建议提交信息：

```text
feat(ui): refine settings and chat glass controls
```

## LG22：Onboarding 控件统一收口

目标：

- Onboarding 的 CTA/provider/category/permission 控件统一到 LG17 按钮与 surface 体系，避免 intro 后页面仍像旧 landing page。

允许范围：

- `Dayflow/Dayflow/Views/Onboarding/TerminalCommandView.swift`
- `Dayflow/Dayflow/Views/Onboarding/ChatCLIDetectionViews.swift`
- `Dayflow/Dayflow/Views/Onboarding/HowItWorksView.swift`
- `Dayflow/Dayflow/Views/Onboarding/OnboardingFlow.swift`
- `Dayflow/Dayflow/Views/Onboarding/LLMProviderSetupView.swift`
- `Dayflow/Dayflow/Views/Onboarding/ScreenRecordingPermissionView.swift`
- `Dayflow/Dayflow/Views/Onboarding/OnboardingCategoryStepView.swift`
- `Dayflow/Dayflow/Views/Onboarding/Prototype/*.swift`
- `Dayflow/Dayflow/Views/Components/ProviderCardComponents.swift`
- LG16/LG17 surface/button 封装文件（仅必要调用）

关键改动：

1. CTA/provider/category/permission 控件复用统一 button/surface。
2. 保留线条动画链路，不恢复 bundled mp4。
3. 不改 provider 检测、CLI 检测、screen recording 权限业务。

验收标准：

- Onboarding intro 后步骤不再混用旧白底 CTA。
- Provider/card/permission controls 与主 UI 的 glass/material 体系一致。
- `DayflowAnimation`、`DayflowOnboarding`、`JournalOnboardingVideo` 旧 asset 名不回归。

验证命令：

```bash
rg -n 'DayflowSurfaceButton\(|Color\.white|primaryButtonFill|secondaryButton|dayflowOnboardingPanel|dayflowOnboardingOptionCard|dayflowFloatingControl' \
  Dayflow/Dayflow/Views/Onboarding Dayflow/Dayflow/Views/Components/ProviderCardComponents.swift
rg -n 'DayflowAnimation|DayflowOnboarding|JournalOnboardingVideo|Bundle\.main\.url\(forResource:.*mp4|AVPlayerItem\(url:' \
  Dayflow/Dayflow/Views/Onboarding Dayflow/Dayflow/App/DayflowApp.swift
git diff --check
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig GIT_ALLOW_PROTOCOL=file:https xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -configuration Debug -derivedDataPath build/local-derived CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

建议提交信息：

```text
feat(onboarding): unify glass control styling
```

## LG23：最终视觉 QA 与文档收口

目标：

- 对 LG16-LG22 后的当前状态做最终残留扫描、文档更新、人工视觉验收清单补齐。

允许范围：

- `docs/LIQUID_GLASS_UI_MIGRATION_INVENTORY.md`
- `docs/LIQUID_GLASS_UI_MIGRATION_TASKS.md`
- `scripts/audit-liquid-glass-final.sh`
- `CLAUDE.md`（仅补充验证说明；注意当前可能被 `.gitignore` 忽略，若要提交需显式处理）

关键改动：

1. 更新 inventory：记录 LG16-LG22 已迁移、保留原因、未解决问题。
2. 更新最终人工验收清单，覆盖 macOS 15 fallback 和 macOS 26+ Liquid Glass path。
3. 更新或补强只读残留扫描脚本。
4. 不做大范围 Swift UI 修改；如发现新 Swift 范围缺口，停止报告新任务。

验收标准：

- 文档清楚说明 macOS 15 material path 和 macOS 26 Liquid Glass path。
- 残留扫描输出都有解释或后续任务。
- 不引入新的 UI 实现改动范围漂移。

验证命令：

```bash
bash scripts/audit-liquid-glass-final.sh
rg -n 'glassEffect|GlassEffect|GlassButtonStyle|GlassProminentButtonStyle|backgroundExtensionEffect|#available\(macOS 26|@available\(macOS 26' Dayflow/Dayflow docs
rg -n 'Color\(red: 0\.98|FBF6EF|F7F3F0|FAF3EB|Color\.white\)|background\(Color\.white' Dayflow/Dayflow
find Dayflow/Dayflow -iname '*.mp4' -o -iname '*.mov' -o -iname '*.m4v'
git diff --check
env GIT_CONFIG_GLOBAL=/private/tmp/dayflow-gitconfig GIT_ALLOW_PROTOCOL=file:https xcodebuild -project Dayflow/Dayflow.xcodeproj -scheme Dayflow -configuration Debug -derivedDataPath build/local-derived CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

建议提交信息：

```text
docs(ui): finalize liquid glass follow-up audit
```

## 最终人工验收清单

完成 LG15 以及后续 LG16-LG23 收口后，建议人工逐项检查：

1. 首次启动线条动画能完成并进入 onboarding 或主界面。
2. Onboarding 全步骤在 900x508 最小窗口下没有文字重叠。
3. Timeline day/week、activity selection、inspector、review prompt 可用。
4. Daily locked/unlocked、standup、goal flow 可用。
5. Weekly overview 和各图表 section 可读。
6. Journal day/week/reminder 可读。
7. Chat 长消息、代码块、composer、tool call 可用。
8. Settings provider/storage/privacy/data tabs 可用。
9. Calendar popover、category picker、feedback modal、What's New、video modal 可用。
10. Reduce Motion 下线条动画和页面过渡不造成卡住。
11. Reduce Transparency / Increase Contrast 下文字和控件边界仍清楚。
12. macOS 15.7 路径呈现 Codex-like 中性半透明工具感。
13. macOS 26+ 路径使用 Liquid Glass API，功能层和内容层层级清楚。
