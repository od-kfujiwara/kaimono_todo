import SwiftUI

struct ShoppingListView: View {
    @StateObject private var store = ShoppingListStore()
    @State private var editingItemId: UUID?
    @FocusState private var focusedItemId: UUID?
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.items) { item in
                    ShoppingItemRow(
                        item: item,
                        isEditing: editingItemId == item.id,
                        focusedItemId: $focusedItemId,
                        onTap: { toggleCompletion(item) },
                        onLongPress: { startEditing(item) },
                        onTextChange: { newText in updateText(item, newText) },
                        onSubmit: addItemAndContinue
                    )
                }
                .onMove(perform: moveItem)
            }
            .listStyle(.plain)
            .environment(\.editMode, .constant(.active))
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
                if newValue == nil && !isSubmitting {
                    // 編集終了時、空のアイテムは削除
                    if let editingId = editingItemId,
                       let item = store.items.first(where: { $0.id == editingId }),
                       item.text.isEmpty {
                        store.items.removeAll { $0.id == editingId }
                        store.save()
                    }
                    editingItemId = nil
                }
                // 新しいフォーカスがあればSubmit完了
                if newValue != nil {
                    isSubmitting = false
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            focusedItemId = nil
        }
    }

    // 完了/未完了の切り替え
    private func toggleCompletion(_ item: ShoppingItem) {
        guard editingItemId != item.id else { return }
        if let index = store.items.firstIndex(where: { $0.id == item.id }) {
            store.items[index].isCompleted.toggle()

            // 完了アイテムを最下部に移動
            withAnimation {
                store.items.sort { !$0.isCompleted && $1.isCompleted }
            }

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

    // Returnキーで次のアイテム追加
    private func addItemAndContinue() {
        guard let currentEditingId = editingItemId,
              let currentItem = store.items.first(where: { $0.id == currentEditingId }),
              !currentItem.text.isEmpty else {
            return
        }

        isSubmitting = true

        // 編集中以外で空のアイテムが既にある場合は、そのアイテムを編集
        if let emptyItem = store.items.first(where: { $0.text.isEmpty && $0.id != currentEditingId }) {
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

    // アイテムの並び替え
    private func moveItem(from source: IndexSet, to destination: Int) {
        store.items.move(fromOffsets: source, toOffset: destination)
        store.save()
    }
}

#Preview {
    ShoppingListView()
}
