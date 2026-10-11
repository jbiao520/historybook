import HistorybookCore
import SwiftUI

struct TimelineView: View {
    @Bindable var model: LibraryModel

    var body: some View {
        let events = Timeline.datedEvents(in: model.nodes)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("时间轴")
                    .font(Theme.serif(34, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text("960–1279 · 点击条目打开对应知识节点")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.muted)
                    .padding(.bottom, 22)

                ForEach(Array(events.enumerated()), id: \.element.id) { index, event in
                    Button {
                        model.openNode(event.id)
                    } label: {
                        HStack(alignment: .top, spacing: 16) {
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(Theme.accent)
                                    .frame(width: 10, height: 10)
                                    .padding(.top, 6)
                                if index < events.count - 1 {
                                    Rectangle()
                                        .fill(Theme.line)
                                        .frame(width: 1)
                                        .frame(maxHeight: .infinity)
                                }
                            }
                            .frame(width: 12)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.timeLabel)
                                    .font(.system(size: 12, weight: .semibold, design: .serif))
                                    .foregroundStyle(Theme.accent)
                                Text(event.title)
                                    .font(Theme.serif(20, weight: .semibold))
                                    .foregroundStyle(Theme.ink)
                                if !event.summary.isEmpty {
                                    Text(event.summary)
                                        .font(.system(size: 13))
                                        .foregroundStyle(Theme.muted)
                                        .lineLimit(2)
                                }
                                if let location = event.location {
                                    Text("\(event.dynasty) · \(location)")
                                        .font(.system(size: 13))
                                        .foregroundStyle(Theme.muted)
                                }
                            }
                            .padding(.bottom, 22)
                            Spacer(minLength: 0)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(32)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.paper)
    }
}
