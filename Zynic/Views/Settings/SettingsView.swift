import SwiftUI

struct SettingsView: View {
    @AppStorage("zynic_username")     var username     = "Guest"
    @AppStorage("zynic_bio")          var bio          = ""
    @AppStorage("zynic_stream_qual")  var streamQuality = "High"
    @State private var showEQ = false
    @State private var editingName = false
    @State private var tempName = ""

    let qualities = ["Low (64kbps)", "Medium (128kbps)", "High (256kbps)"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                List {
                    // Profile
                    Section {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [.purple, .indigo],
                                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 60, height: 60)
                                Text(String((username.isEmpty ? "G" : username).prefix(1)).uppercased())
                                    .font(.system(size: 26, weight: .black))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                if editingName {
                                    TextField("Your name", text: $tempName)
                                        .font(.system(size: 17, weight: .bold))
                                        .onSubmit { username = tempName; editingName = false }
                                        .autocorrectionDisabled()
                                } else {
                                    Text(username)
                                        .font(.system(size: 17, weight: .bold))
                                }
                                Text(bio.isEmpty ? "Tap to add bio" : bio)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                            Button(editingName ? "Done" : "Edit") {
                                if editingName { username = tempName }
                                else           { tempName = username }
                                editingName.toggle()
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.purple)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(Color.white.opacity(0.05))

                        if editingName {
                            TextField("Bio / Status", text: $bio)
                                .font(.system(size: 14))
                                .listRowBackground(Color.white.opacity(0.05))
                        }
                    } header: {
                        Text("Profile").foregroundColor(.secondary)
                    }

                    // Audio
                    Section {
                        NavigationLink {
                            EqualizerView()
                        } label: {
                            Label("Equalizer", systemImage: "slider.vertical.3")
                        }
                        .listRowBackground(Color.white.opacity(0.05))

                        Picker("Stream Quality", selection: $streamQuality) {
                            ForEach(qualities, id: \.self) { Text($0) }
                        }
                        .tint(.purple)
                        .listRowBackground(Color.white.opacity(0.05))
                    } header: {
                        Text("Audio").foregroundColor(.secondary)
                    }

                    // About
                    Section {
                        HStack {
                            Label("Version", systemImage: "info.circle")
                            Spacer()
                            Text("1.0.0").foregroundColor(.secondary)
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                    } header: {
                        Text("About").foregroundColor(.secondary)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.black)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
