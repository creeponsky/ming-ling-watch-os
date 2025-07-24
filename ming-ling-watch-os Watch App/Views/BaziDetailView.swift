import SwiftUI

struct BaziDetailView: View {
    let baziData: BaziData
    let userElement: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 基本信息
                basicInfoSection
                
                // 八字信息
                baziInfoSection
                
                // 称骨信息
                chengguSection
                
                // 五行分析
                wuxingSection
                
                // 喜用神
                xiyongshenSection
                
                // 姻缘信息
                if let yinyuan = baziData.yinyuan {
                    yinyuanSection(yinyuan)
                }
                
                // 财运信息
                if let caiyun = baziData.caiyun {
                    caiyunSection(caiyun)
                }
                
                // 命运批示
                if let mingyun = baziData.mingyun {
                    mingyunSection(mingyun)
                }
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Bazi Analysis")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - 基本信息
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("基本信息")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(title: "姓名", value: baziData.base_info.name)
                InfoRow(title: "性别", value: baziData.base_info.sex)
                InfoRow(title: "公历", value: baziData.base_info.gongli)
                InfoRow(title: "农历", value: baziData.base_info.nongli)
                InfoRow(title: "起运", value: baziData.base_info.qiyun)
                InfoRow(title: "交运", value: baziData.base_info.jiaoyun)
                InfoRow(title: "正格", value: baziData.base_info.zhengge)
                InfoRow(title: "五行喜忌", value: baziData.base_info.wuxing_xiji)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
    }
    
    // MARK: - 八字信息
    private var baziInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("八字信息")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(title: "八字", value: baziData.bazi_info.bazi)
                InfoRow(title: "纳音", value: baziData.bazi_info.na_yin)
                InfoRow(title: "空亡", value: baziData.bazi_info.kw)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("十神:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    ForEach(Array(baziData.bazi_info.tg_cg_god.enumerated()), id: \.offset) { index, god in
                        HStack {
                            Text("•")
                                .foregroundColor(.blue)
                            Text("\(["年", "月", "日", "时"][index]): \(god)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
        )
    }
    
    // MARK: - 称骨信息
    private var chengguSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("称骨分析")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(title: "总重量", value: baziData.chenggu.total_weight)
                InfoRow(title: "年重量", value: baziData.chenggu.year_weight)
                InfoRow(title: "月重量", value: baziData.chenggu.month_weight)
                InfoRow(title: "日重量", value: baziData.chenggu.day_weight)
                InfoRow(title: "时重量", value: baziData.chenggu.hour_weight)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("描述:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text(baziData.chenggu.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    // MARK: - 五行分析
    private var wuxingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("五行分析")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(title: "简要描述", value: baziData.wuxing.simple_desc)
                InfoRow(title: "详细描述", value: baziData.wuxing.detail_desc)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("简要说明:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text(baziData.wuxing.simple_description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.1))
        )
    }
    
    // MARK: - 喜用神
    private var xiyongshenSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("喜用神")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(title: "强弱", value: baziData.xiyongshen.qiangruo)
                InfoRow(title: "喜用神", value: baziData.xiyongshen.xiyongshen)
                InfoRow(title: "忌神", value: baziData.xiyongshen.jishen)
                InfoRow(title: "同类", value: baziData.xiyongshen.tonglei)
                InfoRow(title: "异类", value: baziData.xiyongshen.yilei)
                InfoRow(title: "日主天干", value: baziData.xiyongshen.rizhu_tiangan)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("描述:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text(baziData.xiyongshen.xiyongshen_desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                // 五行统计
                VStack(alignment: .leading, spacing: 4) {
                    Text("五行统计:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 12) {
                        WuXingCountView(element: "金", count: baziData.xiyongshen.jin_number, score: baziData.xiyongshen.jin_score_percent)
                        WuXingCountView(element: "木", count: baziData.xiyongshen.mu_number, score: baziData.xiyongshen.mu_score_percent)
                        WuXingCountView(element: "水", count: baziData.xiyongshen.shui_number, score: baziData.xiyongshen.shui_score_percent)
                        WuXingCountView(element: "火", count: baziData.xiyongshen.huo_number, score: baziData.xiyongshen.huo_score_percent)
                        WuXingCountView(element: "土", count: baziData.xiyongshen.tu_number, score: baziData.xiyongshen.tu_score_percent)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
        )
    }
    
    // MARK: - 姻缘信息
    private func yinyuanSection(_ yinyuan: YinyuanInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("姻缘")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(yinyuan.sanshishu_yinyuan)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.pink.opacity(0.1))
        )
    }
    
    // MARK: - 财运信息
    private func caiyunSection(_ caiyun: CaiyunInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("财运")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(title: "简要", value: caiyun.sanshishu_caiyun.simple_desc)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("详细:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text(caiyun.sanshishu_caiyun.detail_desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
        )
    }
    
    // MARK: - 命运批示
    private func mingyunSection(_ mingyun: MingyunInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("命运")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(mingyun.sanshishu_mingyun)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.indigo.opacity(0.1))
        )
    }
}

// MARK: - 信息行视图
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - 五行统计视图
struct WuXingCountView: View {
    let element: String
    let count: Int
    let score: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(element)
                .font(.caption2)
                .fontWeight(.bold)
            
            Text("\(count)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(score)
                .font(.caption2)
                .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.1))
        )
    }
} 