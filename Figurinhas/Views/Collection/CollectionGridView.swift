import SwiftUI
import UIKit

// MARK: - Filter mode

private enum FilterMode: Equatable {
    case none
    case owned       // count >= 1
    case duplicates  // count > 1
    case missing     // count == 0
}

struct CollectionGridView: View {

    @EnvironmentObject private var collection: StickerCollection
    @State private var filter: FilterMode = .none
    @State private var searchText = ""
    @State private var showExportOptions = false
    @State private var sharePayload: SharePayload?
    @State private var showImportAlert = false
    @State private var importText = ""
    @State private var importResultMessage = ""
    @State private var showImportResult = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 5)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {

                    statsBanner
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .padding(.bottom, 6)
                    searchAndExportBar
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)

                    if filter != .none {
                        filterBanner
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    ForEach(StickerData.groups) { group in
                        let sections = visibleSections(in: group)
                        if !sections.isEmpty {
                            Section {
                                groupBody(group, sections: sections)
                            } header: {
                                groupHeader(group)
                            }
                        }
                    }
                }
                .animation(.spring(duration: 0.3), value: filter)
                .padding(.bottom, 24)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Coleção")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Importar") {
                        importText = ""
                        showImportAlert = true
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showExportOptions = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .confirmationDialog("Exportar figurinhas", isPresented: $showExportOptions, titleVisibility: .visible) {
                Button("Todas") {
                    sharePayload = SharePayload(text: buildExportText(mode: .allOwned))
                }
                Button("Repetidas") {
                    sharePayload = SharePayload(text: buildExportText(mode: .duplicatesOnly))
                }
                Button("Faltando") {
                    sharePayload = SharePayload(text: buildExportText(mode: .missingOnly))
                }
                Button("Cancelar", role: .cancel) {}
            }
            .sheet(item: $sharePayload) { payload in
                ShareSheet(items: [payload.text])
            }
            .alert("Importar figurinhas", isPresented: $showImportAlert) {
                TextField("Ex.: MEX 4, PAN 1, FWC 00", text: $importText)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                Button("Cancelar", role: .cancel) {}
                Button("Importar") {
                    importFromText(importText)
                }
            } message: {
                Text("Cole a lista no mesmo formato da exportação.")
            }
            .alert("Importação concluída", isPresented: $showImportResult) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importResultMessage)
            }
        }
    }

    // MARK: - Stats banner

    private var searchAndExportBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Buscar por país, sigla ou número", text: $searchText)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var statsBanner: some View {
        HStack(spacing: 10) {
            statChip(
                icon: "star.fill",
                value: collection.totalOwned,
                total: collection.totalAll,
                label: "Figurinhas",
                color: .teal,
                mode: .owned
            )
            statChip(
                icon: "doc.on.doc.fill",
                value: collection.totalExtra,
                total: nil,
                label: "Repetidas",
                color: .orange,
                mode: .duplicates
            )
            statChip(
                icon: "xmark.circle.fill",
                value: collection.totalAll - collection.totalOwned,
                total: nil,
                label: "Faltando",
                color: Color(.systemGray),
                mode: .missing
            )
        }
    }

    private func statChip(
        icon: String,
        value: Int,
        total: Int?,
        label: String,
        color: Color,
        mode: FilterMode
    ) -> some View {
        let isActive = filter == mode
        return Button {
            withAnimation { filter = isActive ? .none : mode }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isActive ? .white : color)

                Group {
                    if let total {
                        Text("\(value)").bold()
                        + Text("/\(total)").foregroundColor(isActive ? .white.opacity(0.7) : .secondary)
                    } else {
                        Text("\(value)").bold()
                    }
                }
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(isActive ? .white : .primary)

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(isActive ? .white.opacity(0.85) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isActive ? color : Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Filter banner

    private var filterBanner: some View {
        let (color, text): (Color, String) = {
            switch filter {
            case .owned:      return (.teal,              "Mostrando apenas adicionadas")
            case .duplicates: return (.orange,            "Mostrando apenas repetidas")
            case .missing:    return (Color(.systemGray), "Mostrando apenas faltando")
            case .none:       return (.orange,            "")
            }
        }()

        return HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .foregroundStyle(color)
            Text(text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
            Spacer()
            Button("Limpar") { withAnimation { filter = .none } }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Group header (sticky)

    private func groupHeader(_ group: StickerGroup) -> some View {
        HStack(spacing: 10) {
            Text(group.id)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(group.accent)

            Text(group.title.uppercased())
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(group.accent.opacity(0.75))

            Spacer()

            let owned = ownedCount(group)
            Text("\(owned)/\(group.totalCount)")
                .font(.system(size: 12, weight: .semibold, design: .rounded).monospacedDigit())
                .foregroundStyle(owned == group.totalCount ? group.accent : Color(.secondaryLabel))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(group.accent.opacity(0.10))
        .overlay(alignment: .bottom) {
            Rectangle().fill(group.accent.opacity(0.3)).frame(height: 1)
        }
    }

    // MARK: - Group body

    private func groupBody(_ group: StickerGroup, sections: [CountrySection]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(sections.enumerated()), id: \.element.id) { idx, country in
                countryRow(country, accent: group.accent)
                if idx < sections.count - 1 {
                    Divider().padding(.leading, 16)
                }
            }
        }
    }

    // MARK: - Country row

    private func countryRow(_ country: CountrySection, accent: Color) -> some View {
        let stickersToShow = country.stickers.filter { passes(sticker: $0, in: country) }

        return VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Text(country.code)
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(accent.opacity(0.85)))

                Text(country.name)
                    .font(.system(size: 13, weight: .semibold))

                Spacer()

                let owned = country.stickers.filter { collection.count(for: $0.id) > 0 }.count
                Text("\(owned)/\(country.stickers.count)")
                    .font(.system(size: 11, weight: .medium, design: .rounded).monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(stickersToShow) { sticker in
                    StickerCardView(
                        sticker: sticker,
                        count: collection.count(for: sticker.id),
                        onTap: { collection.add(sticker.id) },
                        onLongPress: { collection.remove(sticker.id) }
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Helpers

    private func passes(sticker: StickerDef) -> Bool {
        passes(sticker: sticker, in: nil)
    }

    private func passes(sticker: StickerDef, in country: CountrySection?) -> Bool {
        let c = collection.count(for: sticker.id)
        let filterMatch: Bool = switch filter {
        case .none:       true
        case .owned:      c >= 1
        case .duplicates: c > 1
        case .missing:    c == 0
        }

        guard filterMatch else { return false }
        return matchesSearch(sticker: sticker, country: country)
    }

    private func matchesSearch(sticker: StickerDef, country: CountrySection?) -> Bool {
        let q = normalizedSearch(searchText)
        guard !q.isEmpty else { return true }

        var bag = [
            sticker.code,
            sticker.number,
            sticker.display
        ]

        if let country {
            bag.append(country.name)
            bag.append(country.code)
        }

        return bag
            .map(normalizedSearch)
            .contains(where: { $0.contains(q) })
    }

    private func normalizedSearch(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: " ", with: "")
    }

    private func buildExportText(mode: ExportMode) -> String {
        let parts = StickerData.groups
            .flatMap(\.sections)
            .flatMap { section in
                section.stickers.compactMap { sticker -> String? in
                    let c = collection.count(for: sticker.id)
                    switch mode {
                    case .allOwned:
                        guard c > 0 else { return nil }
                    case .duplicatesOnly:
                        guard c > 1 else { return nil }
                    case .missingOnly:
                        guard c == 0 else { return nil }
                    }
                    return "\(sticker.code) \(sticker.number)"
                }
            }
        return parts.joined(separator: ", ")
    }

    private func importFromText(_ raw: String) {
        let parts = raw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() }
            .filter { !$0.isEmpty }

        var imported = 0
        var ignored = 0

        for part in parts {
            let tokens = part
                .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
                .map(String.init)

            guard tokens.count >= 2 else {
                ignored += 1
                continue
            }

            let code = tokens[0]
            let number = normalizeImportedNumber(tokens[1], for: code)
            let id = "\(code)\(number)"

            guard StickerData.validIDs.contains(id) else {
                ignored += 1
                continue
            }

            collection.add(id)
            imported += 1
        }

        importResultMessage = "Adicionadas: \(imported) • Ignoradas: \(ignored)"
        showImportResult = true
    }

    private func normalizeImportedNumber(_ numberRaw: String, for code: String) -> String {
        let digits = numberRaw.filter(\.isNumber)
        guard !digits.isEmpty else { return numberRaw }

        if code == "FWC" {
            if digits == "0" || digits == "00" { return "00" }
            return String(Int(digits) ?? 0)
        }

        return String(Int(digits) ?? 0)
    }

    private func hasVisibleStickers(_ country: CountrySection) -> Bool {
        country.stickers.contains { passes(sticker: $0, in: country) }
    }

    private func visibleSections(in group: StickerGroup) -> [CountrySection] {
        group.sections.filter { hasVisibleStickers($0) }
    }

    private func ownedCount(_ group: StickerGroup) -> Int {
        group.sections.flatMap(\.stickers).filter { collection.count(for: $0.id) > 0 }.count
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct SharePayload: Identifiable {
    let id = UUID()
    let text: String
}

private enum ExportMode {
    case allOwned
    case duplicatesOnly
    case missingOnly
}
