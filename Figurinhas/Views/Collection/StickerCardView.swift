import SwiftUI

struct StickerCardView: View {

    let sticker: StickerDef
    let count: Int
    let onTap: () -> Void
    let onLongPress: () -> Void

    // MARK: - State variants

    private var isMissing:   Bool { count == 0 }
    private var isOwned:     Bool { count == 1 }
    private var isDuplicate: Bool { count > 1  }

    private var bgColor: Color {
        if isMissing   { return Color(.systemGray5) }
        if isOwned     { return .teal }
        return .orange
    }

    private var fgColor: Color {
        isMissing ? Color(.label).opacity(0.35) : .white
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topTrailing) {
            cardContent
            if isDuplicate {
                duplicateBadge
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onLongPressGesture(minimumDuration: 0.45, perform: onLongPress)
        .animation(.spring(duration: 0.25), value: count)
    }

    // MARK: - Sub-views

    private var cardContent: some View {
        VStack(spacing: 1) {
            Text(sticker.code)
                .font(.system(size: 8, weight: .semibold, design: .rounded))
                .opacity(isMissing ? 0.5 : 0.85)

            Text(sticker.number)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .minimumScaleFactor(0.6)
        }
        .foregroundStyle(fgColor)
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(bgColor)
                .shadow(
                    color: bgColor.opacity(isMissing ? 0 : 0.45),
                    radius: 4, y: 2
                )
        )
    }

    private var duplicateBadge: some View {
        Text("×\(count)")
            .font(.system(size: 8, weight: .black))
            .foregroundStyle(.white)
            .padding(.horizontal, 3)
            .padding(.vertical, 1.5)
            .background(Capsule().fill(Color.black.opacity(0.35)))
            .padding(3)
    }
}
