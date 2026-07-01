# Chinese UI Localization Inventory

> 用于记录中文化任务清点与剩余英文待处理项。

## 当前状态（2026-07-01）

- 基线脚本：`scripts/audit-ui-english.sh`
- allowlist：`scripts/ui-english-allowlist.txt`
- 尚未完成中文化清单：待 `bash scripts/audit-ui-english.sh` 扫描后更新。

## 处理原则

- 只翻译用户可见文案（标题、按钮、说明、提示、弹窗、状态文案）。
- 保留品牌名、命令、URL、provider raw value、模型名、analytics key、用户标识符、JSON key。
- 如确认为非用户可见文本，写入 allowlist 并注明原因。
