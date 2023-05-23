//
//  AppContentDropDelegate.swift
//  PlanetLite
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers


class AppContentDropDelegate: DropDelegate {
    init() {
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .copy)
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        guard let _ = info.itemProviders(for: [.image]).first else { return false }
        return true
    }
    
    func performDrop(info: DropInfo) -> Bool {
        if PlanetStore.shared.isQuickSharing {
            return false
        }
        let providers = info.itemProviders(for: [.fileURL])
        let supportedExtensions = ["png", "jpeg", "gif", "tiff", "jpg", "heic", "webp"]
        Task {
            var urls: [URL] = []
            for provider in providers {
                if let item = try? await provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier),
                   let data = item as? Data,
                   let path = URL(dataRepresentation: data, relativeTo: nil),
                   supportedExtensions.contains(path.pathExtension.lowercased()) {
                    urls.append(path)
                }
            }
            if urls.count > 0 {
                await MainActor.run {
                    do {
                        try PlanetQuickShareViewModel.shared.prepareFiles(urls)
                        PlanetStore.shared.isQuickSharing = true
                    } catch {
                        let alert = NSAlert()
                        alert.messageText = "Failed to Create Post"
                        alert.informativeText = error.localizedDescription
                        alert.alertStyle = .warning
                        alert.addButton(withTitle: "OK")
                        alert.runModal()
                    }
                }
            }
        }
        return true
    }
}