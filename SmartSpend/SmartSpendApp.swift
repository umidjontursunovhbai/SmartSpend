//
//  SmartSpendApp.swift
//  SmartSpend
//
//  Created by Umidjon Tursunov on 23/08/2025.
//

import AppIntents
import SwiftUI

@main
struct SmartSpendApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    print("✅ App window appeared")
                    SmartSpendAppShortcuts.updateAppShortcutParameters()
                }
                .preferredColorScheme(.light)
        }
    }
}
