import Foundation
import SwiftUI
import ImageIO

// MARK: - GIF动画管理器
class GIFAnimationManager: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var currentImage: UIImage?
    @Published var currentGIFIndex: Int = 0
    
    private var gifImages: [UIImage] = []
    private var gifDurations: [TimeInterval] = []
    private var animationTimer: Timer?
    private var currentFrameIndex: Int = 0
    private var totalFrames: Int = 0
    
    init() {}
    
    // MARK: - 加载GIF动画
    func loadGIF(named gifName: String) {
        // 尝试从Bundle中的GIFs文件夹加载
        if let url = Bundle.main.url(forResource: gifName, withExtension: "gif") {
            print("✅ 从Bundle加载GIF文件: \(gifName)")
            loadGIFFromURL(url)
            return
        }
        
        // 尝试不带扩展名的方式加载
        let fileName = gifName.components(separatedBy: "/").last ?? gifName
        if let bundleURL = Bundle.main.url(forResource: fileName, withExtension: "gif") {
            print("✅ 从Bundle加载文件名: \(fileName)")
            loadGIFFromURL(bundleURL)
            return
        }
        
        // 尝试从Bundle中加载完整路径
        if let bundleURL = Bundle.main.url(forResource: gifName, withExtension: nil) {
            print("✅ 从Bundle加载完整路径: \(gifName)")
            loadGIFFromURL(bundleURL)
            return
        }
        
        // 尝试查找Bundle中的所有GIF文件进行调试
        print("❌ 无法找到GIF文件: \(gifName)")
        print("尝试过的路径:")
        print("  - Bundle: \(gifName).gif")
        print("  - Bundle FileName: \(fileName).gif")
        print("  - Bundle Full Path: \(gifName)")
        
        // 列出Bundle中的GIF文件用于调试
        if let bundlePath = Bundle.main.resourcePath {
            let fileManager = FileManager.default
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: bundlePath)
                let gifFiles = contents.filter { $0.hasSuffix(".gif") }
                print("Bundle中找到的GIF文件: \(gifFiles)")
                
                // 检查GIFs文件夹
                let gifsPath = "\(bundlePath)/GIFs"
                if fileManager.fileExists(atPath: gifsPath) {
                    let gifsContents = try fileManager.contentsOfDirectory(atPath: gifsPath)
                    print("GIFs文件夹内容: \(gifsContents)")
                }
            } catch {
                print("无法列出Bundle内容: \(error)")
            }
        }
        
        // 清空当前状态
        gifImages.removeAll()
        gifDurations.removeAll()
        totalFrames = 0
        currentImage = nil
    }
    
    // MARK: - 从URL加载GIF
    private func loadGIFFromURL(_ url: URL) {
        guard let data = try? Data(contentsOf: url),
              let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("无法解析GIF文件")
//            createDefaultAnimation()
            return
        }
        
        let frameCount = CGImageSourceGetCount(source)
        gifImages.removeAll()
        gifDurations.removeAll()
        
        for i in 0..<frameCount {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                let image = UIImage(cgImage: cgImage)
                gifImages.append(image)
                
                // 获取帧持续时间
                if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                   let gifInfo = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] {
                    
                    var duration: TimeInterval = 0.1 // 默认100ms
                    
                    if let delayTime = gifInfo[kCGImagePropertyGIFDelayTime as String] as? Double {
                        duration = delayTime
                    } else if let unclampedDelayTime = gifInfo[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double {
                        duration = unclampedDelayTime
                    }
                    
                    // 确保最小持续时间
                    if duration < 0.02 {
                        duration = 0.1
                    }
                    
                    gifDurations.append(duration)
                } else {
                    gifDurations.append(0.1)
                }
            }
        }
        
        totalFrames = gifImages.count
        
        if totalFrames > 0 {
            print("✅ 成功加载GIF，共\(totalFrames)帧")
            currentFrameIndex = 0
            currentImage = gifImages.first
        } else {
            print("❌ GIF文件没有有效帧")
            // 清空当前状态
            gifImages.removeAll()
            gifDurations.removeAll()
            totalFrames = 0
            currentImage = nil
        }
    }
    
    // MARK: - 创建默认动画 (已删除，不再使用)
    
    // MARK: - 播放动画
    func play() {
        guard totalFrames > 0 else { return }
        
        isPlaying = true
        animationTimer?.invalidate()
        
        playNextFrame()
    }
    
    // MARK: - 播放下一帧
    private func playNextFrame() {
        guard isPlaying, currentFrameIndex < gifDurations.count else { return }
        
        let duration = gifDurations[currentFrameIndex]
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.nextFrame()
        }
    }
    
    // MARK: - 下一帧
    private func nextFrame() {
        currentFrameIndex = (currentFrameIndex + 1) % totalFrames
        currentImage = gifImages[currentFrameIndex]
        
        if isPlaying {
            playNextFrame()
        }
    }
    
    // MARK: - 暂停动画
    func pause() {
        isPlaying = false
        animationTimer?.invalidate()
    }
    
    // MARK: - 停止动画
    func stop() {
        isPlaying = false
        animationTimer?.invalidate()
        currentFrameIndex = 0
        currentImage = gifImages.first
    }
    
    // MARK: - 跳转到指定帧
    func seekToFrame(_ frame: Int) {
        guard frame >= 0 && frame < totalFrames else { return }
        currentFrameIndex = frame
        currentImage = gifImages[currentFrameIndex]
    }
    
    // MARK: - 获取动画信息
    func getAnimationInfo() -> (totalFrames: Int, currentFrame: Int, averageDuration: TimeInterval)? {
        guard totalFrames > 0 else { return nil }
        
        let averageDuration = gifDurations.reduce(0, +) / Double(gifDurations.count)
        return (totalFrames: totalFrames, currentFrame: currentFrameIndex, averageDuration: averageDuration)
    }
    
    // MARK: - 获取进度
    func getProgress() -> Double {
        guard totalFrames > 0 else { return 0.0 }
        return Double(currentFrameIndex) / Double(totalFrames)
    }
    
    // MARK: - 获取可用GIF数量
    func getAvailableGIFCount() -> Int {
        return 1 // 目前只有1个GIF
    }
    
    // MARK: - 检查GIF文件是否存在
    func checkGIFFileExists(named gifName: String) -> Bool {
        return Bundle.main.url(forResource: gifName, withExtension: "gif") != nil
    }
} 
