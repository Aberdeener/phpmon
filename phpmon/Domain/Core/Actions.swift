//
//  Services.swift
//  PHP Monitor
//
//  Copyright © 2021 Nico Verbruggen. All rights reserved.
//

import Foundation
import AppKit

class Actions {
    
    // MARK: - Detect PHP Versions
    
    public static func detectPhpVersions() -> [String]
    {
        let files = Shell.pipe("ls \(Paths.optPath) | grep php@")
        var versionsOnly = Self.extractPhpVersions(from: files.components(separatedBy: "\n"))
        
        // Make sure the aliased version is detected
        // The user may have `php` installed, but not e.g. `php@8.0`
        // We should also detect that as a version that is installed
        let phpAlias = App.shared.brewPhpVersion
        
        // Avoid inserting a duplicate
        if (!versionsOnly.contains(phpAlias) && Shell.fileExists("\(Paths.optPath)/php/bin/php")) {
            versionsOnly.append(phpAlias);
        }
        
        print("The PHP versions that were detected are: \(versionsOnly)")
        
        App.shared.availablePhpVersions = versionsOnly
        Actions.extractPhpLongVersions()
        
        return versionsOnly
    }
    
    /**
     This method extracts the PHP full version number after finding the php installation folders.
     To be refactored at some later point, I'd like to cache the `PhpInstallation` objects instead of just the version number at some point.
     */
    public static func extractPhpLongVersions()
    {
        var mappedVersions: [String: PhpInstallation] = [:]
        App.shared.availablePhpVersions.forEach { version in
            mappedVersions[version] = PhpInstallation(version)
        }
        
        App.shared.cachedPhpInstallations = mappedVersions
    }
 
    /**
     Extracts valid PHP versions from an array of strings.
     This array of strings is usually retrieved from `grep`.
     */
    public static func extractPhpVersions(
        from versions: [String],
        checkBinaries: Bool = true
    ) -> [String] {
        var output : [String] = []
        
        versions.filter { (version) -> Bool in
            // Omit everything that doesn't start with php@
            // (e.g. something-php@8.0 won't be detected)
            return version.starts(with: "php@")
        }.forEach { (string) in
            let version = string.components(separatedBy: "php@")[1]
            // Only append the version if it doesn't already exist (avoid dupes),
            // is supported and where the binary exists (avoids broken installs)
            if !output.contains(version)
                && Constants.SupportedPhpVersions.contains(version)
                && (checkBinaries ? Shell.fileExists("\(Paths.optPath)/php@\(version)/bin/php") : true)
            {
                output.append(version)
            }
        }
        
        return output
    }
    
    // MARK: - Services
    
    public static func restartPhpFpm()
    {
        brew("services restart \(App.phpInstall!.formula)", sudo: true)
    }
    
    public static func restartNginx()
    {
        brew("services restart nginx", sudo: true)
    }
    
    public static func restartDnsMasq()
    {
        brew("services restart dnsmasq", sudo: true)
    }
    
    public static func stopAllServices()
    {
        brew("services stop \(App.phpInstall!.formula)", sudo: true)
        brew("services stop nginx", sudo: true)
        brew("services stop dnsmasq", sudo: true)
    }
    
    /**
     Kindly asks Valet to switch to a specific PHP version.
     */
    public static func switchToPhpVersionUsingValet(
        version: String,
        availableVersions: [String],
        completed: @escaping () -> Void
    ) {
        print("Switching to \(version) using Valet")
        print(valet("use php@\(version)"))
        completed()
    }
    
