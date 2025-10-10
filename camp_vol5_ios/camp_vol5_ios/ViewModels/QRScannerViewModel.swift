// ViewModels/QRScannerViewModel.swift
// QRコードスキャナーのビューモデル
// AVCaptureSessionの管理とQRコード検出ロジックを担当

import AVFoundation
import Combine
import Foundation

@MainActor
class QRScannerViewModel: NSObject, ObservableObject {
    @Published var scannedCode: String?
    @Published var isScanning = false
    @Published var errorMessage: String?

    private let captureSession = AVCaptureSession()
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?

    // カメラセッションを取得
    var session: AVCaptureSession {
        return captureSession
    }

    override init() {
        super.init()
        setupCaptureSession()
    }

    // カメラセッションのセットアップ
    private func setupCaptureSession() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            errorMessage = "カメラデバイスが見つかりません"
            return
        }

        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            errorMessage = "カメラの初期化に失敗しました: \(error.localizedDescription)"
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            errorMessage = "カメラ入力を追加できません"
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            errorMessage = "メタデータ出力を追加できません"
            return
        }
    }

    // スキャン開始
    func startScanning() {
        guard !captureSession.isRunning else { return }

        Task.detached { [weak self] in
            self?.captureSession.startRunning()

            await MainActor.run {
                self?.isScanning = true
            }
        }
    }

    // スキャン停止
    func stopScanning() {
        guard captureSession.isRunning else { return }

        Task.detached { [weak self] in
            self?.captureSession.stopRunning()

            await MainActor.run {
                self?.isScanning = false
            }
        }
    }

    // スキャン結果をクリア
    func clearScannedCode() {
        scannedCode = nil
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension QRScannerViewModel: AVCaptureMetadataOutputObjectsDelegate {
    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else {
                return
            }
            guard let stringValue = readableObject.stringValue else { return }

            // バイブレーション
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

            // メインスレッドで更新
            Task { @MainActor in
                self.scannedCode = stringValue
            }
        }
    }
}
