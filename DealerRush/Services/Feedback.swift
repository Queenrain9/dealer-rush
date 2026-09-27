import AudioToolbox
import AVFoundation
import UIKit

enum Feedback {
    private static var players: [String: AVAudioPlayer] = [:]
    static func tap() { if UserDefaults.standard.object(forKey: "haptics") as? Bool ?? true { UISelectionFeedbackGenerator().selectionChanged() }; sound("tap") }
    static func answer(correct: Bool, combo: Int) {
        if UserDefaults.standard.object(forKey: "haptics") as? Bool ?? true {
            UINotificationFeedbackGenerator().notificationOccurred(correct ? .success : .error)
            if correct && combo > 0 && combo % 5 == 0 { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
        }
        sound(correct ? "correct" : "incorrect")
    }
    static func complete() { sound("complete"); if UserDefaults.standard.object(forKey: "haptics") as? Bool ?? true { UINotificationFeedbackGenerator().notificationOccurred(.success) } }
    private static func sound(_ name: String) {
        guard UserDefaults.standard.object(forKey: "sound") as? Bool ?? true,
              let url = Bundle.main.url(forResource: name, withExtension: "wav") else { return }
        if let player = try? AVAudioPlayer(contentsOf: url) { players[name] = player; player.play() }
    }
}
