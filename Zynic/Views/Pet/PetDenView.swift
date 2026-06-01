import SwiftUI

// MARK: - Models
struct PetEntry: Identifiable, Codable {
    var id: String { slug }
    var slug: String
    var displayName: String
    var kind: String?
    var spritesheetUrl: String
    var petJsonUrl: String
    var zipUrl: String?
}

struct PetManifest: Codable { var pets: [PetEntry]; var total: Int }

// MARK: - PetDenView
struct PetDenView: View {
    @ObservedObject var companion = CompanionStore.shared
    @State private var pets: [PetEntry] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var filterKind = "All"

    let kinds = ["All", "creature", "character", "robot"]
    let columns = [GridItem(.flexible(), spacing: 10),
                   GridItem(.flexible(), spacing: 10),
                   GridItem(.flexible(), spacing: 10)]

    var filtered: [PetEntry] {
        pets.filter {
            (filterKind == "All" || ($0.kind ?? "").lowercased() == filterKind) &&
            (searchText.isEmpty || $0.displayName.localizedCaseInsensitiveContains(searchText))
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Active companion banner
                    if let pet = companion.activePet {
                        ActiveCompanionBanner(pet: pet)
                            .padding(.horizontal).padding(.top, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Filters
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(kinds, id: \.self) { k in
                                Button(k == "All" ? "All" : k.capitalized) { filterKind = k }
                                    .font(.system(size: 13, weight: .semibold))
                                    .padding(.horizontal, 14).padding(.vertical, 7)
                                    .background(filterKind == k ? Color.purple : Color.white.opacity(0.08))
                                    .foregroundColor(filterKind == k ? .white : .secondary)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 10)

                    if isLoading {
                        Spacer()
                        VStack(spacing: 14) {
                            ProgressView().tint(.purple).scaleEffect(1.4)
                            Text("Loading pets…").foregroundColor(.secondary).font(.system(size: 13))
                        }
                        Spacer()
                    } else if filtered.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "pawprint.slash")
                                .font(.system(size: 44)).foregroundColor(.purple.opacity(0.4))
                            Text("No pets found").foregroundColor(.secondary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(filtered.prefix(300)) { pet in
                                    PetCard(pet: pet,
                                            isActive: companion.activePet?.slug == pet.slug) {
                                        withAnimation(.spring(response: 0.3)) {
                                            companion.setActive(
                                                companion.activePet?.slug == pet.slug ? nil : pet
                                            )
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.bottom, 140)
                        }
                    }
                }
            }
            .navigationTitle("Pet Den 🐾")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .searchable(text: $searchText, placement: .navigationBarDrawer,
                        prompt: "Search \(pets.count) pets…")
        }
        .task { await loadPets() }
    }

    private func loadPets() async {
        isLoading = true
        guard let url = URL(string: "\(BASE_URL)/api/petdex/manifest") else {
            isLoading = false; return
        }
        if let (data, _) = try? await URLSession.shared.data(from: url),
           let manifest = try? JSONDecoder().decode(PetManifest.self, from: data) {
            pets = manifest.pets
        }
        isLoading = false
    }
}

// MARK: - Pet card (clean single idle frame)
struct PetCard: View {
    let pet: PetEntry
    let isActive: Bool
    let onTap: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack(alignment: .bottomTrailing) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.04))

                        // Clean single frame, animates on active
                        if isActive {
                            AnimatedSpriteView(spritesheetUrl: pet.spritesheetUrl,
                                               anim: .idle, size: 84, fps: 6)
                        } else {
                            StaticSpriteView(spritesheetUrl: pet.spritesheetUrl,
                                             anim: .idle, frame: 0, size: 84)
                        }
                    }
                    .frame(height: 92)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isActive ? Color.purple : Color.white.opacity(0.08),
                                    lineWidth: isActive ? 2 : 1)
                    )
                    .scaleEffect(pressed ? 0.93 : 1.0)

                    if isActive {
                        ZStack {
                            Circle().fill(Color.purple).frame(width: 22, height: 22)
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .black)).foregroundColor(.white)
                        }
                        .offset(x: 4, y: 4)
                    }
                }

                Text(pet.displayName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isActive ? .purple : .white)
                    .lineLimit(1)

                if let kind = pet.kind {
                    Text(kind.capitalized).font(.system(size: 9)).foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25), value: pressed)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in pressed = true }
            .onEnded   { _ in pressed = false }
        )
    }
}

// MARK: - Active companion banner (animated)
struct ActiveCompanionBanner: View {
    let pet: PetEntry
    @ObservedObject var companion = CompanionStore.shared

    var body: some View {
        HStack(spacing: 14) {
            AnimatedSpriteView(spritesheetUrl: pet.spritesheetUrl,
                               anim: .idle, size: 56, fps: 6)
                .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 2) {
                Text("Active Companion").font(.system(size: 10)).foregroundColor(.secondary)
                Text(pet.displayName).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                Text((pet.kind ?? "unknown").capitalized).font(.system(size: 11)).foregroundColor(.purple)
            }
            Spacer()

            // Toggle floating visibility
            Button {
                companion.toggleFloating()
            } label: {
                Image(systemName: companion.showFloating ? "eye.fill" : "eye.slash.fill")
                    .font(.system(size: 16)).foregroundColor(.purple)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.purple.opacity(0.15)))
            }

            Button { withAnimation { companion.setActive(nil) } } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22)).foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.12))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.purple.opacity(0.35), lineWidth: 1))
        )
    }
}
