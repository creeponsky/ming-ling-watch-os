//
//  ImageGenerationAPIService.swift
//  ming-ling-watch-os Watch App
//
//  Created by Roo on 2025/7/26.
//

import Foundation
import SwiftUI

/// 用于与图像生成API交互的服务。
class ImageGenerationAPIService {

    /// 图像生成请求的有效负载。
    struct ImageGenerationPayload: Codable {
        let model: String
        let imageUrl: String

        enum CodingKeys: String, CodingKey {
            case model
            case imageUrl = "image_url"
        }
    }

    /// 从API获取生成的图像。
    /// - Parameter completion: 一个在请求完成后调用的闭包，包含图像数据或错误信息。
    func generateImage(completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: "https://api-inference.modelscope.cn/v1/images/generations") else {
            completion(.failure(NSError(domain: "ImageGenerationAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // 重要提示：请使用安全的方式存储和访问API密钥，而不是硬编码。
        request.setValue("Bearer ms-2e23de22-1359-4049-a18a-d14879144f0d", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ImageGenerationPayload(
            model: "black-forest-1abs/FLUX.1-Kontext-dev",
            imageUrl: "https://resources.modelscope.cn/aigc/image_edit.png"
        )

        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            completion(.failure(error))
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // 确保在主线程上调用完成处理程序
            let completionOnMain = { (result: Result<Data, Error>) in
                DispatchQueue.main.async {
                    completion(result)
                }
            }

            if let error = error {
                completionOnMain(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                let serverError = NSError(domain: "ImageGenerationAPI", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "服务器返回状态码 \(statusCode)"])
                completionOnMain(.failure(serverError))
                return
            }

            guard let data = data, !data.isEmpty else {
                let noDataError = NSError(domain: "ImageGenerationAPI", code: -2, userInfo: [NSLocalizedDescriptionKey: "未收到数据"])
                completionOnMain(.failure(noDataError))
                return
            }

            completionOnMain(.success(data))
        }
        task.resume()
    }
}