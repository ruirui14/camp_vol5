// Views/Follow/CameraQRScannerView.swift

import AVFoundation
import SwiftUI

struct CameraQRScannerView: View {
    @StateObject private var viewModel = QRScannerViewModel()
    let onCodeScanned: (String) -> Void

    var body: some View {
        ZStack {
            // カメラプレビュー
            CameraPreviewView(session: viewModel.session)
                .ignoresSafeArea()

            // スキャンエリアのオーバーレイ
            ScannerOverlayView()

            // エラーメッセージ
            if let errorMessage = viewModel.errorMessage {
                VStack {
                    Spacer()
                    Text(errorMessage)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                        .padding()
                }
            }
        }
        .onAppear {
            viewModel.startScanning()
        }
        .onDisappear {
            viewModel.stopScanning()
        }
        .onChange(of: viewModel.scannedCode) { _, newCode in
            if let code = newCode {
                onCodeScanned(code)
                viewModel.clearScannedCode()
            }
        }
    }
}

// MARK: - Camera Preview
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

// MARK: - Scanner Overlay
struct ScannerOverlayView: View {
    var body: some View {
        ZStack {
            // 暗いオーバーレイ
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            // スキャンエリア
            GeometryReader { geometry in
                let size = min(geometry.size.width - 100, geometry.size.height - 300)
                let rect = CGRect(
                    x: (geometry.size.width - size) / 2,
                    y: (geometry.size.height - size) / 2,
                    width: size,
                    height: size
                )

                Path { path in
                    path.addRect(CGRect(origin: .zero, size: geometry.size))
                    path.addRect(rect)
                }
                .fill(style: FillStyle(eoFill: true))
                .foregroundColor(.black.opacity(0.5))

                // スキャンエリアのボーダー
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            }
        }
    }
}

#Preview {
    CameraQRScannerView { code in
        print("Scanned: \(code)")
    }
}
