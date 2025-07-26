import Foundation
import AVFoundation

class AudioRecorderManager: NSObject, ObservableObject, AVAudioRecorderDelegate {
    static let shared = AudioRecorderManager()

    @Published var isRecording = false

    private var audioSession: AVAudioSession!
    private var audioRecorder: AVAudioRecorder!
    private var recordingURL: URL?

    override private init() {
        super.init()
        audioSession = AVAudioSession.sharedInstance()
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        switch audioSession.recordPermission {
        case .granted:
            completion(true)
        case .denied:
            completion(false)
        case .undetermined:
            audioSession.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        @unknown default:
            completion(false)
        }
    }

    func startRecording() {
        requestPermission { [weak self] granted in
            guard let self = self, granted else {
                print("Microphone permission denied.")
                return
            }

            DispatchQueue.main.async {
                do {
                    try self.audioSession.setCategory(.playAndRecord, mode: .default)
                    try self.audioSession.setActive(true)

                    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    self.recordingURL = documentsPath.appendingPathComponent("recording.m4a")

                    let settings = [
                        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                        AVSampleRateKey: 12000,
                        AVNumberOfChannelsKey: 1,
                        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                    ]

                    self.audioRecorder = try AVAudioRecorder(url: self.recordingURL!, settings: settings)
                    self.audioRecorder.delegate = self
                    self.audioRecorder.record()
                    self.isRecording = true
                    print("Started recording.")
                } catch {
                    print("Failed to start recording: \(error.localizedDescription)")
                    self.stopRecording()
                }
            }
        }
    }

    func stopRecording() -> URL? {
        DispatchQueue.main.async {
            self.audioRecorder?.stop()
            self.isRecording = false
            print("Stopped recording.")
        }

        do {
            try audioSession.setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }

        let urlToReturn = recordingURL
        recordingURL = nil
        audioRecorder = nil
        return urlToReturn
    }

    // MARK: - AVAudioRecorderDelegate

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            stopRecording()
            print("Recording finished unsuccessfully.")
        }
    }
}