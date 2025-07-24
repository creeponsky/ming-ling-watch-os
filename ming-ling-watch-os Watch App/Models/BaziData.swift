import Foundation

// MARK: - 八字数据模型
struct BaziData: Codable {
    let base_info: BaseInfo
    let bazi_info: BaziInfo
    let chenggu: ChengguInfo
    let wuxing: WuxingInfo
    let yinyuan: YinyuanInfo?
    let caiyun: CaiyunInfo?
    let sizhu: SizhuInfo?
    let mingyun: MingyunInfo?
    let sx: String
    let xz: String
    let xiyongshen: XiyongshenInfo
}

struct BaseInfo: Codable {
    let sex: String
    let name: String
    let gongli: String
    let nongli: String
    let qiyun: String
    let jiaoyun: String
    let zhengge: String
    let wuxing_xiji: String
}

struct BaziInfo: Codable {
    let kw: String
    let tg_cg_god: [String]
    let bazi: String
    let na_yin: String
}

struct ChengguInfo: Codable {
    let year_weight: String
    let month_weight: String
    let day_weight: String
    let hour_weight: String
    let total_weight: String
    let description: String
}

struct WuxingInfo: Codable {
    let detail_desc: String
    let simple_desc: String
    let simple_description: String
    let detail_description: String
}

struct YinyuanInfo: Codable {
    let sanshishu_yinyuan: String
}

struct CaiyunInfo: Codable {
    let sanshishu_caiyun: SanshishuCaiyun
}

struct SanshishuCaiyun: Codable {
    let simple_desc: String
    let detail_desc: String
}

struct SizhuInfo: Codable {
    let rizhu: String
}

struct MingyunInfo: Codable {
    let sanshishu_mingyun: String
}

struct XiyongshenInfo: Codable {
    let qiangruo: String
    let xiyongshen: String
    let jishen: String
    let xiyongshen_desc: String
    let jin_number: Int
    let mu_number: Int
    let shui_number: Int
    let huo_number: Int
    let tu_number: Int
    let tonglei: String
    let yilei: String
    let rizhu_tiangan: String
    let zidang: Int
    let yidang: Int
    let zidang_percent: String
    let yidang_percent: String
    let jin_score: Int
    let mu_score: Int
    let shui_score: Int
    let huo_score: Int
    let tu_score: Int
    let jin_score_percent: String
    let mu_score_percent: String
    let shui_score_percent: String
    let huo_score_percent: String
    let tu_score_percent: String
    let yinyang: String
} 