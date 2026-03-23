import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var typeRawValue: String

    var ledger: Ledger?

    var type: BillType {
        get { BillType(rawValue: typeRawValue) ?? .expense }
        set { typeRawValue = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "circle.fill",
        colorHex: String = "#007AFF",
        type: BillType = .expense
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.typeRawValue = type.rawValue
    }
}