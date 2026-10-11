import AppKit
import HistorybookCore
import SwiftUI

struct TrailsView: View {
    @Bindable var model: LibraryModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("主题探索")
                    .font(Theme.serif(34, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text("选一个问题，沿着人物、事件、地点和制度读下去。每条路线都可以随时转向你感兴趣的知识链接。")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.muted)
                if model.trails.isEmpty {
                    Text("暂无主题路线，可以先从首页或时间轴自由探索。")
                        .foregroundStyle(Theme.muted)
                } else {
                    TrailGrid(model: model)
                }
            }
            .padding(32)
            .frame(maxWidth: 980, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.paper)
    }
}

struct TrailGrid: View {
    @Bindable var model: LibraryModel

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 16)], spacing: 16) {
            ForEach(model.trails) { trail in
                Button {
                    model.openTrail(trail.id)
                } label: {
                    VStack(alignment: .leading, spacing: 0) {
                        if let url = model.imageURL(trail.cover), let image = NSImage(contentsOf: url) {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 140)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .accessibilityHidden(true)
                        }
                        VStack(alignment: .leading, spacing: 8) {
                            Text(trail.title)
                                .font(Theme.serif(22, weight: .semibold))
                                .foregroundStyle(Theme.ink)
                            Text(trail.question)
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.muted)
                                .lineLimit(2)
                            Text("\(trail.steps.count) 篇 · 开始探索")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.accent)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14).stroke(Theme.line, lineWidth: 1)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct TrailDetailView: View {
    @Bindable var model: LibraryModel
    let trail: HistoryTrail

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Button("所有主题") { model.show(.topics) }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.accent)
                Text(trail.title)
                    .font(Theme.serif(36, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text(trail.question)
                    .font(Theme.serif(22))
                    .foregroundStyle(Theme.accent)
                Text(trail.introduction)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.muted)
                    .lineSpacing(5)
                Text("推荐阅读顺序 · \(trail.steps.count) 篇")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 12)
                ForEach(Array(trail.steps.enumerated()), id: \.element.nodeID) { index, step in
                    if let node = model.library?.node(id: step.nodeID) {
                        Button {
                            model.openNode(node.id)
                        } label: {
                            HStack(alignment: .top, spacing: 16) {
                                Text(String(index + 1))
                                    .font(Theme.serif(24, weight: .semibold))
                                    .foregroundStyle(Theme.accent)
                                    .frame(width: 30)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(node.title)
                                        .font(Theme.serif(21, weight: .semibold))
                                        .foregroundStyle(Theme.ink)
                                    Text("\(node.type.displayName) · \(node.timeLabel)")
                                        .font(.system(size: 12))
                                        .foregroundStyle(Theme.muted)
                                    Text(step.reason)
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.muted)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "arrow.up.right")
                                    .foregroundStyle(Theme.accent)
                            }
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12).stroke(Theme.line, lineWidth: 1)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(32)
            .frame(maxWidth: 800, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.paper)
    }
}
