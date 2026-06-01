import SwiftUI

struct ContentView: View {
    @ObservedObject var player  = AudioPlayerManager.shared
    @ObservedObject var colors  = ColorManager.shared
    @State private var selectedTab    = 0
    @State private var showFullPlayer = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Dynamic tinted tab view
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem { Label("Home",     systemImage: "house.fill")          }.tag(0)
                SearchView()
                    .tabItem { Label("Search",   systemImage: "magnifyingglass")     }.tag(1)
                ExploreView()
                    .tabItem { Label("Explore",  systemImage: "compass.drawing")     }.tag(2)
                ChartsView()
                    .tabItem { Label("Charts",   systemImage: "flame.fill")          }.tag(3)
                LibraryView()
                    .tabItem { Label("Library",  systemImage: "heart.fill")          }.tag(4)
                PetDenView()
                    .tabItem { Label("Pets",     systemImage: "pawprint.fill")       }.tag(5)
                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape.fill")      }.tag(6)
            }
            .tint(colors.accent)

            // Mini player with colour-matched bar
            if player.currentTrack != nil {
                MiniPlayerView(showFullPlayer: $showFullPlayer)
                    .padding(.bottom, 49)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal:   .move(edge: .bottom).combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: player.currentTrack != nil)
        .sheet(isPresented: $showFullPlayer) {
            FullPlayerView(isPresented: $showFullPlayer)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .preferredColorScheme(.dark)
        }
        .alert("Playback Error", isPresented: Binding(
            get: { player.errorMessage != nil },
            set: { if !$0 { player.errorMessage = nil } }
        )) {
            Button("OK") { player.errorMessage = nil }
        } message: {
            Text(player.errorMessage ?? "")
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Style the tab bar to be glass-like
            let tabBar = UITabBarAppearance()
            tabBar.configureWithTransparentBackground()
            tabBar.backgroundColor = UIColor.black.withAlphaComponent(0.85)
            tabBar.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
            UITabBar.appearance().standardAppearance = tabBar
            UITabBar.appearance().scrollEdgeAppearance = tabBar

            // Navigation bar
            let navBar = UINavigationBarAppearance()
            navBar.configureWithTransparentBackground()
            navBar.backgroundColor = .clear
            navBar.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            navBar.titleTextAttributes = [.foregroundColor: UIColor.white]
            UINavigationBar.appearance().standardAppearance = navBar
            UINavigationBar.appearance().scrollEdgeAppearance = navBar
        }
    }
}
