//
//  StateManager.swift
//  PHP Monitor
//
//  Created by Nico Verbruggen on 11/07/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Cocoa

class App {
    
    static let shared = App()
    
    /**
     Whether the application is busy switching versions.
     */
    var busy: Bool = false
    
    /**
     The currently active version of PHP.
     */
    var currentVersion: PhpVersion? = nil
    
    /**
     All available versions of PHP.
     */
    var availablePhpVersions : [String] = []
    
    /**
     The timer that will periodically fetch the PHP version that is currently active.
     */
    var timer: Timer?
    
}
