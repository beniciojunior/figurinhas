import SwiftUI

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

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 5)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {

                    statsBanner
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .padding(.bottom, 6)

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
        }
    }

    // MARK: - Stats banner

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
        let stickersToShow = country.stickers.filter { passes(sticker: $0) }

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
        let c = collection.count(for: sticker.id)
        switch filter {
        case .none:       return true
        case .owned:      return c >= 1
        case .duplicates: return c > 1
        case .missing:    return c == 0
        }
    }

    private func visibleSections(in group: StickerGroup) -> [CountrySection] {
        guard filter != .none else { return group.sections }
        return group.sections.filter { country in
            country.stickers.contains { passes(sticker: $0) }
        }
    }

    private func ownedCount(_ group: StickerGroup) -> Int {
        group.sections.flatMap(\.stickers).filter { collection.count(for: $0.id) > 0 }.count
    }
}
