import Foundation

class TranscriptionAPIService: ObservableObject {
    static let shared = TranscriptionAPIService()

    private let apiKey = "sk-7qaHhZxF52d2va8ckALDvsXEtdjzpF0IL1Qy4B7KeLlvXFAx"
    private let transcriptionURL = URL(string: "http://118.89.199.50:8000/v1/audio/transcriptions")!

    @Published var transcribedText: String = ""
    @Published var isTranscribing = false
    @Published var errorMessage: String?

    private init() {}

    func transcribeAudio(fileURL: URL) {
        DispatchQueue.main.async {
            self.isTranscribing = true
            self.errorMessage = nil
            self.transcribedText = ""
        }

        var request = URLRequest(url: transcriptionURL)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        var data = Data()

        // Add file data
        do {
            let audioData = try Data(contentsOf: fileURL)
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
            data.append(audioData)
            data.append("\r\n".data(using: .utf8)!)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to read audio file: \(error.localizedDescription)"
                self.isTranscribing = false
            }
            return
        }

        // Add model parameter
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        data.append("step-asr".data(using: .utf8)!)
        data.append("\r\n".data(using: .utf8)!)

        data.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = data

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isTranscribing = false
                if let error = error {
                    self?.errorMessage = "API request failed: \(error.localizedDescription)"
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    self?.errorMessage = "Invalid server response."
                    return
                }

                guard let data = data else {
                    self?.errorMessage = "No data received from server."
                    return
                }

                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let text = jsonResponse["text"] as? String {
                        self?.transcribedText = text
                    } else {
                        self?.errorMessage = "Failed to parse transcription response."
                    }
                } catch {
                    self?.errorMessage = "Failed to decode JSON: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}