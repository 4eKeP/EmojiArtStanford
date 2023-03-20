//
//  EmojiArtStanfordApp.swift
//  EmojiArtStanford
//
//  Created by admin on 19.03.2023.
//

import SwiftUI

@main
struct EmojiArtStanfordApp: App {
    let document =  EmojiArtDocument()
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentView(document: document)
        }
    }
}
