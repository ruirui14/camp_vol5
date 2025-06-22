//
//  QRCodeScannerView.swift
//  camp_vol5_ios
//
//  Created by rui on 2025/06/21.
//

import SwiftUI
import AVFoundation

struct QRCodeScannerView: View {
    @Binding var scannedText: String
    @Binding var isPresented: Bool
    @State private var showAlert = false
    
    
    var body: some View {
        ZStack {
            
            
            CameraView(scannedText: $scannedText, showAlert: $showAlert,isPresented: $isPresented)
                .edgesIgnoringSafeArea(.all)
            VStack() {
                // 📍上部ヘッダー（戻る + タイトル）
                HeaderBar(title: "推しの鼓動追加") {
                    isPresented = false
                }
                Spacer()
                // カスタムボトムバー
                CustomBottomBar()
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .edgesIgnoringSafeArea(.top) // ヘッダーを安全領域の外まで表示したい時
            
        }
        
        
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("QRコード読み取り完了"),
                message: Text("内容: \(scannedText)"),
                dismissButton: .default(Text("OK")){
                    isPresented = false
                }
            )
        }
    }
    
    
    
    
    
    // カスタムヘッダー（戻るボタン + タイトル + グラデーション）
    struct HeaderBar: View {
        var title: String
        var onBack: () -> Void
        
        var body: some View {
            GeometryReader { proxy in
                let topInset = proxy.safeAreaInsets.top
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [Color(red: 250/255, green: 189/255, blue: 194/255), Color(red: 243/255, green: 94/255, blue: 106/255)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 44 + topInset + 50)
                    .edgesIgnoringSafeArea(.top)
                    
                    HStack {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.leading)
                        
                        Spacer()
                        
                        Text(title)
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Spacer().frame(width: 44)
                    }
                    .padding(.top, topInset + 20)
                }
                .frame(height: 44 + topInset)
            }
            .frame(height: 44) // GeometryReaderの高さ調整
        }
    }
    
    
    
    
    struct CameraView: UIViewRepresentable {
        @Binding var scannedText: String
        @Binding var showAlert: Bool
        @Binding var isPresented: Bool
        
        func makeCoordinator() -> Coordinator {
            Coordinator(scannedText: $scannedText, showAlert: $showAlert,isPresented: $isPresented)
        }
        
        func makeUIView(context: Context) -> BaseCameraView {
            let view = BaseCameraView()
            view.setup(delegate: context.coordinator)
            return view
        }
        //func makeUIView(context: Context) -> UIView { BaseCameraView() }
        func updateUIView(_ uiView: UIViewType, context: Context) {}
        
        class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
            @Binding var scannedText: String
            @Binding var showAlert: Bool
            @Binding var isPresented: Bool
            
            init(scannedText: Binding<String>, showAlert: Binding<Bool>,isPresented: Binding<Bool>) {
                _scannedText = scannedText
                _showAlert = showAlert
                _isPresented = isPresented
            }
            func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
                print("デリゲート呼ばれたよ！（metadata count: \(metadataObjects.count)）")
                guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                      object.type == .qr,
                      let stringValue = object.stringValue else { return }
                print("QRコードじゃなかった、または読めなかった")
                
                
                DispatchQueue.main.async {
                    self.scannedText = stringValue
                    self.showAlert = true
                    
                }
            }
        }
    }
    
    
    
    class BaseCameraView: UIView {
        private var session: AVCaptureSession?
        
        override func layoutSubviews() {
            super.layoutSubviews()
            (layer.sublayers?.first as? AVCaptureVideoPreviewLayer)?.frame = bounds
        }
        
        func setup(delegate: AVCaptureMetadataOutputObjectsDelegate) {
            guard session == nil else { return }
            
            let session = AVCaptureSession()
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else { return }
            
            session.addInput(input)
            
            let output = AVCaptureMetadataOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                output.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
                output.metadataObjectTypes = [.qr]
            }
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            layer.insertSublayer(previewLayer, at: 0)
            previewLayer.frame = bounds
            
            session.startRunning()
            self.session = session
            
            //        lazy var initCaptureSession: Void = {
            //            guard let device = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera],
            //                                                                mediaType: .video,
            //                                                                position: .unspecified)
            //                .devices.first(where: { $0.position == .back }),
            //                  let input = try? AVCaptureDeviceInput(device: device) else { return }
            //
            //            let session = AVCaptureSession()
            //            session.addInput(input)
            //            session.startRunning()
            //
            //            layer.insertSublayer(AVCaptureVideoPreviewLayer(session: session), at: 0)
            //        }()
        }
    }
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ListHeartBeatsView()
        }
    }
    
    
    
    
    //#Preview {
    //    QRCodeScannerView()
    //}
}
