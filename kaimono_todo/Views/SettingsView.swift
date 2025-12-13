import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @FocusState private var focusedField: Int?
    @State private var iconPickerSelection: IconPickerSelection?
    @State private var showIconHint = false

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
                    if showIconHint {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "hand.tap")
                                .font(.title2)
                                .foregroundColor(.appAccent)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("アイコンをタップして変更できます")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Text("リストごとに好きなアイコンを選べます。")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.appAccent.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.appAccent.opacity(0.2), lineWidth: 1)
                        )
                        .cornerRadius(12)
                    }

                    ForEach(0..<settings.listCount, id: \.self) { index in
                        HStack {
                            // アイコン選択ボタン
                            Button {
                                if !settings.hasSeenIconHint {
                                    settings.hasSeenIconHint = true
                                    showIconHint = false
                                }
                                iconPickerSelection = IconPickerSelection(id: index)
                            } label: {
                                Image(systemName: settings.iconForIndex(index))
                                    .font(.system(size: 18, weight: .semibold))
                                    .frame(width: 36, height: 36)
                                    .background(Color.gray.opacity(0.12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                    .cornerRadius(10)
                            }
                            .buttonStyle(.plain)

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
                .onAppear {
                    if !settings.hasSeenIconHint {
                        showIconHint = true
                    }
                }

                Section {
                    Text("リストの数を減らしても、データは削除されません。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("設定")
            .sheet(item: $iconPickerSelection) { selection in
                IconPickerView(settings: settings, listIndex: selection.id)
                    .presentationDetents([.fraction(0.5), .large])
            }
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

private struct IconPickerSelection: Identifiable {
    let id: Int
}
