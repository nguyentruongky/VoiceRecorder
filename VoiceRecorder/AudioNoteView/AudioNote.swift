import Foundation
import SwiftData

@Model
final class AudioNote {
    var id: UUID
    var title: String
    var duration: TimeInterval
    var createdAt: Date

    init(id: UUID = UUID(), title: String, duration: TimeInterval, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.duration = duration
        self.createdAt = createdAt
    }
}
