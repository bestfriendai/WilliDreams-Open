//
//  Profile.swift
//  WilliStudy
//
//  Created by William Gallegos on 2/24/24.
//

import SwiftUI
import WilliKit

/// Deprecated: Use WilliProfile instead. This view is kept for backwards compatibility.
@available(*, deprecated, renamed: "WilliProfile", message: "Profile doesn't include the latest features.")
struct Profile: View {
    @State var userToShow: User

    var body: some View {
        // FIX: Simplified to just wrap WilliProfile, removed all dead code
        WilliProfile(user: userToShow)
    }
}
