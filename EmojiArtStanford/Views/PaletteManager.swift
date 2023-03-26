//
//  PaletteManager.swift
//  EmojiArtStanford
//
//  Created by admin on 25.03.2023.
//

import SwiftUI

struct PaletteManager: View {
    @EnvironmentObject var store: PaletteStore
    @Environment(\.isPresented) var isPresented
    @Environment(\.dismiss) var dismiss
  //  @Environment(\.colorScheme) var colorScheme
    @State private var editMode: EditMode = .inactive
    
    
    var body: some View {
        NavigationView {
            List{
                ForEach(store.palettes) { palette in
                    NavigationLink(destination: PaletteEditor(palette: $store.palettes[palette])){
                        VStack(alignment: .leading){
                            Text(palette.name)
                                //.font(editMode == .active ? .largeTitle : .caption)
                            Text(palette.emojis)
                        }
                       // для добавление дополнительных действий во время режима редактирования нельзя использовать .onTapGesture { } вместо этого использовать .gesture и созданную переменную например (tap)
                        .gesture(editMode == .active ? tap : nil)
                      //  .onTapGesture { }
                    }
                }
                .onDelete{ indexSet in
                    store.palettes.remove(atOffsets: indexSet)
                }
                .onMove { indexSet, newOffSet in
                    store.palettes.move(fromOffsets: indexSet, toOffset: newOffSet)
                }
            }
            .navigationTitle("Manage Palettes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem{ EditButton() }
                ToolbarItem(placement: .navigationBarLeading) {
                    if isPresented
                    //строка для ограничения платформ
                        //,
                    //    UIDevice.current.userInterfaceIdiom != .pad
                    {
                        Button("Close"){
                            dismiss()
                        }
                    }
                }
            }
            //@Environment значения можно применять непосредственно к определенным View
            .environment(\.editMode, $editMode)
        }
    }
    var tap: some Gesture{
        TapGesture().onEnded{ }
    }
}

struct PaletteManager_Previews: PreviewProvider {
    static var previews: some View {
        PaletteManager()
            .previewDevice("iPhone 14")
            .environmentObject(PaletteStore(named: "Preview"))
    }
}
