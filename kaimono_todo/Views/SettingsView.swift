import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("リストの数")) {
                    Picker("リストの数", selection: $settings.listCount) {
                        ForEach(1...4, id: \.self) { count in
                            Text("\(count)個").tag(count)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("リスト名")) {
                    ForEach(0..<settings.listCount, id: \.self) { index in
                        HStack {
                            Image(systemName: settings.iconForIndex(index))
                                .frame(width: 30)
                            TextField("リスト\(index + 1)", text: Binding(
                                get: { settings.listNames[index] },
                                set: { newValue in
                                    // 文字数制限（20文字）
                                    let limited = String(newValue.prefix(20))
                                    settings.listNames[index] = limited
                                }
                            ))
                        }
                    }
                }

                Section {
                    Text("リストの数を減らしても、データは削除されません。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("設定")
        }
    }
}

#Preview {
    SettingsView(settings: AppSettings())
}