    /**
     Switching to a new PHP version involves:
     - unlinking the current version
     - stopping the active services
     - linking the new desired version
     
     Please note that depending on which version is installed,
     the version that is switched to may or may not be identical to `php` (without @version).
     */
    public static func switchToPhpVersion(
        version: String,
        availableVersions: [String],
        completed: @escaping () -> Void
    ) {
        print("Switching to \(version), unlinking all versions...")

        let group = DispatchGroup()
        
        availableVersions.forEach { (available) in
            group.enter()
            
            DispatchQueue.global(qos: .userInitiated).async {
                let formula = (available == App.shared.brewPhpVersion)
                    ? "php" : "php@\(available)"
                
                brew("unlink \(formula)")
                brew("services stop \(formula)", sudo: true)
                
                group.leave()
            }
        }
        
        group.notify(queue: .global(qos: .userInitiated)) {
            print("All versions have been unlinked!")
            print("Linking the new version!")
            
            let formula = (version == App.shared.brewPhpVersion) ? "php" : "php@\(version)"
            brew("link \(formula) --overwrite --force")
            brew("services start \(formula)", sudo: true)
            
            print("The new version has been linked!")
            completed()
        }
    }
    
    // MARK: - Finding Config Files
    
    public static func openGenericPhpConfigFolder()
    {
        let files = [NSURL(fileURLWithPath: "\(Paths.etcPath)/php")];
        NSWorkspace.shared.activateFileViewerSelecting(files as [URL])
    }
    
    public static func openGlobalComposerFolder()
    {
        let file = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".composer/composer.json")
        NSWorkspace.shared.activateFileViewerSelecting([file] as [URL])
    }
    
    public static func openPhpConfigFolder(version: String)
    {
        let files = [NSURL(fileURLWithPath: "\(Paths.etcPath)/php/\(version)/php.ini")];
        NSWorkspace.shared.activateFileViewerSelecting(files as [URL])
    }
    
    public static func openValetConfigFolder()
    {
        let file = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/valet")
        NSWorkspace.shared.activateFileViewerSelecting([file] as [URL])
    }
    
    // MARK: - Quick Fix
    
    /**
     Detects all currently available PHP versions,
     and unlinks each and every one of them.
     
     After this, the brew services are also stopped,
     the latest PHP version is linked, and php + nginx are restarted.
     
     If this does not solve the issue, the user may need to install additional
     extensions and/or run `composer global update`.
     */
    public static func fixMyPhp()
    {
        brew("services restart dnsmasq", sudo: true)
        
        detectPhpVersions().forEach { (version) in
            let formula = (version == App.shared.brewPhpVersion) ? "php" : "php@\(version)"
            brew("unlink php@\(version)")
            brew("services stop \(formula)")
            brew("services stop \(formula)", sudo: true)
        }
        
        brew("services stop php")
        brew("services stop nginx")
        brew("link php")
        brew("services restart dnsmasq", sudo: true)
        brew("services stop php", sudo: true)
        brew("services stop nginx", sudo: true)
    }
    
    // MARK: Common Shell Commands
    
    /**
     Runs a `valet` command.
     */
    public static func valet(_ command: String) -> String
    {
        return Shell.pipe("sudo \(Paths.valet) \(command)", requiresPath: true)
    }
    
    /**
     Runs a `brew` command. Can run as superuser.
     */
    public static func brew(_ command: String, sudo: Bool = false)
    {
        Shell.run("\(sudo ? "sudo " : "")" + "\(Paths.brew) \(command)")
    }
    
    /**
     Runs `sed` in order to replace all occurrences of a string in a specific file with another.
     */
    public static func sed(file: String, original: String, replacement: String)
    {
        // Escape slashes (or `sed` won't work)
        let e_original = original.replacingOccurrences(of: "/", with: "\\/")
        let e_replacement = replacement.replacingOccurrences(of: "/", with: "\\/")
        
        // Check if gsed exists; it is able to follow symlinks,
        // which we want to do to toggle the extension
        if Shell.fileExists("\(Paths.binPath)/gsed") {
            Shell.run("\(Paths.binPath)/gsed -i --follow-symlinks 's/\(e_original)/\(e_replacement)/g' \(file)")
        } else {
            Shell.run("sed -i '' 's/\(e_original)/\(e_replacement)/g' \(file)")
        }
    }
    
    /**
     Uses `grep` to determine whether a particular query string can be found in a particular file.
     */
    public static func grepContains(file: String, query: String) -> Bool
    {
        return Shell.pipe("""
            grep -q '\(query)' \(file); [ $? -eq 0 ] && echo "YES" || echo "NO"
            """)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .contains("YES")
    }
    
}
