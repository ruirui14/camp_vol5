// Views/StreamView.swift
// 配信視聴画面 - 背景に配信を表示し、ドラッグ可能なハートアニメーションを重ねて表示
// HeartbeatDetailViewから遷移する専用画面
// MVVMアーキテクチャに従い、ViewModelでビジネスロジックを管理

import SwiftUI

struct StreamView: View {
    // MARK: - Environment & ViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: StreamViewModel

    // MARK: - Parameters
    let userName: String

    // MARK: - UI State
    @State private var heartOffset: CGSize = .zero
    private let heartSize: CGFloat = 105.0

    // MARK: - Initialization
    init(viewModel: StreamViewModel, userName: String) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.userName = userName
    }

    var body: some View {
        ZStack {
            // 背景: 配信WebView
            if !viewModel.streamUrl.isEmpty {
                StreamWebViewWrapper(urlString: viewModel.streamUrl)
                    .ignoresSafeArea()
            } else {
                // URL未設定時の説明
                VStack(spacing: 20) {
                    Image(systemName: "play.tv")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)

                    Text("配信URLを設定してください")
                        .font(.title2)
                        .foregroundColor(.white)

                    Text("右上のボタンから配信URLを入力できます")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            }

            // ドラッグ可能なハートアニメーション
            HeartAnimationView(
                bpm: viewModel.currentBpm,
                heartSize: heartSize,
                showBPM: true,
                enableHaptic: false,
                heartColor: .red,
                syncWithVibration: false
            )
            .offset(heartOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        heartOffset = value.translation
                    }
            )
        }
        .navigationTitle(userName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("戻る") {
                    dismiss()
                }
                .foregroundColor(.white)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.showingUrlInput = true
                }) {
                    Image(systemName: "link.circle")
                        .foregroundColor(.white)
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingUrlInput) {
            StreamUrlInputSheet(streamUrl: $viewModel.streamUrl)
        }
        .onAppear {
            viewModel.startMonitoring()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
    }
}
