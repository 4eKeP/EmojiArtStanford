//
//  PaletteChooser.swift
//  EmojiArtStanford
//
//  Created by admin on 23.03.2023.
//

import SwiftUI

struct PaletteChooser: View {
    var emojiFontSize: CGFloat = 40
    var emojiFont: Font {.system(size: emojiFontSize)}
    
    @EnvironmentObject var store: PaletteStore
    
    @State private var chosenPaletteIndex = 0
    
    var body: some View {
        HStack{
            paletteControlButton
            body(for: store.palette(at: chosenPaletteIndex))
        }
        // .clipped() этот параметр добавлен что бы при rollTransition анимированные view не на кладывались друг на друга
        .clipped()
    }
    
    var paletteControlButton: some View{
        Button{
            withAnimation{
                chosenPaletteIndex = (chosenPaletteIndex + 1) % store.palettes.count
            }
        } label: {
            Image(systemName: "paintpalette")
        }
        .font(emojiFont)
        .contextMenu{contextMenu}
    }
    
    @ViewBuilder
    var contextMenu: some View {
        AnimatedActionButton(title: "Edit", systemImage: "pencil") {
            paletteToEdit = store.palette(at: chosenPaletteIndex)
           // editing = true
        }
        AnimatedActionButton(title: "New", systemImage: "plus") {
            store.insertPalette(named: "New", emojis: "", at: chosenPaletteIndex)
            paletteToEdit = store.palette(at: chosenPaletteIndex)
           // editing = true
        }
        AnimatedActionButton(title: "Delete", systemImage: "minus.circle") {
            //chosenPaletteIndex =, для того что бы при удалении последнего элемента в последовательности переходил на другу последовательность
            chosenPaletteIndex = store.removePalette(at: chosenPaletteIndex)
        }
        AnimatedActionButton(title: "Manager", systemImage: "slider.vertical.3") {
            managing = true
        }
        goToMenu
    }
    
    var goToMenu: some View {
        Menu{
            ForEach(store.palettes){ palette in
                AnimatedActionButton(title: palette.name) {
                    if let index = store.palettes.index(matching: palette) {
                        chosenPaletteIndex = index
                    }
                }
            }
        } label: {
            Label("Go to", systemImage: "text.insert")
        }
    }
    
    
    func body(for palette: Palette) -> some View {
        HStack {
            Text(palette.name)
            ScrollingViewEmojiView(emojis: palette.emojis)
                .font(emojiFont)
        }
        //что бы rollTransition работала надо сделать каждый palette уникальным для этого и добавляеться .id
        .id(palette.id)
        .transition(rollTransition)
        // 2 способа появления окна редактирования с помощью Bool и Optional, предпочтителен Optional
//        .popover(isPresented: $editing) {
//            PaletteEditor(palette: $store.palettes[chosenPaletteIndex])
//        }
        .popover(item: $paletteToEdit) { palette in
            // $ binding это get и set значение
            //palette в коллекции используеться как идентификатор, как работает palettes[palette] смотреть расшерение для rangeReplaceable collection в файле UtilityExtensions
            PaletteEditor(palette: $store.palettes[palette])
        }
        .sheet(isPresented: $managing) {
            PaletteManager()
        }
    }
    
   // @State private var editing = false
    @State private var managing = false
    @State private var paletteToEdit: Palette?
    
    var rollTransition: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .offset(x: 0, y: emojiFontSize),
            removal: .offset(x: 0, y: -emojiFontSize))
    }
}



struct ScrollingViewEmojiView: View {
    let emojis: String
    var body: some View{
        ScrollView(.horizontal){
            HStack{
                ForEach(emojis.withNoRepeatedCharacters.map{String($0)}, id: \.self) { emoji in
                    Text(emoji)
                        .onDrag {
                            NSItemProvider(object: emoji as NSString)
                        }
                }
            }
        }
    }
}
    
    struct PaletteChooser_Previews: PreviewProvider {
        static var previews: some View {
            PaletteChooser()
        }
    }
