import Foundation

// MARK: - 八字API服务
class BaziAPIService: ObservableObject {
    private let apiKey = "Ta8IUNfPIo9mfkRY0ey4HZJ0O"
    private let baseURL = "https://api.yuanfenju.com/index.php/v1/Bazi/cesuan"
    
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - API响应模型
    struct BaziResponse: Codable {
        let errcode: Int
        let errmsg: String
        let notice: String?
        let data: BaziData?
    }
    
    // MARK: - 获取五行属性
    func getFiveElements(birthday: Date, sex: Int) async throws -> (FiveElements, BaziData) {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        let calendar = Calendar.current
        let year = calendar.component(.year, from: birthday)
        let month = calendar.component(.month, from: birthday)
        let day = calendar.component(.day, from: birthday)
        let hour = calendar.component(.hour, from: birthday)
        let minute = calendar.component(.minute, from: birthday)
        
        let url = URL(string: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // 构建表单数据
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "name", value: "用户"),
            URLQueryItem(name: "sex", value: "\(sex)"),
            URLQueryItem(name: "type", value: "1"), // 公历
            URLQueryItem(name: "year", value: "\(year)"),
            URLQueryItem(name: "month", value: "\(month)"),
            URLQueryItem(name: "day", value: "\(day)"),
            URLQueryItem(name: "hours", value: "\(hour)"),
            URLQueryItem(name: "minute", value: "\(minute)"),
            URLQueryItem(name: "zhen", value: "2"), // 不考虑真太阳时
            URLQueryItem(name: "lang", value: "zh-cn")
        ]
        
        request.httpBody = components.query?.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let baziResponse = try JSONDecoder().decode(BaziResponse.self, from: data)
        
        guard baziResponse.errcode == 0, let baziData = baziResponse.data else {
            throw APIError.apiError(baziResponse.errmsg)
        }
        
        // 根据喜用神确定五行属性
        let primaryElement = determinePrimaryElement(xiyong: baziData.xiyongshen.xiyongshen)
        
        return (FiveElements.elements[primaryElement] ?? FiveElements.elements["金"]!, baziData)
    }
    
    // MARK: - 确定主属性
    private func determinePrimaryElement(xiyong: String) -> String {
        // 根据喜用神字符串判断主属性
        if xiyong.contains("金") {
            return "金"
        } else if xiyong.contains("木") {
            return "木"
        } else if xiyong.contains("水") {
            return "水"
        } else if xiyong.contains("火") {
            return "火"
        } else if xiyong.contains("土") {
            return "土"
        }
        
        // 默认返回金
        return "金"
    }
    
    // MARK: - 获取宠物推荐
    func getPetRecommendation(for element: String) -> PetRecommendation? {
        return PetRecommendation.recommendations[element]
    }
}

// MARK: - API错误
enum APIError: Error, LocalizedError {
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "服务器响应无效"
        case .httpError(let code):
            return "HTTP错误: \(code)"
        case .apiError(let message):
            return "API错误: \(message)"
        case .networkError:
            return "网络连接错误"
        }
    }
} 