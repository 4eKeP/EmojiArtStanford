//
//  EmojiArtDocument.swift
//  EmojiArtStanford
//
//  Created by admin on 19.03.2023.
//

import SwiftUI

class EmojiArtDocument: ObservableObject {
  
    @Published private(set) var emojiArt: EmojiArtModel {
        didSet{
            autosave()
            if emojiArt.background != oldValue.background{
                fetchBackgroundImageDataIfNecessary()
            }
        }
    }
    private var autosaveTimer: Timer?
    private func schedualeAutosave () {
        autosaveTimer?.invalidate()
        autosaveTimer = Timer.scheduledTimer(withTimeInterval: Autosave.coalescingInterval, repeats: false){ _ in
            //self здесь не помечаеться weak для того что бы сохранение все таки произашло 
            self.autosave()
        }
    }
    private struct Autosave {
        static let filename = "Autosave.emojiart"
        static var url: URL? {
            // на ios всегда используеться .userDomainMask другие дериктории как правило для мак
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            //возвращаем комбинацию documentDirectory и filename
            return documentDirectory?.appendingPathComponent(filename)
        }
        static let coalescingInterval = 5.0
    }
    
    private func autosave() {
        if let url = Autosave.url {
            save(to: url)
        }
    }
    
    private func save(to url: URL) {
        // String(describing: self) - имя структуры где находишься, #function - имя функции
        let thisFunction = "\(String(describing: self)).\(#function)"
        do{
            let data: Data = try emojiArt.json()
            print("\(thisFunction) json = \(String(data: data, encoding: .utf8) ?? "nil")")
            try data.write(to: url)
            print("\(thisFunction) success")
        }catch let encoderError where encoderError is EncodingError{
            print("\(thisFunction) couldn't encode EmojiArt as JSON because \(encoderError.localizedDescription)")
        }catch{
            print("\(thisFunction) error = \(error)")
        }
    }
    
    init() {
        if let url = Autosave.url, let autosaveEmojiArt = try? EmojiArtModel(url: url){
            emojiArt = autosaveEmojiArt
            fetchBackgroundImageDataIfNecessary()
        } else {
            emojiArt = EmojiArtModel()
            //   emojiArt.addEmoji("🛥️", at: (-200,-100), size: 80)
            // emojiArt.addEmoji("🥴", at: (50,100), size: 40)
        }
    }
    var emojis: [EmojiArtModel.Emoji] {emojiArt.emojis}
    var background: EmojiArtModel.Background {emojiArt.background}
    
    @Published var backgroundImage: UIImage?
    @Published var backgroundImageFetchStatus = BackgroundImageFetchStatus.idle
    
    enum BackgroundImageFetchStatus: Equatable {
        case idle
        case fetching
        case failed(URL)
    }
    
    private func fetchBackgroundImageDataIfNecessary() {
        backgroundImage = nil
        switch emojiArt.background{
        case .url(let url):
            //fetch data
            backgroundImageFetchStatus = .fetching
            DispatchQueue.global(qos: .userInitiated).async {
                let imageData = try? Data(contentsOf: url)
                DispatchQueue.main.async { [weak self] in
                    if self?.emojiArt.background == EmojiArtModel.Background.url(url){
                        self?.backgroundImageFetchStatus = .idle
                        if imageData != nil {
                            self?.backgroundImage = UIImage(data: imageData!)
                        }
                        if self?.backgroundImage == nil{
                            self?.backgroundImageFetchStatus = .failed(url)
                        }
                    }
                }
            }
        case .imageData(let data):
            backgroundImage = UIImage(data: data)
        case .blank:
            break
        }
    }
    
    //MARK: - Intents
    
    func setBackground(_ background: EmojiArtModel.Background) {
        emojiArt.background = background
        print("background set to \(background)")
    }
    func addEmoji(_ emoji: String, at location: (x: Int, y: Int), size: CGFloat) {
        emojiArt.addEmoji(emoji, at: location, size: Int(size))
    }
    func moveEmoji(_ emoji: EmojiArtModel.Emoji, by offset: CGSize){
        if let index = emojiArt.emojis.index(matching: emoji){
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    func scaleEmoji(_ emoji: EmojiArtModel.Emoji, by scale: CGFloat){
        if let index = emojiArt.emojis.index(matching: emoji){
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrAwayFromZero))
        }
    }
    
    
    
    
}
