import SwiftUI
import NightarcCore

struct ContentView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var roleManager: RoleManager
    @StateObject private var addonRepo = AddonRepository.shared

    var body: some View {
        Group {
            if !profileManager.hasRestoredSession {
                SessionRestoreView()
            } else if profileManager.isAuthenticated {
                if profileManager.currentProfile != nil {
                    MainTabView()
                } else if !profileManager.profiles.isEmpty {
                    ProfilePickerScreen()
                } else {
                    CreateFirstProfileScreen()
                }
            } else {
                AuthScreen()
            }
        }
        .onChange(of: profileManager.currentProfile) { _, profile in
            roleManager.evaluateRole(profile: profile)
        }
    }
}

private struct SessionRestoreView: View {
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var wordmarkOpacity: Double = 0
    @State private var wordmarkOffset: CGFloat = 10
    @State private var progressWidth: CGFloat = 0
    @State private var orbitDegrees: Double = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            SplashStarField()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // App icon with rotating orbit ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        .frame(width: 110, height: 110)

                    Circle()
                        .fill(Color.white.opacity(0.55))
                        .frame(width: 6, height: 6)
                        .shadow(color: .white.opacity(0.9), radius: 4)
                        .offset(y: -55)
                        .rotationEffect(.degrees(orbitDegrees))

                    Image("luna-icon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .white.opacity(0.12), radius: 20)
                }
                .frame(width: 110, height: 110)
                .scaleEffect(iconScale)
                .opacity(iconOpacity)

                Text("Nightarc")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(wordmarkOpacity)
                    .offset(y: wordmarkOffset)
                    .padding(.top, 20)

                Spacer()
            }

            // Progress bar
            VStack {
                Spacer()
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 2)
                        Capsule()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: progressWidth * geo.size.width, height: 2)
                    }
                }
                .frame(height: 2)
                .padding(.horizontal, 32)
                .padding(.bottom, 54)
                .opacity(wordmarkOpacity)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                orbitDegrees = 360
            }
            withAnimation(.spring(response: 0.65, dampingFraction: 0.65).delay(0.2)) {
                iconScale = 1
                iconOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.55).delay(0.8)) {
                wordmarkOpacity = 1
                wordmarkOffset = 0
            }
            withAnimation(.easeInOut(duration: 2.8).delay(1.3)) {
                progressWidth = 0.72
            }
        }
    }
}

// TimelineView + Canvas = single draw call per frame, no per-star view overhead
private struct SplashStarField: View {
    struct Particle {
        let x: CGFloat      // normalized 0–1 horizontal
        let size: CGFloat   // diameter in points
        let opacity: Double // peak opacity
        let speed: CGFloat  // points per second (upward)
        let phase: CGFloat  // normalized 0–1 starting position in cycle
    }

    private let particles: [Particle] = (0..<38).map { _ in
        Particle(
            x:       .random(in: 0...1),
            size:    .random(in: 0.6...2.4),
            opacity: .random(in: 0.12...0.6),
            speed:   .random(in: 35...95),
            phase:   .random(in: 0...1)
        )
    }

    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                let now  = CGFloat(tl.date.timeIntervalSinceReferenceDate)
                let cycH = size.height + 20

                for p in particles {
                    let traveled = (now * p.speed + p.phase * cycH)
                        .truncatingRemainder(dividingBy: cycH)
                    let y    = cycH - traveled
                    let x    = p.x * size.width
                    let prog = y / cycH
                    let fade = min(prog / 0.08, (1 - prog) / 0.08, 1.0)

                    ctx.fill(
                        Path(ellipseIn: CGRect(
                            x: x - p.size / 2,
                            y: y - p.size / 2,
                            width:  p.size,
                            height: p.size
                        )),
                        with: .color(Color.white.opacity(p.opacity * fade))
                    )
                }
            }
        }
    }
}

private struct TabBarMinimizeModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            content
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var profileManager: ProfileManager
    @EnvironmentObject var roleManager: RoleManager
    @StateObject private var addonRepo = AddonRepository.shared

    @State private var selectedTab = 0
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if sizeClass == .regular {
            NavigationSplitView {
                List {
                    Button { selectedTab = 0 } label: {
                        Label("Home", systemImage: "house.fill")
                    }
                    Button { selectedTab = 1 } label: {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    Button { selectedTab = 2 } label: {
                        Label("Library", systemImage: "bookmark.fill")
                    }
                    Button { selectedTab = 3 } label: {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    if roleManager.isAdmin {
                        Button { selectedTab = 4 } label: {
                            Label("Admin", systemImage: "shield.fill")
                        }
                    }
                }
                .listStyle(.sidebar)
            } detail: {
                tabContent
            }
            .tint(.white)
            .task {
                if let profile = profileManager.currentProfile {
                    await addonRepo.loadAddons(profileId: profile.id)
                }
            }
            .onChange(of: profileManager.currentProfile) { _, newProfile in
                if let profile = newProfile {
                    Task {
                        await addonRepo.loadAddons(profileId: profile.id)
                    }
                }
            }
        } else {
            TabView(selection: $selectedTab) {
                Tab("Home", systemImage: "house.fill", value: 0) {
                    HomeScreen()
                }
                Tab("Search", systemImage: "magnifyingglass", value: 1) {
                    SearchScreen()
                }
                Tab("Library", systemImage: "bookmark.fill", value: 2) {
                    LibraryScreen()
                }
                Tab("Settings", systemImage: "gearshape.fill", value: 3) {
                    SettingsScreen()
                }
                if roleManager.isAdmin {
                    Tab("Admin", systemImage: "shield.fill", value: 4) {
                        AdminDashboard()
                    }
                }
            }
            .tint(.blue)
            .modifier(TabBarMinimizeModifier())
            .task {
                if let profile = profileManager.currentProfile {
                    await addonRepo.loadAddons(profileId: profile.id)
                }
            }
            .onChange(of: profileManager.currentProfile) { _, newProfile in
                if let profile = newProfile {
                    Task {
                        await addonRepo.loadAddons(profileId: profile.id)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0: HomeScreen()
        case 1: SearchScreen()
        case 2: LibraryScreen()
        case 3: SettingsScreen()
        case 4: AdminDashboard()
        default: HomeScreen()
        }
    }
}
