//
//  EmojiArtDocumentView.swift
//  EmojiArtStanford
//
//  Created by admin on 19.03.2023.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    
    @ObservedObject var document: EmojiArtDocument
    
    @Environment(\.undoManager) var undoManager
    
    //@ScaledMetric позволет влиять на размер шрифта регулируя общие настройки устройства
    @ScaledMetric var defaultEmojiFontSize: CGFloat = 40
    var body: some View {
        VStack(spacing: 0){
            documentBody
            PaletteChooser(emojiFontSize: defaultEmojiFontSize)
        }
    }
     
    
    var documentBody: some View {
        GeometryReader{geometry in
            ZStack{
                Color.white
                    OptionalImage(uiImage: document.backgroundImage)
                    .scaleEffect(zoomScale)
                    .position(convertFromEMojiCoordinates((0,0), in: geometry))
                .gesture(doubleTapToZoom(in: geometry.size))
                if document.backgroundImageFetchStatus == .fetching {
                    ProgressView().scaleEffect(2)
                }else{
                    ForEach(document.emojis){emoji in
                        Text(emoji.text)
                            .font(.system(size: fontSize(for: emoji)))
                            .scaleEffect(zoomScale)
                            .position(position(for: emoji, in: geometry))
                    }
                }
            }
            .clipped()
            .onDrop(of: [.plainText, .url, .image], isTargeted: nil){providers, location in
                return drop(providers: providers, at: location, in: geometry)
            }
            .gesture(panGasture().simultaneously(with: zoomGasture()))
            //разобраться с новым способом вывода alert
            // .alert(<#T##title: Text##Text#>, isPresented: <#T##Binding<Bool>#>, actions: <#T##() -> View#>, message: <#T##() -> View#>) { }
            .alert(item: $alertToShow) { alertToShow in
                alertToShow.alert()
            }
            .onChange(of: document.backgroundImageFetchStatus) { status in
                switch status {
                case .failed(let url):
                    showBackgoundImageFailedAlert(url)
                default:
                    break
                }
            }
            .onReceive(document.$backgroundImage) { image in
                if autoZoom {
                    zoomToFit(image, in: geometry.size)
                }
            }
            .compactableToolbar {
                 
                    AnimatedActionButton(title: "Paste Background", systemImage: "doc.on.clipboard") {
                        pasteBackground()
                    }
                if Camera.isAvalible {
                    AnimatedActionButton(title: "Take Photo", systemImage: "camera") {
                        backgroundPicker = .camera
                    }
                }
                if PhotoLibrary.isAvailable {
                    AnimatedActionButton(title: "Search Photos", systemImage: "photo") {
                        backgroundPicker = .library
                    }
                }
                
                    if let undoManager = undoManager{
                        if undoManager.canUndo{
                            AnimatedActionButton(title: undoManager.undoActionName, systemImage: "arrow.uturn.backward") {
                                undoManager.undo()
                            }
                        }
                        if undoManager.canRedo{
                            AnimatedActionButton(title: undoManager.redoActionName, systemImage: "arrow.uturn.forward") {
                                undoManager.redo()
                            }
                        }
                    }
            }
            .sheet(item: $backgroundPicker) { pickerType in
                switch pickerType {
                case .camera: Camera(handlePickedImage: {image in handlePickedBackground(image)})
                case .library: PhotoLibrary(handlePickedImage: {image in handlePickedBackground(image)})
                }
            }
        }
    }
    
    func handlePickedBackground(_ image: UIImage?){
        autoZoom = true
        if let imageData = image?.jpegData(compressionQuality: 1.0) {
            document.setBackground(.imageData(imageData), undoManager: undoManager)
        }
        backgroundPicker = nil
    }
    
    @State private var backgroundPicker: BackgroundPickerType?
    
    //чтобы подписать enum под протокол Identifiable необходимо инициализировать id как "self"
    enum BackgroundPickerType: Identifiable {
        var id: BackgroundPickerType {self}
        
        case camera
        case library
        
    }
    
