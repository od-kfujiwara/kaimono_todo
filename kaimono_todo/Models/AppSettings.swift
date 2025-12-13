import Foundation
import Combine

class AppSettings: ObservableObject {
    @Published var listCount: Int {
        didSet { save() }
    }

    @Published var listNames: [String] {
        didSet { save() }
    }

    @Published var listIcons: [String] {
        didSet { save() }
    }

    @Published var hasSeenIconHint: Bool {
        didSet { save() }
    }

    private let listCountKey = "app_list_count"
    private let listNamesKey = "app_list_names"
    private let listIconsKey = "app_list_icons"
    private let iconHintSeenKey = "app_icon_hint_seen"

    // デフォルトのアイコン配列
    let defaultIcons = ["cart", "basket", "bag", "list.bullet"]

    // 利用可能なアイコン一覧
    let availableIcons = [
        "cart", "cart.fill",
        "basket", "basket.fill",
        "bag", "bag.fill",
        "list.bullet", "list.bullet.circle",
        "square.and.pencil", "note.text",
        "checkmark.circle", "checkmark.circle.fill",
        "star", "star.fill",
        "heart", "heart.fill"
    ]

    init() {
        // UserDefaults から読み込み
        let savedCount = UserDefaults.standard.integer(forKey: listCountKey)

        // 初回起動時はデフォルト値（3つ）
        let count = savedCount == 0 ? 3 : savedCount

        // listNames の読み込みと補完
        var names: [String]
        if let savedNames = UserDefaults.standard.stringArray(forKey: listNamesKey) {
            names = savedNames
        } else {
            // デフォルトのリスト名
            names = ["リスト1", "リスト2", "リスト3", "リスト4"]
        }

        // listNames が足りない場合は補完
        while names.count < 4 {
            names.append("リスト\(names.count + 1)")
        }

        // listIcons の読み込みと補完
        var icons: [String]
        if let savedIcons = UserDefaults.standard.stringArray(forKey: listIconsKey) {
            icons = savedIcons
        } else {
            // デフォルトのアイコン
            icons = ["cart", "basket", "bag", "list.bullet"]
        }

        // listIcons が足りない場合は補完
        while icons.count < 4 {
            let index = icons.count
            icons.append(defaultIcons[index % defaultIcons.count])
        }

        // 全てのプロパティを一度に初期化（didSet を避ける）
        self.listCount = count
        self.listNames = names
        self.listIcons = icons
        self.hasSeenIconHint = UserDefaults.standard.bool(forKey: iconHintSeenKey)
    }

    private func save() {
        UserDefaults.standard.set(listCount, forKey: listCountKey)
        UserDefaults.standard.set(listNames, forKey: listNamesKey)
        UserDefaults.standard.set(listIcons, forKey: listIconsKey)
        UserDefaults.standard.set(hasSeenIconHint, forKey: iconHintSeenKey)
    }

    func iconForIndex(_ index: Int) -> String {
        return listIcons[index % listIcons.count]
    }
}
