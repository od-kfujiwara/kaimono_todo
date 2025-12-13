import SwiftUI

struct ShoppingListView: View {
    @StateObject private var store: ShoppingListStore
    @State private var editingItemId: UUID?
    @FocusState private var focusedItemId: UUID?
    @State private var isSubmitting = false
    @State private var showOnboardingHint = false
    @State private var tourStage: TourStage = .done

    private let onboardingHintKey = "app_onboarding_hint_seen"
    private let tourStageKey = "onboarding_tour_stage"
    init(listId: Int) {
        _store = StateObject(wrappedValue: ShoppingListStore(listId: listId))
    }

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
            .overlay {
                if store.items.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "cart")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("右上の + ボタンから\nアイテムを登録できます")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                if tourStage == .addFromPlus {
                    calloutBubble(title: TourCopy.addTitle,
                                  iconName: "plus",
                                  color: .red,
                                  arrowOffset: 220,
                                  width: 200)
                        .padding(.trailing, 12)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(2)
                }
            }
            .overlay(alignment: .topLeading) {
                if tourStage == .longPressEdit {
                    calloutBubble(title: TourCopy.editTitle,
                                  iconName: "hand.point.up.left",
                                  color: .red,
                                  arrowOffset: 32,
                                  width: 200)
                        .padding(.leading, 12)
                        .padding(.top, 80)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(2)
                }
            }
            .overlay(alignment: .topLeading) {
                if shouldShowDeleteCallout {
                    calloutBubble(title: TourCopy.deleteTitle,
                                  iconName: "trash",
                                  color: .red,
                                  arrowOffset: 32,
                                  width: 200)
                        .padding(.leading, 12)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(2)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: deleteButtonTapped) {
                        Image(systemName: "trash")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: addItemTapped) {
                        Image(systemName: "plus")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if focusedItemId != nil {
                    HStack {
                        Spacer()
                        Button("完了") {
                            focusedItemId = nil
                        }
                        .font(.title3)
                        .fontWeight(.bold)
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(.clear)
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
            if showOnboardingHint {
                markOnboardingHintSeen()
            }
            advanceTourFromTap()
        }
        .onAppear {
            showOnboardingHintIfNeeded()
            loadTourStageIfNeeded()
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
        if tourStage == .longPressEdit {
            advanceTour(to: .deleteOnlyCompleted)
        }
    }

    // テキスト更新
    private func updateText(_ item: ShoppingItem, _ newText: String) {
        if let index = store.items.firstIndex(where: { $0.id == item.id }) {
            store.items[index].text = newText
            store.saveDebounced()
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

    private func addItemTapped() {
        addItem()
        if tourStage == .addFromPlus {
            advanceTour(to: .longPressEdit)
        }
    }

    // 完了済みアイテムを削除
    private func deleteCompleted() {
        store.items.removeAll { $0.isCompleted }
        store.save()
    }

    private func deleteButtonTapped() {
        deleteCompleted()
        if tourStage == .deleteOnlyCompleted {
            markOnboardingHintSeen()
            advanceTour(to: .done)
        }
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
        store.saveDebounced()
    }

    private func showOnboardingHintIfNeeded() {
        let hasSeen = UserDefaults.standard.bool(forKey: onboardingHintKey)
        showOnboardingHint = !hasSeen
    }

    private func markOnboardingHintSeen() {
        UserDefaults.standard.set(true, forKey: onboardingHintKey)
        showOnboardingHint = false
    }

    // オンボーディング表示制御
    private func loadTourStageIfNeeded() {
        if let saved = UserDefaults.standard.string(forKey: tourStageKey),
           let stage = TourStage(rawValue: saved) {
            tourStage = stage
        } else {
            tourStage = .addFromPlus
        }
    }

    private func advanceTour(to next: TourStage) {
        tourStage = next
        if next == .deleteOnlyCompleted {
            showOnboardingHint = true
        }
        UserDefaults.standard.set(next.rawValue, forKey: tourStageKey)
    }

    private var shouldShowDeleteCallout: Bool {
        (tourStage == .done && showOnboardingHint) || tourStage == .deleteOnlyCompleted
    }

    private func advanceTourFromTap() {
        switch tourStage {
        case .addFromPlus:
            advanceTour(to: .longPressEdit)
        case .longPressEdit:
            advanceTour(to: .deleteOnlyCompleted)
        case .deleteOnlyCompleted:
            markOnboardingHintSeen()
            advanceTour(to: .done)
        case .done:
            break
        }
    }

    @ViewBuilder
    // 各ツアー/ヒントで共通の吹き出し
    private func calloutBubble(title: String, iconName: String, color: Color, arrowOffset: CGFloat, width: CGFloat? = nil) -> some View {
        VStack(alignment: .center, spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(color)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 30)
        .frame(width: width, alignment: .center)
        .background(
            SpeechBubble(cornerRadius: 30, arrowSize: CGSize(width: 16, height: 10), arrowOffset: arrowOffset)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            SpeechBubble(cornerRadius: 30, arrowSize: CGSize(width: 16, height: 10), arrowOffset: arrowOffset)
                .stroke(Color.gray.opacity(0.35), lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .allowsHitTesting(true)
    }
}

#Preview {
    ShoppingListView(listId: 0)
}

private enum TourStage: String {
    case addFromPlus
    case longPressEdit
    case deleteOnlyCompleted
    case done

    var message: String {
        switch self {
        case .addFromPlus:
            return TourCopy.addTitle
        case .longPressEdit:
            return TourCopy.editTitle
        case .deleteOnlyCompleted:
            return TourCopy.deleteTitle
        case .done:
            return ""
        }
    }
}

// ツアー文言を1か所に集約
private enum TourCopy {
    static let addTitle = "＋からアイテムを\n追加できます"
    static let editTitle = "アイテムを長押しすると編集できます"
    static let deleteTitle = "完了にした項目だけ\n削除できます"
}

// 吹き出し背景（上側に矢印）
private struct SpeechBubble: Shape {
    let cornerRadius: CGFloat
    let arrowSize: CGSize
    let arrowOffset: CGFloat

    func path(in rect: CGRect) -> Path {
        let arrowWidth = arrowSize.width
        let arrowHeight = arrowSize.height
        let minStart = rect.minX + arrowWidth / 2
        let arrowStartX = min(max(rect.minX + arrowOffset, minStart), rect.maxX - cornerRadius - arrowWidth)

        var path = Path()

        path.move(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY + arrowHeight))
        path.addLine(to: CGPoint(x: arrowStartX, y: rect.minY + arrowHeight))
        path.addLine(to: CGPoint(x: arrowStartX + arrowWidth / 2, y: rect.minY))
        path.addLine(to: CGPoint(x: arrowStartX + arrowWidth, y: rect.minY + arrowHeight))
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY + arrowHeight))

        path.addArc(center: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY + arrowHeight + cornerRadius),
                    radius: cornerRadius,
                    startAngle: .degrees(270),
                    endAngle: .degrees(0),
                    clockwise: false)

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
        path.addArc(center: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
                    radius: cornerRadius,
                    startAngle: .degrees(0),
                    endAngle: .degrees(90),
                    clockwise: false)

        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
                    radius: cornerRadius,
                    startAngle: .degrees(90),
                    endAngle: .degrees(180),
                    clockwise: false)

        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + arrowHeight + cornerRadius))
        path.addArc(center: CGPoint(x: rect.minX + cornerRadius, y: rect.minY + arrowHeight + cornerRadius),
                    radius: cornerRadius,
                    startAngle: .degrees(180),
                    endAngle: .degrees(270),
                    clockwise: false)

        path.closeSubpath()
        return path
    }
}