private func pasteBackground() {
    autoZoom = true
    if let imageData = UIPasteboard.general.image?.jpegData(compressionQuality: 1.0) {
        document.setBackground(.imageData(imageData), undoManager: undoManager)
    }else if let url = UIPasteboard.general.url?.imageURL{
        document.setBackground(.url(url), undoManager: undoManager)
    }else{
        alertToShow = IdentifiableAlert(title: "Paste Background", message: "There is no image currently on the pasteboard")
    }
}
    
    @State private var autoZoom = false
   // @State private var fetchFailed = false
    @State private var alertToShow: IdentifiableAlert?
    
    private func showBackgoundImageFailedAlert(_ url: URL) {
        alertToShow = IdentifiableAlert(id: "fetch failed: " + url.absoluteString, alert: {
            Alert(
                title: Text("Background Image Fetch"),
                  message: Text("Couldn't load from \(url)."),
                  dismissButton: .default(Text("Ok")))
        })
    }
    
    
    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy)->Bool{
        var found = providers.loadObjects(ofType: URL.self){ url in
            autoZoom = true
            document.setBackground(.url(url.imageURL), undoManager: undoManager)
        }
        if !found {
            found = providers.loadObjects(ofType: UIImage.self){image in
                if let data = image.jpegData(compressionQuality: 1.0) {
                    autoZoom = true
                    document.setBackground(.imageData(data), undoManager: undoManager)
                }
            }
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                if let emoji = string.first, emoji.isEmoji{
                    
                    document.addEmoji(String(emoji),
                                      at: convertToEMojiCoordinates(location, in: geometry),
                                      size: defaultEmojiFontSize / zoomScale, undoManager: undoManager)
                }
            }
        }
        return found
    }
    
    private func position(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint{
        convertFromEMojiCoordinates((emoji.x, emoji.y), in: geometry)
    }
    
    private func convertToEMojiCoordinates(_ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
        let center = geometry.frame(in: .local).center
        let location = CGPoint(
            x: (location.x - panOffset.width - center.x) / zoomScale,
            y: (location.y - panOffset.height - center.y) / zoomScale
            )
        return (Int(location.x), Int(location.y))
    }
    
    private func convertFromEMojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy)->CGPoint{
        let center = geometry.frame(in: .local).center
        return CGPoint(
            x: center.x + CGFloat(location.x) * zoomScale + panOffset.width,
            y: center.y + CGFloat(location.y) * zoomScale + panOffset.height)
    }
    
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat{
        CGFloat(emoji.size)
    }
    // обычно в @SceneStorage можно поместить только базовые структуры CGSize к примеру нельзя, но можно воспользоваться rawValue подробнее смотреть в UtilityExtensions
    @SceneStorage("EmojiArtDocumentView.steadyStatePanOffset")
    private var steadyStatePanOffset: CGSize = CGSize.zero
    
    @GestureState private var gesturePanOffset: CGSize = CGSize.zero
    
    private var panOffset: CGSize {
        // + добавлен в UtilityExtensions
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func panGasture() -> some Gesture {
        DragGesture()
        // параметр _ обозначет особую анимацию (обычно называеться transaction)
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
            }
    }
    
    @SceneStorage("EmojiArtDocumentView.steadyStateZoomScale")
    private var steadyStateZoomScale: CGFloat = 1
    
    @GestureState private var gestureZoomScale: CGFloat = 1
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }
    
    private func zoomGasture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale){ latestGastureScale, gestureZoomScale, _ in
                //gestureZoomScale временный inOut параметр
                gestureZoomScale = latestGastureScale
                
            }
            .onEnded { gestureScaleAtEnd in
                steadyStateZoomScale *= gestureScaleAtEnd
        }
    }
    
   
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation{
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        // добавить guard за место if let
        if let image = image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            steadyStateZoomScale = .zero
            steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    
}













struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
