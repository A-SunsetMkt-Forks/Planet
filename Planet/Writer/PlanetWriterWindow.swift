//
//  PlanetWriterWindow.swift
//  Planet
//
//  Created by Kai on 2/22/22.
//

import Cocoa
import SwiftUI


class PlanetWriterWindow: NSWindow {
    var draftPlanetID: UUID
    
    init(rect: NSRect, maskStyle style: NSWindow.StyleMask, backingType: NSWindow.BackingStoreType, deferMode flag: Bool, draftPlanetID id: UUID) {
        draftPlanetID = id
        super.init(contentRect: rect, styleMask: style, backing: backingType, defer: flag)
        self.titleVisibility = .visible
        self.isMovableByWindowBackground = true
        self.titlebarAppearsTransparent = true
        self.title = "Writer " + draftPlanetID.uuidString.prefix(4)
        self.delegate = self
        self.isReleasedWhenClosed = false
        
        DispatchQueue.main.async {
            PlanetStore.shared.activeWriterID = id
            PlanetStore.shared.writerIDs.insert(id)
        }
    }
}


extension PlanetWriterWindow: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        return true
    }

    func windowWillClose(_ notification: Notification) {
        NotificationCenter.default.post(name: .closeWriterWindow, object: draftPlanetID)
    }
}
