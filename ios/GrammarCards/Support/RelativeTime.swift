import Foundation

enum RelativeTime {
    /// "방금 전", "5분 전", "3시간 전", "2일 전", "1개월 전"
    static func korean(since date: Date, now: Date = .now) -> String {
        let seconds = max(0, now.timeIntervalSince(date))
        let minute = 60.0, hour = 3600.0, day = 86400.0
        switch seconds {
        case ..<minute: return "방금 전"
        case ..<hour: return "\(Int(seconds / minute))분 전"
        case ..<day: return "\(Int(seconds / hour))시간 전"
        case ..<(day * 30): return "\(Int(seconds / day))일 전"
        default: return "\(Int(seconds / (day * 30)))개월 전"
        }
    }
}
