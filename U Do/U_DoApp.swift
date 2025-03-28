//
//  U_DoApp.swift
//  U Do
//
//  Created by yoyojun on 23/12/2024.
//

import SwiftUI

@main
@MainActor
struct U_DoApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class CustomWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}


class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusItem: NSStatusItem?
    var window = NSWindow()
    var timer: Timer?
    var currentTaskIndex = 0
    let taskViewModel = TaskViewModel()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let menuView = IntegratedMenuView(taskViewModel: taskViewModel)
        
        setupWindow(with: menuView)
        setupStatusItem()
        rotateTask()
        startTaskRotation()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateTaskRotation),
            name: NSNotification.Name("UpdateTaskRotation"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTasksUpdated),
            name: NSNotification.Name("UpdateMenu"),
            object: nil
        )
        
        
        
        window.hidesOnDeactivate = false
            
        // Add these window behavior flags
        window.collectionBehavior = [.transient, .ignoresCycle]
        
    }
    
    @objc private func handleTasksUpdated() {
            // Reset index when tasks are updated
            currentTaskIndex = 0
            rotateTask()
        }
    
    func setupWindow(with menuView: IntegratedMenuView) {
        let hostingView = NSHostingView(rootView: menuView)
        window = CustomWindow(
            contentRect: NSRect(x: 0, y: 0, width: 310, height: 400),
            styleMask: [.fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.contentView = hostingView
        window.backgroundColor = .clear // Changed to clear
        window.isMovable = true
        window.level = .floating
        window.hasShadow = true
        window.titleVisibility = .hidden
        window.isOpaque = false
        window.titlebarAppearsTransparent = true

        hostingView.wantsLayer = true
        hostingView.layer?.cornerRadius = 20
        hostingView.layer?.masksToBounds = true
      
        
        let monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.window.isVisible else { return }
            
            let clickLocation = event.locationInWindow
            let windowFrame = self.window.frame
            
            // Check if click is outside the window
            if !NSPointInRect(clickLocation, windowFrame) {
                self.window.orderOut(nil)
            }
        }
        
        // Store the monitor to prevent it from being deallocated
        objc_setAssociatedObject(window, "monitorKey", monitor, .OBJC_ASSOCIATION_RETAIN)
    }
    
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.action = #selector(MenuButtonToggle)
    }
    
    func startTaskRotation() {
        timer?.invalidate()
        
        let interval = SettingsViewModel.shared.timeSecond
        
        // Initial rotation when starting
        rotateTask()
        
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval), repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.rotateTask()
        }
    }
    
    @objc func updateTaskRotation() {
        startTaskRotation() // This will create a new timer with the updated interval
    }
    
    public func rotateTask() {
        // Get only visible tasks
        let visibleTasks = taskViewModel.tasks.filter { $0.isVisibleInMenubar }
        
        guard !visibleTasks.isEmpty else {
            statusItem?.button?.title = "📄"

            return
        }
        
        // Ensure currentTaskIndex is within bounds of visible tasks
        if currentTaskIndex >= visibleTasks.count {
            currentTaskIndex = 0
        }
        
        // Get the current visible task
        let task = visibleTasks[currentTaskIndex]
        
        // Update the status item with the task title
        if task.isHighPriority {
            statusItem?.button?.title = "\(SettingsViewModel.shared.priorityEmoji) \(task.title)"
        } else {
            statusItem?.button?.title = task.title
        }
        
        // Increment the index for next rotation
        currentTaskIndex = (currentTaskIndex + 1) % visibleTasks.count
    }

    
    @objc func MenuButtonToggle(sender: AnyObject) {
        if window.isVisible {
            window.orderOut(nil)
        } else {
            
            SettingsViewModel.shared.menuWindow = window
            
            // Position window below the status item
            if let button = statusItem?.button {
                let buttonFrame = button.window?.convertToScreen(button.frame) ?? .zero
                let windowFrame = window.frame
                let x = buttonFrame.minX - (windowFrame.width - buttonFrame.width) / 2
                let y = buttonFrame.minY - windowFrame.height + window.titlebarHeightAdjustment()
                
                // Ensure the window stays within screen bounds
                if let screen = NSScreen.main {
                    let screenFrame = screen.visibleFrame
                    let adjustedX = min(max(x, screenFrame.minX), screenFrame.maxX - windowFrame.width)
                    window.setFrameOrigin(NSPoint(x: adjustedX, y: y))
                }
                NSApplication.shared.activate(ignoringOtherApps: true)
                window.makeKeyAndOrderFront(nil)
                window.makeFirstResponder(window.contentView)
                
                
            }
        }
    }
}

extension NSWindow {
    func titlebarHeightAdjustment() -> CGFloat {
        guard let contentView = self.contentView else { return 0 }
        return self.frame.height - contentView.frame.height
    }
}
