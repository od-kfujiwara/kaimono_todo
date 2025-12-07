import SwiftUI

// 買い物アイテムの行表示
struct ShoppingItemRow: View {
    let item: ShoppingItem
    let isEditing: Bool
    @FocusState.Binding var focusedItemId: UUID?
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onTextChange: (String) -> Void
    let onSubmit: () -> Void

    @State private var isLongPressing = false

    var body: some View {
        HStack {
            if isEditing {
                // テキスト編集中
                TextField("", text: .init(
                    get: { item.text },
                    set: { onTextChange($0) }
                ))
                .focused($focusedItemId, equals: item.id)
                .submitLabel(.next)
                .onSubmit {
                    onSubmit()
                }
            } else {
                // 通常表示
                Text(item.text)
                    .strikethrough(item.isCompleted)
                    .foregroundColor(item.isCompleted ? .gray : .primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .scaleEffect(isLongPressing ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isLongPressing)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.3, pressing: { isPressing in
            withAnimation {
                isLongPressing = isPressing
            }
        }, perform: {
            onLongPress()
        })
        .onTapGesture {
            if !isEditing {
                onTap()
            }
        }
        .listRowBackground(isLongPressing ? Color.gray.opacity(0.2) : Color.clear)
    }
}
