import SwiftUI

// MARK: - 主宠物页面
struct MainPetView: View {
    @StateObject private var profileManager = UserProfileManager.shared
    @State private var currentPage = 0
    
    private let pages = ["宠物", "健康"]
    
    var body: some View {
        TabView(selection: $currentPage) {
            // 宠物页面
            PetPageView(userElement: profileManager.userProfile.fiveElements?.primary ?? "金")
                .tag(0)
            
            // 健康数据页面
            HealthDashboardPageView()
                .tag(1)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .automatic))
        .onAppear {
            profileManager.updateHealthStreak()
        }
    }
    

}





// MARK: - 预览
struct MainPetView_Previews: PreviewProvider {
    static var previews: some View {
        MainPetView()
    }
} 
