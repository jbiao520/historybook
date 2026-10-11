import HistorybookCore
import SwiftUI

struct SearchView: View {
    @Bindable var model: LibraryModel
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("搜索")
                .font(Theme.serif(34, weight: .semibold))
                .foregroundStyle(Theme.ink)
            TextField("搜索标题、关键词或正文", text: $model.searchQuery)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 16))
                .focused($searchFocused)
                .onAppear {
                    // Focus after AppKit has attached the newly shown field.
                    DispatchQueue.main.async { searchFocused = true }
                }
            if model.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("可以试着搜索「澶渊之盟」，或正文里的一个词。")
                    .foregroundStyle(Theme.muted)
                Spacer()
            } else if model.searchResults.isEmpty {
                Text("没有找到与「\(model.searchQuery)」匹配的节点。")
                    .foregroundStyle(Theme.muted)
                Spacer()
            } else {
                NodeRows(nodes: model.searchResults, onOpen: model.openNode)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.paper)
    }

}
