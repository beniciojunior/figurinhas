import SwiftUI

enum ScannerMode: String, CaseIterable {
    case add    = "Adicionar"
    case remove = "Remover"
}

struct StickerFoundSheet: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var collection: StickerCollection

    let stickerID: String
    let mode: ScannerMode
    /// Called after the user confirms add/remove (before dismiss).
    let onConfirm: () -> Void

    private var def: StickerDef? { StickerData.byID[stickerID] }
    private var count: Int       { collection.count(for: stickerID) }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            handle

            stickerCard
                .padding(.top, 20)

            ownershipLabel
                .padding(.top, 12)

            Spacer()

            actionButtons
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
        .presentationDetents([.fraction(0.52)])
        .presentationCornerRadius(28)
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Sub-views

    private var handle: some View {
        Capsule()
            .fill(Color(.tertiaryLabel))
            .frame(width: 38, height: 4)
            .padding(.top, 12)
    }

    private var stickerCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(cardColor)
                .frame(width: 110, height: 140)
                .shadow(color: cardColor.opacity(0.5), radius: 14, y: 6)

            VStack(spacing: 4) {
                Text(def?.code ?? "—")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                Text(def?.number ?? "")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
            }
        }
    }

    private var ownershipLabel: some View {
        VStack(spacing: 4) {
            Text(def?.display ?? stickerID)
                .font(.title3.bold())

            HStack(spacing: 5) {
                Image(systemName: count > 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(count > 0 ? .green : Color(.secondaryLabel))
                Text(ownershipText)
                    .foregroundStyle(count > 0 ? .primary : .secondary)
            }
            .font(.subheadline)
        }
    }

    private var ownershipText: String {
        switch count {
        case 0:  return "Você não tem esta figurinha"
        case 1:  return "Você tem 1 desta figurinha"
        default: return "Você tem \(count) desta figurinha"
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                onConfirm()
                dismiss()
            } label: {
                Label(
                    mode == .add ? "Adicionar à Coleção" : "Remover da Coleção",
                    systemImage: mode == .add ? "plus.circle.fill" : "minus.circle.fill"
                )
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(mode == .add ? Color.green : Color.red, in: RoundedRectangle(cornerRadius: 14))
            }

            Button { dismiss() } label: {
                Text("Voltar")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 14))
            }
            .foregroundStyle(.primary)
        }
    }

    private var cardColor: Color {
        if count == 0 { return .gray }
        if count == 1 { return .teal }
        return .orange
    }
}
