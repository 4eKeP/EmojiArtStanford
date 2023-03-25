//
//  PaletteEditor.swift
//  EmojiArtStanford
//
//  Created by admin on 23.03.2023.
//

import SwiftUI

struct PaletteEditor: View {
    // @Binding c его помощью можно изменять данные в "источнике истины Palette"
    // @Binding нельзя задать значение через = так как оно береться из "источнике истины" места привязки
    // @Binding не может быть private
    @Binding var palette: Palette
    
    var body: some View {
        Form{
            nameSection
            addEmojiSection
            removeEmojiSection
        }
        .navigationTitle("Edit \(palette.name)")
        .frame(minWidth: 300, minHeight: 350)
    }
    var nameSection: some View {
        //разобраться с header и content так как последовательность (header:_, content_) в будущих версиях будет убрана
        Section("Name"){
            //$palette взаимодействет со значение через сам @Binding
            TextField("Name", text: $palette.name)
        }
    }
    
    @State private var emojiIsToAdd = ""
    
    var addEmojiSection: some View{
        Section("Add Emoji"){
            //для того что бы каждый раз когда вписываешь emoji он добавлялся, тоеть каждый раз когда изменяеться для этого есть модификатор View .onChange
            TextField("", text: $emojiIsToAdd)
            //примеры модификаторов
                //.textContentType(.addressCity)
                //.textInputAutocapitalization(.characters)
               // .keyboardType(.default)
                .onChange(of: emojiIsToAdd) { emojis in
                    addEmojis(emojis)
                }
        }
    }
    func addEmojis(_ emojis: String){
        withAnimation {
            palette.emojis = (emojis + palette.emojis)
                .filter {$0.isEmoji}
                .withNoRepeatedCharacters
        }
        
    }
    var removeEmojiSection: some View {
        Section("Remove Emoji") {
            let emojis = palette.emojis.withNoRepeatedCharacters.map {String($0)}
            //сделать emoji больше
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))]){
                ForEach(emojis, id: \.self){ emoji in
                    Text(emoji)
                        .onTapGesture {
                            withAnimation {
                                palette.emojis.removeAll(where: {String($0) == emoji})
                            }
                            //padding(10) временное решение разобраться позже
                        }.padding(10)
                }
            }
        }
    }
    
}

struct PaletteEditor_Previews: PreviewProvider {
    static var previews: some View {
        PaletteEditor(palette: .constant(PaletteStore(named: "Preview").palette(at: 0)))
            .previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/300.0/*@END_MENU_TOKEN@*/, height: 350))
    }
}
