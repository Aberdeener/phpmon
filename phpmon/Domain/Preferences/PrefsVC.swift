//
//  PrefsVC.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 30/03/2021.
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Cocoa
import HotKey
import Carbon

class PrefsVC: NSViewController {
    
    // MARK: - Window Identifier
    
    @IBOutlet weak var stackView: NSStackView!
    
    // MARK: - Display
    
    public static func create(delegate: NSWindowDelegate?) {
        let storyboard = NSStoryboard(name: "Main" , bundle : nil)
        
        let windowController = storyboard.instantiateController(
            withIdentifier: "preferencesWindow"
        ) as! PrefsWC
        
        windowController.window!.title = "prefs.title".localized
        windowController.window!.subtitle = "prefs.subtitle".localized
        windowController.window!.delegate = delegate
        windowController.window!.styleMask = [.titled, .closable, .miniaturizable]
        windowController.window!.delegate = windowController
        windowController.positionWindowInTopLeftCorner()
        
        App.shared.preferencesWindowController = windowController
    }
    
    public static func show(delegate: NSWindowDelegate? = nil) {
        if (App.shared.preferencesWindowController == nil) {
            Self.create(delegate: delegate)
        }
        
        App.shared.preferencesWindowController!.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        [
            CheckboxPreferenceView.make(
                sectionText: "prefs.dynamic_icon".localized,
                descriptionText: "prefs.dynamic_icon_desc".localized,
                checkboxText: "prefs.dynamic_icon_title".localized,
                preference: .shouldDisplayDynamicIcon,
                action: {
                    MainMenu.shared.refreshIcon()
                }
            ),
            CheckboxPreferenceView.make(
                sectionText: "",
                descriptionText: "prefs.display_full_php_version_desc".localized,
                checkboxText: "prefs.display_full_php_version".localized,
                preference: .fullPhpVersionDynamicIcon,
                action: {
                    MainMenu.shared.refreshIcon()
                    MainMenu.shared.update()
                }
            ),
            CheckboxPreferenceView.make(
                sectionText: "prefs.services".localized,
                descriptionText: "prefs.auto_restart_services_desc".localized,
                checkboxText: "prefs.auto_restart_services_title".localized,
                preference: .autoServiceRestartAfterExtensionToggle,
                action: {}
            ),
            /* DISABLED UNTIL VALET SWITCHING IS OK (see #34)
            CheckboxPreferenceView.make(
                sectionText: "",
                descriptionText: "prefs.use_internal_switcher_desc".localized,
                checkboxText: "prefs.use_internal_switcher".localized,
                preference: .useInternalSwitcher,
                action: {}
            ), */
            HotkeyPreferenceView.make(
                sectionText: "prefs.global_shortcut".localized,
                descriptionText: "prefs.shortcut_desc".localized,
                self
            )
        ].forEach({ self.stackView.addArrangedSubview($0) })
    }
    
    // MARK: - Listening for hotkey dleegate
    
    var listeningForHotkeyView: HotkeyPreferenceView? = nil
    
    override func viewWillDisappear() {
        if listeningForHotkeyView !== nil {
            listeningForHotkeyView = nil
        }
    }

    // MARK: - Deinitialization
    
    deinit {
        print("VC deallocated")
    }
}
