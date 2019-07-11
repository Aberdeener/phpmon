//
//  ViewController.swift
//  phpmon
//
//  Created by Nico Verbruggen on 11/06/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Cocoa

class LogViewController: NSViewController, ShellDelegate {
    
    public static func show(delegate: NSWindowDelegate? = nil) {
        if (App.shared.windowController == nil) {
            let vc = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "logWindow") as! LogViewController
            Shell.shared.delegate = vc
            let window = NSWindow(contentViewController: vc)
            window.title = "Terminal Output"
            window.delegate = delegate
            App.shared.windowController = NSWindowController(window: window)
        }
        App.shared.windowController!.showWindow(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @IBOutlet var textView: NSTextView!
    
    public func appendHistoryItem(_ historyItem: ShellHistoryItem) {
        self.append(
            """
            ======
            @ \(historyItem.date.toString())
            ------
            $ \(historyItem.command)
            ------
            > \(historyItem.output)
            
            """
        )
    }
    
    public func append(_ text : String) {
        self.textView.textStorage?.append(
            NSAttributedString(
                string: text,
                attributes: [
                    NSAttributedString.Key.font: NSFont(name: "Menlo", size: 12.0)!
                ]
            )
        )
        self.textView.scrollToEndOfDocument(nil)
    }
    
    override func viewDidLoad() {
        self.textView.isEditable = false
        for entry in Shell.shared.history {
            self.appendHistoryItem(entry)
        }
    }
    
    func didCompleteCommand(historyItem: ShellHistoryItem) {
        self.appendHistoryItem(historyItem)
    }
    
    @IBAction func pressed(_ sender: Any) {
        self.view.window?.windowController?.close()
    }
    
    deinit {
        print("VC deallocated")
    }
}
