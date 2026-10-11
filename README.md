# Historybook

宋朝历史的离线阅读应用。macOS 14 及以上，SwiftUI 窗口，文章用本地 HTML/CSS 在 WKWebView 中排版。没有账号、后端或运行时网络请求。

内容是打包进 App 的 Markdown、JSON 和图片。新增一个知识节点只需要加文件，不需要改 Swift。

## 构建

需要支持 Swift 6 的 Xcode 或命令行工具。测试使用 Swift Testing；对于本机命令行工具中位于独立目录的 Testing.framework，Package.swift 会补充搜索路径。

```bash
swift build
swift test
```

生成可双击打开的 App：

```bash
Scripts/assemble-app.sh
open .build/Historybook.app
```

`LSMinimumSystemVersion` 是 14.0。脚本默认使用 Release 构建，把可执行文件和一份 `Content` 资源放进 `.build/Historybook.app`，并进行本地临时签名和签名验证。可以把整个 App 复制到「应用程序」后双击运行。当前产物适用于构建机器的架构。

一条命令完成内容、导航测试及打包资源检查：

```bash
Scripts/check-mvp.sh
```

需要 Debug App 时运行 `HISTORYBOOK_CONFIGURATION=debug Scripts/assemble-app.sh`。V0.1 验收见 [Docs/Acceptance.md](Docs/Acceptance.md)。V0.2 的内容扩充、主题路线和窗口验收见 [Docs/Acceptance-v0.2.md](Docs/Acceptance-v0.2.md)。

## 阅读

窗口左侧是首页、时间轴、主题探索、搜索、浏览历史。右侧是阅读区。首页展示宋朝（960—1279）、简介、背景图、可点击的时间轴、六条主题路线，以及事件和探索入口。

正文里的 `history://节点id` 链接、底部关联卡片都会在 App 内打开下一篇。返回和前进覆盖首页、时间轴、主题探索、路线、搜索、浏览历史以及文章。从路线进入文章后，返回回到该路线，前进恢复文章。路线本身不写入浏览历史。点击面包屑可返回之前的文章，并保留前进路径。浏览历史按最近访问在前显示本次运行中打开过的节点。

任意页面按 `⌘F` 或点击顶部放大镜即可搜索，输入框会自动获得焦点。搜索依次匹配标题、关键词、简介、正文和图说；图片路径和内部链接地址不参与搜索。`⌘[` 返回，`⌘]` 前进。界面和文章配色自动跟随系统深色模式。

配图都是历史场景重建，不能当作原始史料。

## 增加一个节点

在 `Sources/Historybook/Content` 里添加两个文件：

`metadata/your-id.json`

```json
{
  "id": "your-id",
  "title": "篇名",
  "type": "event",
  "year": 1000,
  "yearEnd": 1004,
  "dynasty": "北宋",
  "location": "开封",
  "cover": "cover-your-id.webp",
  "article": "your-id.md",
  "keywords": ["关键词"],
  "relatedIds": ["chenqiao-mutiny", "dongjing-bianliang", "military-system"],
  "references": ["相关史料的书名、卷次或篇名"],
  "summary": "用一句话说明这篇为什么值得打开。",
  "dateLabel": "约1084–卒年未定"
}
```

`type` 使用 `event`（历史事件）、`person`（历史人物）、`place`（历史地点）或 `culture`（制度与文化）。`yearEnd`、`location`、`keywords`、`references`、`summary`、`dateLabel` 可以省略。旧的元数据没有简介也能加载。`summary` 会出现在搜索、卡片和时间轴上。`dateLabel` 用于约略纪年或需要说明农历与公历跨年的场合，填写后会代替由年份自动生成的时间标签。`relatedIds` 写 3 到 6 个已经存在的 id。`references` 是可离线显示的书目文字，会出现在正文后的「阅读线索」。节点 ID 必须唯一。

`articles/your-id.md` 使用普通段落。链到其他节点时写成 `[显示文字](history://节点id)`。文中配图写成 `![图说](images/某张图.webp)`，每篇 2 到 4 张。封面文件放在 `images/`，只写文件名。

图片使用 WebP 或 JPEG，长边至少 800 像素，比例为 16:9 或 3:2。有争议的说法在正文里用 `【争议】` 标出。

主题路线放在 `trails.json`。每条路线有 id、标题、问题、简介、封面和有序步骤；每一步写 `nodeID` 和一句阅读说明。路线 id 不能重复，步骤不能为空或重复，也不能指向不存在的节点。缺少这个文件时，主题探索显示空状态，原有文章仍可阅读。Swift 源码里不写路线名称和节点名单。

当前内容库有 45 篇正文：事件 14、人物 13、地点 7、制度与文化 11。每篇 800～1500 字、3 张正文配图和一张封面，每篇关联 3～6 个节点，并有一句简介。另有 6 条主题路线。配图继续复用历史场景重建，封面文件彼此不同。共使用 62 个本地 WebP 文件。

保存后重新执行 `swift build` 和 `Scripts/assemble-app.sh`。加载器会扫描 `metadata/*.json`，Swift 源码里没有节点名单。
