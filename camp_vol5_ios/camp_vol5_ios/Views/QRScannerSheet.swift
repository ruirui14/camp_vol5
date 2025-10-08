// Views/QRScannerSheet.swift
// QRコードスキャナーのシートビュー
// QRScannerViewControllerをSwiftUIでラップして表示

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
