// Views/QRScannerSheet.swift
import AVFoundation
import SwiftUI

struct QRScannerSheet: View {
    let onQRCodeScanned: (String) -> Void
    @State private var navigateToQRShare = false
    @EnvironmentObject private var authenticationManager: AuthenticationManager
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationStack {
            ZStack {
                // QRコードスキャナー部分
                QRScannerViewController_Wrapper(onQRCodeScanned: onQRCodeScanned)
                    .ignoresSafeArea()

                // オーバーレイ UI
                VStack {
                    HStack {
                        Button("閉じる") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    Spacer()

                    // 下部の説明とボタン
                    VStack(spacing: 16) {
                        Text("QRコードをスキャンして\nユーザーを追加")
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .shadow(color: .black, radius: 2)

                        if authenticationManager.isAuthenticated {
                            Button(action: {
                                print("📱 [QRScannerSheet] QRコード表示ボタンタップ")
                                navigateToQRShare = true
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "qrcode")
                                        .foregroundColor(.white)
                                        .font(.title3)
                                    Text("QRコードを表示")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.white)
                                }
                                .frame(minWidth: 60)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.green.opacity(0.8),
                                                    Color.blue.opacity(0.7),
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(color: .white.opacity(0.5), radius: 2, x: 0, y: 0)
                                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                                )
                            }
                        } else {
                            Text("Google認証後に自分のQRコードが利用可能")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToQRShare) {
                QRCodeShareView()
                    .environmentObject(authenticationManager)
                    .onDisappear {
                        print("📱 [QRScannerSheet] QRCodeShareView navigationから戻った")
                    }
            }
        }
    }
}

struct QRScannerViewController_Wrapper: UIViewControllerRepresentable {
    let onQRCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(
        _: QRScannerViewController,
        context _: Context
    ) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onQRCodeScanned: onQRCodeScanned)
    }

    class Coordinator: NSObject, QRScannerDelegate {
        let onQRCodeScanned: (String) -> Void

        init(onQRCodeScanned: @escaping (String) -> Void) {
            self.onQRCodeScanned = onQRCodeScanned
        }

        func didScanQRCode(_ code: String) {
            onQRCodeScanned(code)
        }
    }
}

protocol QRScannerDelegate: AnyObject {
    func didScanQRCode(_ code: String)
}

class QRScannerViewController: UIViewController {
    weak var delegate: QRScannerDelegate?

    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    private func setupCamera() {
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video)
        else {
            return
        }

        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(
                self,
                queue: DispatchQueue.main
            )
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
    }

    private func setupUI() {
        // オーバーレイビューを追加
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.addSubview(overlayView)

        // スキャンエリアを作成
        let scanArea = CGRect(
            x: 50,
            y: 200,
            width: view.bounds.width - 100,
            height: view.bounds.width - 100
        )
        let path = UIBezierPath(rect: overlayView.bounds)
        let scanPath = UIBezierPath(rect: scanArea)
        path.append(scanPath.reversing())

        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
        overlayView.layer.mask = maskLayer

        // ガイドラインを追加
        let guidelineView = UIView(frame: scanArea)
        guidelineView.layer.borderColor = UIColor.white.cgColor
        guidelineView.layer.borderWidth = 2
        guidelineView.layer.cornerRadius = 8
        view.addSubview(guidelineView)
    }
}

extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from _: AVCaptureConnection
    ) {
        if let metadataObject = metadataObjects.first {
            guard
                let readableObject = metadataObject
                    as? AVMetadataMachineReadableCodeObject
            else {
                return
            }
            guard let stringValue = readableObject.stringValue else { return }

            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

            delegate?.didScanQRCode(stringValue)
        }
    }
}
