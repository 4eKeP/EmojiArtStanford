//
//  EmojiArtDocument.swift
//  EmojiArtStanford
//
//  Created by admin on 19.03.2023.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

extension UTType {
    static let emojiart = UTType(exportedAs: "EmojiArtStanford.proj")
}

class EmojiArtDocument: ReferenceFileDocument {
    
    typealias Snapshot = Data
    //что бы найти UTType необходимо импортировать UniformTypeIdentifiers
    static var readableContentTypes = [UTType.emojiart]
    static var writeableContentTypes = [UTType.emojiart]
       
    func snapshot(contentType: UTType) throws -> Data {
        try emojiArt.json()
    }
    
    func fileWrapper(snapshot: Data, configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: snapshot)
    }
    
    required init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents{
            emojiArt = try EmojiArtModel(json: data)
            fetchBackgroundImageDataIfNecessary()
        }else{
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
  
    @Published private(set) var emojiArt: EmojiArtModel {
        didSet{
        //    autosave()
            if emojiArt.background != oldValue.background{
                fetchBackgroundImageDataIfNecessary()
            }
        }
    }
    //код для старого способа сохранения
    /*
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
    */
    
    init() {
        emojiArt = EmojiArtModel()
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
    
    private var backgroundImageFetchCancellacle: AnyCancellable?
    
    private func fetchBackgroundImageDataIfNecessary() {
        backgroundImage = nil
        switch emojiArt.background{
        case .url(let url):
            //fetch data
            backgroundImageFetchStatus = .fetching
            //останавливает старые запросы, если новый появился
            backgroundImageFetchCancellacle?.cancel()
            //лучше использовать URLSession
            let session = URLSession.shared
            let publisher = session.dataTaskPublisher(for: url)
                .map{(data, urlResponse) in UIImage(data: data)}
                .replaceError(with: nil)
                .receive(on: DispatchQueue.main)
            /*
            // для того что бы передача данных не закончилась после выполнения функции надо создать переменную типа AnyCancellable?(нельзя применить без import Combine)
            // польза в том что при закрытии приложения или исчезновении self и backgroundImageFetchCancellacle, цикл автоматически перестанет ждать ответа
             */
         backgroundImageFetchCancellacle = publisher
            /*
        // .assign не подходит так как невозможно сменить статус BackgroundImageFetchStatus
        //         .assign(to: \EmojiArtDocument.backgroundImage, on: self)
            */
            /*
            // если .replaceError(with: nil) не подходит к условиям реализации (например считывание кода ошибки) то можно использовать форму .sink приведенную ниже
             .sink(receiveCompletion: {result in
                 switch result {
                 case .finished:
                     print("success!")
                 case .failure(let error):
                     print("failed: error  =\(error)")
                 }
             },
                   receiveValue: { [weak self] image in
                 self?.backgroundImage = image
                 self?.backgroundImageFetchStatus = (image != nil) ? .idle : .failed(url)
             })
             */
             .sink { [weak self] image in
                 self?.backgroundImage = image
                 self?.backgroundImageFetchStatus = (image != nil) ? .idle : .failed(url)
             }
            // или "ручным" способом ниже, но лучше использовать URLSession
            /*
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
             */
        case .imageData(let data):
            backgroundImage = UIImage(data: data)
        case .blank:
            break
        }
    }
    
    //MARK: - Intents
    
    func setBackground(_ background: EmojiArtModel.Background, undoManager: UndoManager?) {
        undoablyPerform(operation: "Set Background", with: undoManager){
            emojiArt.background = background
        }
    }
    func addEmoji(_ emoji: String, at location: (x: Int, y: Int), size: CGFloat, undoManager: UndoManager?) {
        undoablyPerform(operation: "Add \(emoji)", with: undoManager){
            emojiArt.addEmoji(emoji, at: location, size: Int(size))
        }
    }
    func moveEmoji(_ emoji: EmojiArtModel.Emoji, by offset: CGSize, undoManager: UndoManager?){
            if let index = emojiArt.emojis.index(matching: emoji){
                undoablyPerform(operation: "Move", with: undoManager){
                emojiArt.emojis[index].x += Int(offset.width)
                emojiArt.emojis[index].y += Int(offset.height)
            }
        }
    }
    func scaleEmoji(_ emoji: EmojiArtModel.Emoji, by scale: CGFloat, undoManager: UndoManager?){
        if let index = emojiArt.emojis.index(matching: emoji){
            undoablyPerform(operation: "Scaling", with: undoManager){
                emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrAwayFromZero))
            }
        }
    }
    
    //MARK: - Undo
    
    private func undoablyPerform(operation: String, with undoManager: UndoManager? = nil, doit: ()->Void){
        let oldEmojiArt = emojiArt
        doit()
        undoManager?.registerUndo(withTarget: self) { myself in
            //что бы реализовать redo необходимо добавить строку ниже
            myself.undoablyPerform(operation: operation, with: undoManager) {
                myself.emojiArt = oldEmojiArt
            }
        }
        undoManager?.setActionName(operation)
    }
}
