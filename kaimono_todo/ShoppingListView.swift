import SwiftUI

struct ShoppingListView: View {
    @StateObject private var store = ShoppingListStore()
    @State private var editingItemId: UUID?
    @FocusState private var focusedItemId: UUID?

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedItems) { item in
                    ShoppingItemRow(
                        item: item,
                        isEditing: editingItemId == item.id,
                        focusedItemId: $focusedItemId,
                        onTap: { toggleCompletion(item) },
                        onLongPress: { startEditing(item) },
                        onTextChange: { newText in updateText(item, newText) }
                    )
                }
            }
            .listStyle(.plain)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: deleteCompleted) {
                        Image(systemName: "trash")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: addItem) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onChange(of: focusedItemId) { oldValue, newValue in
                if newValue == nil {
                    // 編集終了時、空のアイテムは削除
                    if let editingId = editingItemId,
                       let item = store.items.first(where: { $0.id == editingId }),
                       item.text.isEmpty {
                        store.items.removeAll { $0.id == editingId }
                        store.save()
                    }
                    editingItemId = nil
                }
            }
        }
    }

    // 未完了を上、完了済みを下に表示
    private var sortedItems: [ShoppingItem] {
        store.items.sorted { !$0.isCompleted && $1.isCompleted }
    }

    // 完了/未完了の切り替え
    private func toggleCompletion(_ item: ShoppingItem) {
        guard editingItemId != item.id else { return }
        if let index = store.items.firstIndex(where: { $0.id == item.id }) {
            store.items[index].isCompleted.toggle()
            store.save()
        }
    }

    // 編集モード開始
    private func startEditing(_ item: ShoppingItem) {
        editingItemId = item.id
        focusedItemId = item.id
    }

    // テキスト更新
    private func updateText(_ item: ShoppingItem, _ newText: String) {
        if let index = store.items.firstIndex(where: { $0.id == item.id }) {
            store.items[index].text = newText
            store.save()
        }
    }

    // 新しいアイテム追加
    private func addItem() {
        // 空のアイテムが既にある場合は、そのアイテムを編集
        if let emptyItem = store.items.first(where: { $0.text.isEmpty }) {
            editingItemId = emptyItem.id
            focusedItemId = emptyItem.id
        } else {
            let newItem = ShoppingItem(text: "")
            store.items.insert(newItem, at: 0)
            editingItemId = newItem.id
            focusedItemId = newItem.id
            store.save()
        }
    }

    // 完了済みアイテムを削除
    private func deleteCompleted() {
        store.items.removeAll { $0.isCompleted }
        store.save()
    }
}

struct ShoppingItemRow: View {
    let item: ShoppingItem
    let isEditing: Bool
    @FocusState.Binding var focusedItemId: UUID?
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onTextChange: (String) -> Void

    var body: some View {
        HStack {
            if isEditing {
                TextField("アイテム名", text: .init(
                    get: { item.text },
                    set: { onTextChange($0) }
                ))
                .focused($focusedItemId, equals: item.id)
            } else {
                Text(item.text)
                    .strikethrough(item.isCompleted)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditing {
                onTap()
            }
        }
        .onLongPressGesture {
            onLongPress()
        }
    }
}

#Preview {
    ShoppingListView()
}
