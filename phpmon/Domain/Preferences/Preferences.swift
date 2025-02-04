//
//  Preferences.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation

enum PreferenceName: String {
    case wasLaunchedBefore = "launched_before"
    case shouldDisplayDynamicIcon = "use_dynamic_icon"
    case fullPhpVersionDynamicIcon = "full_php_in_menu_bar"
    case autoServiceRestartAfterExtensionToggle = "auto_restart_after_extension_toggle"
    case useInternalSwitcher = "use_phpmon_switcher"
    case globalHotkey = "global_hotkey"
}

class Preferences {
    
    // MARK: - Singleton
    
    static var shared = Preferences()
    
    var cachedPreferences: [PreferenceName: Any?]
    
    public init() {
        Preferences.handleFirstTimeLaunch()
        cachedPreferences = Self.cache()
    }
    
    // MARK: - First Time Run
    
    /**
     Note: macOS seems to cache plist values in memory as well as in files.
     You can find the persisted configuration file in: ~/Library/Preferences/com.nicoverbruggen.phpmon.plist
     
     To clear the cache, and get a first-run experience you may need to run:
     ```
     defaults delete com.nicoverbruggen.phpmon
     killall cfprefsd
     ```
     */
    static func handleFirstTimeLaunch() {
        UserDefaults.standard.register(defaults: [
            PreferenceName.shouldDisplayDynamicIcon.rawValue: true,
            PreferenceName.fullPhpVersionDynamicIcon.rawValue: false,
            PreferenceName.autoServiceRestartAfterExtensionToggle.rawValue: true,
            PreferenceName.useInternalSwitcher.rawValue: false
        ])
        
        if UserDefaults.standard.bool(forKey: PreferenceName.wasLaunchedBefore.rawValue) {
            return
        }
        print("Saving first-time preferences!")
        UserDefaults.standard.setValue(true, forKey: PreferenceName.wasLaunchedBefore.rawValue)
        UserDefaults.standard.synchronize()
    }
    
    // MARK: - API
    
    static var preferences: [PreferenceName: Any?] {
        return Self.shared.cachedPreferences
    }
    
    // MARK: - Internal Functionality
    
    static func cache() -> [PreferenceName: Any] {
        return [
            // Part 1: Always Booleans
            .shouldDisplayDynamicIcon: UserDefaults.standard.bool(forKey: PreferenceName.shouldDisplayDynamicIcon.rawValue) as Any,
            .fullPhpVersionDynamicIcon: UserDefaults.standard.bool(forKey: PreferenceName.fullPhpVersionDynamicIcon.rawValue) as Any,
            .autoServiceRestartAfterExtensionToggle: UserDefaults.standard.bool(forKey: PreferenceName.autoServiceRestartAfterExtensionToggle.rawValue) as Any,
            .useInternalSwitcher: UserDefaults.standard.bool(forKey: PreferenceName.useInternalSwitcher.rawValue) as Any,
            
            // Part 2: Always Strings
            .globalHotkey: UserDefaults.standard.string(forKey: PreferenceName.globalHotkey.rawValue) as Any,
        ]
    }
    
    static func update(_ preference: PreferenceName, value: Any?) {
        if (value == nil) {
            UserDefaults.standard.removeObject(forKey: preference.rawValue)
        } else {
            UserDefaults.standard.setValue(value, forKey: preference.rawValue)
        }
        UserDefaults.standard.synchronize()
        
        // Update the preferences cache in memory!
        Preferences.shared.cachedPreferences = Preferences.cache()
    }
    
}
