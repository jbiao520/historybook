import HistorybookCore
import SwiftUI

struct HistoryListView: View {
    @Bindable var model: LibraryModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("浏览历史")
                .font(Theme.serif(34, weight: .semibold))
                .foregroundStyle(Theme.ink)
            if model.exploration.visitHistory.isEmpty {
                Text("还没有打开过知识节点。从首页或时间轴选一条开始。")
                    .foregroundStyle(Theme.muted)
                Spacer()
            } else {
                NodeRows(
                    nodes: model.exploration.visitHistory.reversed().compactMap {
                        model.library?.node(id: $0)
                    },
                    onOpen: model.openNode
                )
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.paper)
    }
}
