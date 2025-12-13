import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @FocusState private var focusedField: Int?

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
                            .focused($focusedField, equals: index)
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
            .safeAreaInset(edge: .bottom) {
                if focusedField != nil {
                    HStack {
                        Spacer()
                        Button("完了") {
                            focusedField = nil
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
        }
    }
}

#Preview {
    SettingsView(settings: AppSettings())
}
