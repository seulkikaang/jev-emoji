import SwiftUI

struct EmojiPickerView: View {
    @ObservedObject var model: EmojiPickerModel
    @FocusState private var searchFocused: Bool
    @State private var showingSettings = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            searchField
                .padding(.top, 20)

            if !model.isSearching {
                contextCard
                    .padding(.top, 18)
            }

            HStack(alignment: .firstTextBaseline) {
                Text(model.resultsTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.primary.opacity(0.84))
                Spacer()
                Text(model.isLoading ? "" : "\(model.recommendations.count)개")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 21)
            .padding(.bottom, 10)

            if model.isLoading {
                ProgressView().frame(maxWidth: .infinity).frame(height: 131)
            }

            LazyVGrid(columns: columns, spacing: 7) {
                ForEach(Array(model.recommendations.enumerated()), id: \.element.id) { index, item in
                    emojiButton(item, index: index)
                }
            }

            Spacer(minLength: 8)
            footer
        }
        .padding(.horizontal, 20)
        .padding(.top, 19)
        .padding(.bottom, 14)
        .frame(width: 376, height: 490)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            searchFocused = true
            model.onInsert = { NSApp.keyWindow?.close() }
        }
        .sheet(isPresented: $showingSettings) { JevSettingsView(model: model) }
        .onExitCommand { NSApp.keyWindow?.close() }
        .background {
            Button(action: {
                if let first = model.recommendations.first { model.insert(first.emoji) }
            }) { EmptyView() }
            .keyboardShortcut(.return, modifiers: [])
            .hidden()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 39, height: 39)
                Image(systemName: "face.smiling")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(Color.accentColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("JEV Emoji")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text("문장에 딱 맞는 이모지")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("⌥⌘E")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.primary.opacity(0.055), in: Capsule())
            Button { showingSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 27, height: 27)
                    .background(Color.primary.opacity(0.045), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Jev 연결 설정")
        }
    }

    private var searchField: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            TextField("기분, 상황, 문장을 검색해요", text: Binding(get: { model.query }, set: { model.updateQuery($0) }))
                .font(.system(size: 13))
                .textFieldStyle(.plain)
                .focused($searchFocused)
                .onSubmit {
                    if let first = model.recommendations.first { model.insert(first.emoji) }
                }
            if !model.query.isEmpty {
                Button {
                    model.recommendContext()
                    searchFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.04), lineWidth: 1)
        }
    }

    private var contextCard: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: model.canReadContext ? "text.quote" : "sparkle.magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 4) {
                Text(!model.canReadContext ? "문맥 추천 켜기" : model.context.isEmpty ? "문맥을 가져오지 못했어요" : "\(model.contextAppName)에서 읽은 문장")
                    .font(.system(size: 11, weight: .semibold))
                Text(model.contextMessage)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .help(model.contextMessage)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if !model.canReadContext {
                Button("권한 켜기") { model.requestAccessibilityAccess() }
                    .font(.system(size: 10, weight: .semibold))
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(Color.accentColor.opacity(0.065), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private func emojiButton(_ item: EmojiItem, index: Int) -> some View {
        Button {
            model.insert(item.emoji)
        } label: {
            VStack(spacing: 3) {
                Text(item.emoji)
                    .font(.system(size: 26))
                Text(item.name)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 62)
            .background(Color.primary.opacity(index == 0 ? 0.065 : 0.035),
                        in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
        .buttonStyle(.plain)
        .help("\(item.name) · 클릭하여 입력")
    }

    private var footer: some View {
        HStack(spacing: 5) {
            Image(systemName: "return")
                .font(.system(size: 9, weight: .semibold))
            Text("Enter 입력")
            Text("·")
            Text("Esc 닫기")
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.system(size: 9))
            Text("Jev · 문맥 최대 140자 전송")
        }
        .font(.system(size: 10, weight: .medium))
        .foregroundStyle(.tertiary)
        .padding(.top, 10)
        .overlay(alignment: .bottom) {
            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.red)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .offset(y: -27)
            }
        }
        .overlay(alignment: .top) { Rectangle().fill(Color.primary.opacity(0.07)).frame(height: 1) }
    }
}

private struct JevSettingsView: View {
    @ObservedObject var model: EmojiPickerModel
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = ""
    @State private var saveError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 9) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                Text("Jev 연결")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                Spacer()
                Button { dismiss() } label: { Image(systemName: "xmark") }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }

            Picker("연결 서비스", selection: Binding(get: { model.provider }, set: { value in
                apiKey = ""
                saveError = nil
                model.selectProvider(value)
            })) {
                ForEach(JevProvider.allCases) { provider in
                    Text(provider.name).tag(provider)
                }
            }

            Text("\(model.provider.name) 키로 문맥에 맞는 이모지를 고릅니다. 키는 이 Mac의 키체인에 보관됩니다.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Link("\(model.provider.name)에서 키 만들기 ↗", destination: model.provider.keyURL)
                .font(.system(size: 12, weight: .semibold))

            SecureField("\(model.provider.name) API key", text: $apiKey)
                .textFieldStyle(.roundedBorder)

            if let saveError {
                Text(saveError).font(.system(size: 11)).foregroundStyle(.red)
            }

            HStack {
                if model.isConfigured {
                    Button("키 삭제") {
                        model.removeAPIKey()
                        apiKey = ""
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Button("저장하고 연결") {
                    do {
                        try model.saveAPIKey(apiKey)
                        dismiss()
                    } catch {
                        saveError = error.localizedDescription
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Text("검색어와 최대 140자의 문맥, 이모지 후보가 \(model.provider.name)로 전송됩니다. 이용 요금과 접근 권한은 해당 서비스에서 확인해 주세요.")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(width: 350)
    }
}
