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
                        Label(
                            settings.listNames[index].isEmpty
                                ? "リスト\(index + 1)"
                                : settings.listNames[index],
                            systemImage: settings.iconForIndex(index)
                        )
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
