import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID
    var name: String
    var colorHex: String
    var createdAt: Date
    var ledger: Ledger?
    
    @Relationship
    var bills: [Bill]?
    
    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#5B7CFA",
        createdAt: Date = Date(),
        ledger: Ledger? = nil
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.ledger = ledger
    }
}