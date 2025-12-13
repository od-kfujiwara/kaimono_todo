import Foundation
import Combine

// 買い物アイテムのデータモデル
struct ShoppingItem: Identifiable, Codable {
    let id: UUID
    var text: String
    var isCompleted: Bool

    init(id: UUID = UUID(), text: String = "", isCompleted: Bool = false) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
    }
}

// 買い物リストを管理するストア
class ShoppingListStore: ObservableObject {
    @Published var items: [ShoppingItem] = []
    private let saveKey: String
    private var saveWorkItem: DispatchWorkItem?

    init(listId: Int) {
        self.saveKey = "shopping_items_\(listId)"
        load()
        // 初回起動時、リスト1のみサンプルデータを表示
        if items.isEmpty && listId == 0 {
            items = [
                ShoppingItem(text: "牛乳"),
                ShoppingItem(text: "卵"),
                ShoppingItem(text: "パン")
            ]
            save()
        }
    }

    // UserDefaultsに保存
    func save() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }

    // 入力や並び替えで多発する保存をまとめて実行し、書き込み負荷を減らす
    func saveDebounced(delay: TimeInterval = 0.25) {
        saveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.save()
        }
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    // UserDefaultsから読み込み
    func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([ShoppingItem].self, from: data) {
            items = decoded
        }
    }
}
