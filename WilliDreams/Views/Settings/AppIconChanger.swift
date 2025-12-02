//
//  AppIconChanger.swift
//  WilliDreams
//
//  Created by William Gallegos on 7/25/24.
//

import SwiftUI

#if os(iOS)
struct AppIconChanger: View {
    @StateObject var viewModel = ChangeAppIconViewModel()
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            ContainerRelativeShape()
                .foregroundStyle(Color.background)
                .ignoresSafeArea()
            VStack {
                ScrollView {
                    ForEach(AppIcon.allCases) { appIcon in
                        Button(action: {
                            withAnimation {
                                    viewModel.updateAppIcon(to: appIcon)
                            }
                        }, label: {
                            HStack {
                                Image(appIcon.preview)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 60, height: 60)
                                    .clipShape(.rect(cornerRadius: 12))
                                Text(appIcon.iconName ?? "Default")
                                    .foregroundStyle(Color.textColorSet)
                                    .padding()
                                Spacer()
                                if viewModel.selectedAppIcon == appIcon {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                        })
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 20)
                                .foregroundStyle(.gray.opacity(0.2))
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Select an icon")
        }
    }
}

prefix func ! (value: Binding<Bool>) -> Binding<Bool> {
    Binding<Bool>(
        get: { !value.wrappedValue },
        set: { value.wrappedValue = !$0 }
    )
}

enum AppIcon: String, CaseIterable, Identifiable {
    case standard = "App Icon"
    case red = "RedIcon"
    case orange = "OrangeIcon"
    case yellow = "YellowIcon"
    case green = "GreenIcon"
    case teal = "TealIcon"
    case cyan = "CyanIcon"
    case navyBlue = "NavyBlueIcon"
    case purple = "PurpleIcon"
    case pink = "PinkIcon"
    case white = "WhiteIcon"
    case black = "BlackIcon"
    
    var id: String { rawValue }
    var iconName: String? {
        switch self {
        case .standard:
            return nil
        case .red:
            return "Red"
        case .orange:
            return "Orange"
        case .yellow:
            return "Yellow"
        case .green:
            return "Green"
        case .teal:
            return "Teal"
        case .cyan:
            return "Cyan"
        case .navyBlue:
            return "Navy Blue"
        case .purple:
            return "Purple"
        case .pink:
            return "Pink"
        case .white:
            return "White"
        case .black:
            return "Black"
        }
    }
    
    var preview: String {
        "\(rawValue)Preview"
    }
}

@MainActor
final class ChangeAppIconViewModel: ObservableObject {
    
    
    @Published private(set) var selectedAppIcon: AppIcon
    
    init() {
        if let iconName = UIApplication.shared.alternateIconName, let appIcon = AppIcon(rawValue: iconName) {
            selectedAppIcon = appIcon
        } else {
            selectedAppIcon = .standard
        }
    }
    
    @MainActor
    func updateAppIcon(to icon: AppIcon) {
        let previousAppIcon = selectedAppIcon
        selectedAppIcon = icon
        
        Task {
            let iconName = icon.rawValue
            if UIApplication.shared.alternateIconName != iconName {
                do {
                    if iconName != "App Icon" {
                        //if Date.now > Date(timeIntervalSince1970: 1709708400) {
                        try await UIApplication.shared.setAlternateIconName(iconName)
                        //}
                    } else {
                        try await UIApplication.shared.setAlternateIconName(nil)
                    }
                } catch {
                    /// Log the error with details.
                    print("Updating icon to \(iconName) failed with error: \(error)")
                    
                    /// Restore the previous app icon
                    selectedAppIcon = previousAppIcon
                }
            }
            // No need to update since we're already using this icon.
        }
    }
}

#Preview {
    AppIconChanger()
}
#endif
