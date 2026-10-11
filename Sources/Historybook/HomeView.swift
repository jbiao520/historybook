import AppKit
import HistorybookCore
import SwiftUI

struct HomeView: View {
    @Bindable var model: LibraryModel

    var body: some View {
        let home = model.library?.home
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                hero(home: home)
                timelineBand
                if !model.trails.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("沿着主题探索", detail: "\(model.trails.count) 条阅读路线 · \(model.nodes.count) 个知识节点")
                        TrailGrid(model: model)
                    }
                }
                if let ids = home?.featuredIds, !ids.isEmpty {
                    featured(ids: ids)
                }
                explorationEntries
            }
            .padding(28)
            .frame(maxWidth: 980, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.paper)
    }

    private func hero(home: HomePage?) -> some View {
        ZStack(alignment: .bottomLeading) {
            heroImage(named: home?.background)
                .frame(height: 320)
                .frame(maxWidth: .infinity)
                .clipped()
            LinearGradient(
                colors: [Color.black.opacity(0.05), Color.black.opacity(0.62)],
                startPoint: .top,
                endPoint: .bottom
            )
            VStack(alignment: .leading, spacing: 8) {
                Text(home?.title ?? "宋朝")
                    .font(Theme.serif(52, weight: .bold))
                    .foregroundStyle(Color.white)
                Text("\(String(home?.startYear ?? 960)) — \(String(home?.endYear ?? 1279))")
                    .font(Theme.serif(22, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.92))
                Text(home?.introduction ?? "")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .lineSpacing(4)
                    .frame(maxWidth: 640, alignment: .leading)
            }
            .padding(28)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private func heroImage(named fileName: String?) -> some View {
        if let fileName, let url = model.imageURL(fileName), let image = NSImage(contentsOf: url) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Rectangle().fill(Theme.accent.opacity(0.35))
        }
    }

    private var timelineBand: some View {
        let events = Timeline.datedEvents(in: model.nodes)
        return VStack(alignment: .leading, spacing: 12) {
            sectionTitle("时间轴", detail: "960–1279")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    yearCap("960")
                    ForEach(events) { event in
                        Button {
                            model.openNode(event.id)
                        } label: {
                            VStack(spacing: 8) {
                                Text(String(event.year))
                                    .font(.system(size: 12, weight: .semibold, design: .serif))
                                    .foregroundStyle(Theme.accent)
                                Circle()
                                    .fill(Theme.accent)
                                    .frame(width: 9, height: 9)
                                Text(event.title)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.ink)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 88)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                    yearCap("1279")
                }
                .padding(.vertical, 8)
                .background(alignment: .top) {
                    Rectangle()
                        .fill(Theme.line)
                        .frame(height: 1)
                        .padding(.top, 30)
                        .padding(.horizontal, 24)
                }
            }
        }
    }

    private func yearCap(_ year: String) -> some View {
        VStack(spacing: 8) {
            Text(year)
                .font(Theme.serif(13, weight: .bold))
                .foregroundStyle(Theme.ink)
            RoundedRectangle(cornerRadius: 2)
                .fill(Theme.ink)
                .frame(width: 2, height: 14)
            Text(" ")
                .font(.system(size: 12))
                .frame(width: 36)
        }
    }

    private func featured(ids: [String]) -> some View {
        let nodes = ids.compactMap { model.library?.node(id: $0) }
        return VStack(alignment: .leading, spacing: 12) {
            sectionTitle("重要事件与探索入口", detail: "从这里进入")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 14)], spacing: 14) {
                ForEach(nodes) { node in
                    Button {
                        model.openNode(node.id)
                    } label: {
                        featuredCard(node)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func featuredCard(_ node: HistoryNode) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            cardImage(node.cover)
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .clipped()
            VStack(alignment: .leading, spacing: 4) {
                Text(node.type.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                Text(node.title)
                    .font(Theme.serif(18, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text(node.timeLabel)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)
                if !node.summary.isEmpty {
                    Text(node.summary)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.muted)
                        .lineLimit(2)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.line, lineWidth: 1)
        )
    }

    private var explorationEntries: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("按类别浏览", detail: "人物、地点与制度")
            ForEach(NodeType.allCases, id: \.self) { type in
                let group = model.nodes.filter { $0.type == type }
                if !group.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(type.displayName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.muted)
                        FlowTags(nodes: group) { node in
                            model.openNode(node.id)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cardImage(_ fileName: String) -> some View {
        if let url = model.imageURL(fileName), let image = NSImage(contentsOf: url) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Rectangle().fill(Theme.line.opacity(0.4))
        }
    }

    private func sectionTitle(_ title: String, detail: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(Theme.serif(24, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Text(detail)
                .font(.system(size: 13))
                .foregroundStyle(Theme.muted)
        }
    }
}

private struct FlowTags: View {
    let nodes: [HistoryNode]
    let open: (HistoryNode) -> Void

    var body: some View {
        FlexibleRow(nodes: nodes, open: open)
    }
}

private struct FlexibleRow: View {
    let nodes: [HistoryNode]
    let open: (HistoryNode) -> Void

    private let columns = [GridItem(.adaptive(minimum: 148), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(nodes) { node in
                Button {
                    open(node)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(node.title)
                            .font(.system(size: 13, weight: .medium))
                        Text(node.timeLabel)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.muted)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Theme.line, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.ink)
            }
        }
    }
}
