//
//  Init.swift
//  NuTrack
//
//  Created by Anthony Rojas on 3/10/25.
//

import UIKit

// Sets the app-wide theme to either "Light", "Dark", or "System"
// App theme persists across sessions
func setAppTheme(setting: Int) {
    UIApplication.shared.windows.forEach { window in
        switch setting {
        case 1:
            window.overrideUserInterfaceStyle = .light
        case 2:
            window.overrideUserInterfaceStyle = .dark
        default:
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
    
    UserDefaults.standard.set(setting, forKey: "appTheme")
}

// Gets the app theme stored in UserDefaults
func getAppTheme() -> Int {
    return UserDefaults.standard.integer(forKey: "appTheme")
}

// Any settings that should be initialized when the app becomes
// active should be put in here
func initAppSettings() {
    setAppTheme(setting: getAppTheme())
}
