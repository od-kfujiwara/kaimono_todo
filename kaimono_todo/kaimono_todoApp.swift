import SwiftUI

@main
struct kaimono_todoApp: App {
    @StateObject private var settings = AppSettings()

    var body: some Scene {
        WindowGroup {
            ContentView(settings: settings)
        }
    }
}

struct ContentView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        TabView {
            // 動的にリストタブを生成
            ForEach(0..<settings.listCount, id: \.self) { index in
                ShoppingListView(listId: index)
                    .tabItem {
                        Label {
                            Text(tabTitle(for: index))
                        } icon: {
                            Image(systemName: settings.iconForIndex(index))
                        }
                    }
                    .tag(index)
            }

            // 設定タブ（一番右）
            SettingsView(settings: settings)
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
                .tag(999)
        }
    }
}

#Preview {
    ContentView(settings: AppSettings())
}

extension ContentView {
    // タブのタイトルは一定文字数で省略し、タブ幅が揃うようにする
    private func tabTitle(for index: Int) -> String {
        let base = settings.listNames[index].isEmpty
            ? "リスト\(index + 1)"
            : settings.listNames[index]

        let limit = 8
        if base.count > limit {
            let endIndex = base.index(base.startIndex, offsetBy: max(limit - 3, 1))
            return String(base[..<endIndex]) + "..."
        }
        return base
    }
}
