import SwiftUI

@main
struct kaimono_todoApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ShoppingListView(listId: 0)
                    .tabItem {
                        Label("リスト1", systemImage: "cart")
                    }

                ShoppingListView(listId: 1)
                    .tabItem {
                        Label("リスト2", systemImage: "basket")
                    }

                ShoppingListView(listId: 2)
                    .tabItem {
                        Label("リスト3", systemImage: "bag")
                    }

                ShoppingListView(listId: 3)
                    .tabItem {
                        Label("リスト4", systemImage: "list.bullet")
                    }
            }
        }
    }
}
