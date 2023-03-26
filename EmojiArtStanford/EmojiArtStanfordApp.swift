//
//  EmojiArtStanfordApp.swift
//  EmojiArtStanford
//
//  Created by admin on 19.03.2023.
//

import SwiftUI

@main
struct EmojiArtStanfordApp: App {
    //разобраться кто/что занчит
    //это обьявление 2х ViewModel
   // @StateObject var document =  EmojiArtDocument()
    @StateObject var paletteStore = PaletteStore(named: "Default")
    var body: some Scene {
        //код для старого способа сохранения
       // WindowGroup
        DocumentGroup(newDocument: {EmojiArtDocument()}) { config in
            EmojiArtDocumentView(document: config.document)
                .environmentObject(paletteStore)
        }
    }
}
