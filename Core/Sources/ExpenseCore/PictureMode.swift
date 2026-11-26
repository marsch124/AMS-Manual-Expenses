import Foundation

/// 1.34: "picture mode" — a launch word that starts the app with made-up sample expenses and
/// opens one chosen screen, so screenshots can be taken without taps and without real data.
/// This is only the reading of the launch words; the app does the rest (in-memory store,
/// invented names kept in memory, nothing written anywhere).
///   `-pictures`            sample data on
///   `-show <screen>`       with `-pictures`: open that screen at the start
public struct PictureMode: Equatable {
    public enum Screen: String, CaseIterable {
        case map, statistics, yesterday
        case thisWeek = "this-week"
        case lastWeek = "last-week"
    }

    /// Picture mode is on (`-pictures` was given).
    public let sample: Bool
    /// The screen to open; nil when none was asked for or the word is not one of the five.
    public let screen: Screen?

    /// `-show` alone does nothing: only `-pictures` turns picture mode on.
    public static func parse(_ arguments: [String]) -> PictureMode {
        guard arguments.contains("-pictures") else { return PictureMode(sample: false, screen: nil) }
        var screen: Screen?
        if let i = arguments.firstIndex(of: "-show"), i + 1 < arguments.count {
            screen = Screen(rawValue: arguments[i + 1])
        }
        return PictureMode(sample: true, screen: screen)
    }
}
