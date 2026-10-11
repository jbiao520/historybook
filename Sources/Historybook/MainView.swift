import HistorybookCore
import SwiftUI

struct MainView: View {
    @State private var model = LibraryModel()

    var body: some View {
        NavigationSplitView {
            List(SidebarSection.allCases, selection: sidebarSelection) { section in
                Label(section.title, systemImage: section.symbol)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .navigationTitle("Historybook")
            .frame(minWidth: 180)
        } detail: {
            VStack(spacing: 0) {
                explorationBar
                Divider()
                detail
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Theme.paper)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 980, minHeight: 680)
        .background(Theme.paper)
        .onAppear {
            if model.library == nil && model.loadError == nil {
                model.load()
            }
        }
    }

    private var sidebarSelection: Binding<SidebarSection?> {
        Binding(
            get: { model.section },
            set: { section in
                if let section {
                    model.show(section)
                }
            }
        )
    }

    private var explorationBar: some View {
        HStack(spacing: 12) {
            Button {
                model.goBack()
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(!model.exploration.canGoBack)
            .help("返回")
            .accessibilityLabel("返回")
            .keyboardShortcut("[", modifiers: .command)

            Button {
                model.goForward()
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(!model.exploration.canGoForward)
            .help("前进")
            .accessibilityLabel("前进")
            .keyboardShortcut("]", modifiers: .command)

            if model.breadcrumbNodes.isEmpty {
                Text("宋朝  ›  \(model.currentTrail?.title ?? model.section.title)")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.muted)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button("宋朝") { model.show(.home) }
                            .help("返回宋朝首页")
                        ForEach(Array(model.breadcrumbNodes.enumerated()), id: \.offset) { index, node in
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9))
                                .foregroundStyle(Theme.muted)
                            Button(node.title) { model.goToBreadcrumb(at: index) }
                                .disabled(index == model.breadcrumbNodes.count - 1)
                                .help("回到\(node.title)")
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: true, vertical: false)
                }
            }
            Spacer()
            Button {
                model.show(.search)
            } label: {
                Image(systemName: "magnifyingglass")
            }
            .help("搜索所有内容（⌘F）")
            .accessibilityLabel("搜索所有内容")
            .keyboardShortcut("f", modifiers: .command)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.card)
    }

    @ViewBuilder
    private var detail: some View {
        if let loadError = model.loadError {
            Text(loadError)
                .foregroundStyle(Theme.muted)
                .padding(32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.paper)
        } else if model.pane == .article, let node = model.currentNode, let root = model.library?.root {
            ArticleWebView(
                html: model.html(for: node),
                baseURL: root,
                onOpenNode: { model.openNode($0) }
            )
        } else if let trail = model.currentTrail {
            TrailDetailView(model: model, trail: trail)
        } else {
            switch model.section {
            case .home:
                HomeView(model: model)
            case .timeline:
                TimelineView(model: model)
            case .topics:
                TrailsView(model: model)
            case .search:
                SearchView(model: model)
            case .history:
                HistoryListView(model: model)
            }
        }
    }
}
