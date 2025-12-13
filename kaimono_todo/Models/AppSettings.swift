import Foundation
import Combine

class AppSettings: ObservableObject {
    @Published var listCount: Int {
        didSet { save() }
    }

    @Published var listNames: [String] {
        didSet { save() }
    }

    private let listCountKey = "app_list_count"
    private let listNamesKey = "app_list_names"

    // デフォルトのアイコン配列
    let defaultIcons = ["cart", "basket", "bag", "list.bullet"]

    init() {
        // UserDefaults から読み込み
        let savedCount = UserDefaults.standard.integer(forKey: listCountKey)

        // 初回起動時はデフォルト値（3つ）
        self.listCount = savedCount == 0 ? 3 : savedCount

        if let savedNames = UserDefaults.standard.stringArray(forKey: listNamesKey) {
            self.listNames = savedNames
        } else {
            // デフォルトのリスト名
            self.listNames = ["リスト1", "リスト2", "リスト3", "リスト4"]
        }

        // listNames が足りない場合は補完
        while self.listNames.count < 4 {
            self.listNames.append("リスト\(self.listNames.count + 1)")
        }
    }

    private func save() {
        UserDefaults.standard.set(listCount, forKey: listCountKey)
        UserDefaults.standard.set(listNames, forKey: listNamesKey)
    }

    func iconForIndex(_ index: Int) -> String {
        return defaultIcons[index % defaultIcons.count]
    }
}
