import Foundation

class SpeechAPIService: ObservableObject {
    static let shared = SpeechAPIService()

    @Published var audioData: Data?
    @Published var errorMessage: String? = nil
    @Published var isRequesting: Bool = false

    private init() {}

    func generateSpeech(text: String) {
        self.isRequesting = true
        self.errorMessage = nil
        self.audioData = nil

        guard let url = URL(string: "https://0-0.pro/v1/audio/speech") else {
            self.errorMessage = "Invalid URL"
            self.isRequesting = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer sk-7qaHhZxF52d2va8ckALDvsXEtdjzpF0IL1Qy4B7KeLlvXFAx", forHTTPHeaderField: "Authorization")

        let requestBody: [String: Any] = [
            "model": "speech-02-hd",
            "input": text,
            "voice": "ttv-voice-2025072518250625-MpUt9UZ9"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            self.errorMessage = "Failed to encode request body: \(error.localizedDescription)"
            self.isRequesting = false
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isRequesting = false

                if let error = error {
                    self.errorMessage = "Request failed: \(error.localizedDescription)"
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    self.errorMessage = "Invalid response from server"
                    return
                }

                guard let data = data else {
                    self.errorMessage = "No data received"
                    return
                }

                self.audioData = data
            }
        }.resume()
    }
}