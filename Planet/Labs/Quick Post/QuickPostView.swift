//
//  QuickPostView.swift
//  Planet
//
//  Created by Xin Liu on 4/23/24.
//

import SwiftUI

struct QuickPostView: View {
    @StateObject private var viewModel: QuickPostViewModel
    @Environment(\.dismiss) private var dismiss

    init() {
        _viewModel = StateObject(wrappedValue: QuickPostViewModel.shared)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Upper: Avatar | Text Entry
            HStack {
                VStack {
                    if let planet = KeyboardShortcutHelper.shared.activeMyPlanet {
                        planet.avatarView(size: 40)
                            .help(planet.name)
                    }
                    Spacer()
                }
                .frame(width: 40)
                .padding(.top, 10)
                .padding(.bottom, 10)
                .padding(.leading, 10)
                .padding(.trailing, 0)

                TextEditor(text: $viewModel.content)
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .lineSpacing(4)
                    .disableAutocorrection(true)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                    .padding(.leading, 0)
                    .padding(.trailing, 10)
                    .frame(height: 160)
            }
            .background(Color(NSColor.textBackgroundColor))

            if viewModel.fileURLs.count > 0 {
                Divider()
                mediaTray()
                    .focusable()
                    .onPasteCommand(
                        of: [.fileURL, .image, .movie],
                        perform: QuickPostViewModel.shared.processPasteItems(_:)
                    )

            }

            Divider()

            HStack {
                Button {
                    do {
                        viewModel.allowedContentTypes = [.image]
                        viewModel.allowMultipleSelection = true
                        try attach()
                    }
                    catch {
                        debugPrint("failed to add attachment to Quick Post: \(error)")
                    }
                } label: {
                    Label("Add Image", systemImage: "photo.on.rectangle.angled")
                }
                Spacer()
                Button("Cancel", role: .cancel) {
                    viewModel.fileURLs = []
                    viewModel.content = ""
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle)

                Button {
                    // Save content as a new MyArticleModel
                    do {
                        try saveContent()
                    }
                    catch {
                        debugPrint("Failed to save quick post")
                    }
                    viewModel.content = ""
                    dismiss()
                } label: {
                    Text("Post")
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle)
            }.padding(10)
                .background(Color(NSColor.windowBackgroundColor))
        }.frame(width: 500, height: viewModel.fileURLs.count > 0 ? 310 : 200)
    }

    @ViewBuilder
    private func mediaTray() -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(viewModel.fileURLs, id: \.self) { url in
                    mediaItem(for: url)
                }
            }
        }
        .frame(height: 110)
        .frame(maxWidth: .infinity)
        .background(Color.secondary.opacity(0.03))
    }

    @ViewBuilder
    private func mediaItem(for url: URL) -> some View {
        VStack(spacing: 0) {
            Image(nsImage: NSImage(contentsOf: url) ?? NSImage())
                .interpolation(.high)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                .frame(width: 100, height: 80)
            Text(url.lastPathComponent)
                .font(.caption)
                .lineLimit(1)
                .frame(width: 100, height: 20)
                .truncationMode(.tail)
        }
        .padding(5)
        .background(Color.secondary.opacity(0.05))
        .contextMenu {
            Button {
                viewModel.fileURLs.removeAll { $0 == url }
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    private func extractTitle(from content: String) -> String {
        let content = content.trim()
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            if line.hasPrefix("# ") {
                return line.replacingOccurrences(of: "# ", with: "")
            }
        }
        return ""
    }

    private func extractContent(from content: String) -> String {
        let content = content.trim()
        let lines = content.components(separatedBy: .newlines)
        var result = ""
        var i = 0
        for line in lines {
            if i == 0 {
                if line.hasPrefix("# ") {
                    i += 1
                    continue
                }
                else {
                    result += "\(line)\n"
                }
            }
            else {
                result += "\(line)\n"
            }
            i += 1
        }
        return result.trim()
    }

    private func attach() throws {
        let panel = NSOpenPanel()
        panel.message = "Add Attachments"
        panel.prompt = "Add"
        panel.allowedContentTypes = viewModel.allowedContentTypes
        panel.allowsMultipleSelection = viewModel.allowMultipleSelection
        panel.canChooseDirectories = false
        panel.showsHiddenFiles = false
        let response = panel.runModal()
        guard response == .OK, panel.urls.count > 0 else { return }
        let urls = panel.urls
        try urls.forEach { url in
            viewModel.fileURLs.append(url)
        }
    }

    private func saveContent() throws {
        defer {
            viewModel.fileURLs = []
            viewModel.content = ""
        }
        // Save content as a new MyArticleModel
        guard let planet = KeyboardShortcutHelper.shared.activeMyPlanet else { return }
        let date = Date()
        let content = viewModel.content.trim()
        let article: MyArticleModel = try MyArticleModel.compose(
            link: nil,
            date: date,
            title: extractTitle(from: content),
            content: extractContent(from: content),
            summary: nil,
            planet: planet
        )
        if viewModel.fileURLs.count > 0 {
            var attachments: [String] = []
            for url in viewModel.fileURLs {
                // Copy the file to MyArticleModel's publicBasePath
                let fileName = url.lastPathComponent
                let targetURL = article.publicBasePath.appendingPathComponent(fileName)
                try FileManager.default.copyItem(at: url, to: targetURL)
                attachments.append(fileName)
            }
            article.attachments = attachments
        } else {
            // No attachments
            article.attachments = []
        }
        // TODO: Support tags in Quick Post
        article.tags = [:]
        var articles = planet.articles
        articles?.append(article)
        articles?.sort(by: { MyArticleModel.reorder(a: $0, b: $1) })
        planet.articles = articles

        do {
            try article.save()
            try article.savePublic()
            try planet.copyTemplateAssets()
            planet.updated = Date()
            try planet.save()

            Task {
                try await planet.savePublic()
                try await planet.publish()
                Task(priority: .background) {
                    await article.prewarm()
                }
            }

            Task { @MainActor in
                PlanetStore.shared.selectedView = .myPlanet(planet)
                PlanetStore.shared.refreshSelectedArticles()
                // wrap it to delay the state change
                if planet.templateName == "Croptop" {
                    Task { @MainActor in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            // Croptop needs a delay here when it loads from the local gateway
                            if PlanetStore.shared.selectedArticle == article {
                                NotificationCenter.default.post(name: .loadArticle, object: nil)
                            }
                            else {
                                PlanetStore.shared.selectedArticle = article
                            }
                            Task(priority: .userInitiated) {
                                NotificationCenter.default.post(
                                    name: .scrollToArticle,
                                    object: article
                                )
                            }
                        }
                    }
                }
                else {
                    Task { @MainActor in
                        if PlanetStore.shared.selectedArticle == article {
                            NotificationCenter.default.post(name: .loadArticle, object: nil)
                        }
                        else {
                            PlanetStore.shared.selectedArticle = article
                        }
                        Task(priority: .userInitiated) {
                            NotificationCenter.default.post(name: .scrollToArticle, object: article)
                        }
                    }
                }
            }
        }
        catch {
            debugPrint("Failed to save quick post")
        }
    }
}

#Preview {
    QuickPostView()
}
