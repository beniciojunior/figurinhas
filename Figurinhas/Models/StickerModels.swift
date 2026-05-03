import SwiftUI

// MARK: - Core Types

struct StickerDef: Identifiable, Hashable {
    let id: String        // "MEX1", "FWC00", "CC1"
    let code: String      // "MEX", "FWC", "CC"
    let number: String    // "1", "00"

    var display: String { "\(code) \(number)" }

    init(code: String, number: String) {
        self.code = code
        self.number = number
        self.id = "\(code)\(number)"
    }
}

struct CountrySection: Identifiable {
    let id: String        // country code
    let name: String
    let code: String
    let stickers: [StickerDef]
}

struct StickerGroup: Identifiable {
    let id: String        // "A"–"L", "FWC", "CC"
    let title: String
    let accent: Color
    let sections: [CountrySection]

    var totalCount: Int { sections.reduce(0) { $0 + $1.stickers.count } }
}

// MARK: - All Data

enum StickerData {

    static let groups: [StickerGroup] = [fwc] + worldCup + [cc]

    static let allDefs: [StickerDef] = groups.flatMap { $0.sections.flatMap(\.stickers) }

    static let byID: [String: StickerDef] = Dictionary(uniqueKeysWithValues: allDefs.map { ($0.id, $0) })

    static let validIDs: Set<String> = Set(allDefs.map(\.id))

    // MARK: FWC
    static let fwc: StickerGroup = {
        let nums = ["00"] + (1...19).map(String.init)
        let defs = nums.map { StickerDef(code: "FWC", number: $0) }
        let section = CountrySection(id: "FWC", name: "FIFA World Cup History", code: "FWC", stickers: defs)
        return StickerGroup(id: "FWC", title: "FIFA World Cup History", accent: .yellow, sections: [section])
    }()

    // MARK: Coca-Cola
    static let cc: StickerGroup = {
        let defs = (1...14).map { StickerDef(code: "CC", number: String($0)) }
        let section = CountrySection(id: "CC", name: "Figurinhas Coca-Cola", code: "CC", stickers: defs)
        return StickerGroup(id: "CC", title: "Figurinhas da Coca-Cola", accent: .red, sections: [section])
    }()

    // MARK: World Cup Groups A–L
    static let worldCup: [StickerGroup] = [
        group("A", .orange, [
            ("México",           "MEX"),
            ("África do Sul",    "RSA"),
            ("Coréia do Sul",    "KOR"),
            ("Rep. Tcheca",      "CZE"),
        ]),
        group("B", .blue, [
            ("Canadá",           "CAN"),
            ("Bósnia",           "BIH"),
            ("Catar",            "QAT"),
            ("Suíça",            "SUI"),
        ]),
        group("C", .green, [
            ("Brasil",           "BRA"),
            ("Marrocos",         "MAR"),
            ("Haiti",            "HAI"),
            ("Escócia",          "SCO"),
        ]),
        group("D", .purple, [
            ("Estados Unidos",   "USA"),
            ("Paraguai",         "PAR"),
            ("Austrália",        "AUS"),
            ("Turquia",          "TUR"),
        ]),
        group("E", .pink, [
            ("Alemanha",         "GER"),
            ("Curaçao",          "CUW"),
            ("Costa do Marfim",  "CIV"),
            ("Equador",          "ECU"),
        ]),
        group("F", .teal, [
            ("Holanda",          "NED"),
            ("Japão",            "JPN"),
            ("Suécia",           "SWE"),
            ("Tunísia",          "TUN"),
        ]),
        group("G", .indigo, [
            ("Bélgica",          "BEL"),
            ("Egito",            "EGY"),
            ("Irã",              "IRN"),
            ("Nova Zelândia",    "NZL"),
        ]),
        group("H", Color(.systemBrown), [
            ("Espanha",          "ESP"),
            ("Cabo Verde",       "CPV"),
            ("Arábia Saudita",   "KSA"),
            ("Uruguai",          "URU"),
        ]),
        group("I", .cyan, [
            ("França",           "FRA"),
            ("Senegal",          "SEN"),
            ("Iraque",           "IRQ"),
            ("Noruega",          "NOR"),
        ]),
        group("J", Color(.systemMint), [
            ("Argentina",        "ARG"),
            ("Argélia",          "ALG"),
            ("Áustria",          "AUT"),
            ("Jordânia",         "JOR"),
        ]),
        group("K", Color(.systemOrange), [
            ("Portugal",         "POR"),
            ("Congo",            "COD"),
            ("Uzbequistão",      "UZB"),
            ("Colômbia",         "COL"),
        ]),
        group("L", Color(.systemBlue), [
            ("Inglaterra",       "ENG"),
            ("Croácia",          "CRO"),
            ("Gana",             "GHA"),
            ("Panamá",           "PAN"),
        ]),
    ]

    private static func group(
        _ id: String,
        _ accent: Color,
        _ countries: [(String, String)]
    ) -> StickerGroup {
        let sections = countries.map { name, code in
            CountrySection(
                id: code,
                name: name,
                code: code,
                stickers: (1...20).map { StickerDef(code: code, number: String($0)) }
            )
        }
        return StickerGroup(id: id, title: "Grupo \(id)", accent: accent, sections: sections)
    }
}
