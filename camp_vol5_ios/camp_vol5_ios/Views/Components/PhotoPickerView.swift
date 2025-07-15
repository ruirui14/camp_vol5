// Views/Components/PhotoPickerView.swift
// 拡張写真選択ビュー

import Photos
import PhotosUI
import SwiftUI

// MARK: - 写真ライブラリ権限管理（統合版）
class PhotoPermissionManagerIntegrated: ObservableObject {
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined

    init() {
        checkPermission()
    }

    func checkPermission() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestPermission() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
            }
        }
    }
}

// MARK: - 拡張写真選択ビュー
struct PhotoPickerView: View {
    @StateObject private var permissionManager = PhotoPermissionManagerIntegrated()
    @State private var selectedItem: PhotosPickerItem?
    @State private var isProcessing = false
    @State private var showingPermissionAlert = false

    let onImageSelected: (UIImage) -> Void

    var body: some View {
        Group {
            if permissionManager.authorizationStatus == .authorized
                || permissionManager.authorizationStatus == .limited
            {
                PhotosPicker(
                    selection: $selectedItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "photo")
                        }
                        Text(isProcessing ? "処理中..." : "画像を変更")
                    }
                    .foregroundColor(.blue)
                    .padding()
                }
                .disabled(isProcessing)
            } else {
                Button(action: {
                    if permissionManager.authorizationStatus == .denied {
                        showingPermissionAlert = true
                    } else {
                        permissionManager.requestPermission()
                    }
                }) {
                    HStack {
                        Image(systemName: "photo")
                        Text("写真ライブラリにアクセス")
                    }
                    .foregroundColor(.blue)
                    .padding()
                }
            }
        }
        .onChange(of: selectedItem) { oldItem, newItem in
            guard let newItem = newItem else { return }

            isProcessing = true

            Task {
                do {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        if let uiImage = UIImage(data: data) {
                            await MainActor.run {
                                isProcessing = false
                                onImageSelected(uiImage)
                                selectedItem = nil
                            }
                        } else {
                            await MainActor.run {
                                isProcessing = false
                            }
                        }
                    } else {
                        await MainActor.run {
                            isProcessing = false
                        }
                    }
                } catch {
                    await MainActor.run {
                        isProcessing = false
                    }
                }
            }
        }
        .alert("写真ライブラリへのアクセス", isPresented: $showingPermissionAlert) {
            Button("設定を開く") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("写真を選択するには、設定で写真ライブラリへのアクセスを許可してください。")
        }
        .onAppear {
            permissionManager.checkPermission()
        }
    }
}
