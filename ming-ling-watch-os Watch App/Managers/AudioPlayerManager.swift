import Foundation
import AVFoundation

class AudioPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = AudioPlayerManager()

    private var audioPlayer: AVAudioPlayer?
    private var completionHandler: (() -> Void)?

    @Published var isPlaying = false

    private override init() {
        super.init()
    }

    func playAudio(data: Data, completion: @escaping () -> Void) {
        self.completionHandler = completion
        do {
            // Configure the audio session
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            // Initialize the audio player
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.play()

            isPlaying = true
        } catch {
            print("Failed to play audio: \(error.localizedDescription)")
            isPlaying = false
            completion()
        }
    }

    func stop() {
        audioPlayer?.stop()
        isPlaying = false
    }

    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
        completionHandler?()
        completionHandler = nil
    }
}