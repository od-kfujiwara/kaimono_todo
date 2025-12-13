import SwiftUI

struct IconPickerView: View {
    @ObservedObject var settings: AppSettings
    let listIndex: Int
    @Environment(\.dismiss) var dismiss

    let columns = [
        GridItem(.adaptive(minimum: 60))
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(settings.availableIcons, id: \.self) { icon in
                        Button {
                            settings.listIcons[listIndex] = icon
                            dismiss()
                        } label: {
                            VStack {
                                Image(systemName: icon)
                                    .font(.system(size: 30))
                                    .frame(width: 60, height: 60)
                                    .background(
                                        settings.listIcons[listIndex] == icon
                                            ? Color.appAccent.opacity(0.2)
                                            : Color.gray.opacity(0.1)
                                    )
                                    .cornerRadius(8)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("アイコンを選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    IconPickerView(settings: AppSettings(), listIndex: 0)
}
