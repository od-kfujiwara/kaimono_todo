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

    init(listId: Int) {
        self.saveKey = "shopping_items_\(listId)"
        load()
        // 初回起動時はサンプルデータを表示
        if items.isEmpty {
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

    // UserDefaultsから読み込み
    func load() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([ShoppingItem].self, from: data) {
            items = decoded
        }
    }
}
