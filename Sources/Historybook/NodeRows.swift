import HistorybookCore
import SwiftUI

/// Full-width buttons keep search and visit entries clickable and accessible.
struct NodeRows: View {
    let nodes: [HistoryNode]
    let onOpen: (String) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(Array(nodes.enumerated()), id: \.offset) { _, node in
                    Button {
                        onOpen(node.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(node.title)
                                .font(Theme.serif(18, weight: .semibold))
                                .foregroundStyle(Theme.ink)
                            Text("\(node.type.displayName) · \(node.timeLabel)")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.muted)
                            if !node.summary.isEmpty {
                                Text(node.summary)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Theme.muted)
                                    .lineLimit(2)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10).stroke(Theme.line, lineWidth: 1)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(2)
        }
    }
}
