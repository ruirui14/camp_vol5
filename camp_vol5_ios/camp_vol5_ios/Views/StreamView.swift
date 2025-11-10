// Views/StreamView.swift
// 配信視聴画面 - YouTube配信を表示し、ドラッグ可能なハートアニメーションを重ねて表示
// MVVMアーキテクチャに従い、StreamViewModelでUI状態とビジネスロジックを管理
// フルスクリーン機能: 画面タップでフルスクリーン終了ボタンを表示/非表示

import SwiftUI

struct StreamView: View {
    // MARK: - Environment & ViewModel
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: StreamViewModel

    // MARK: - Constants
    let userName: String
    private let heartSize: CGFloat = 105.0

    // MARK: - Initialization
    init(viewModel: StreamViewModel, userName: String) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.userName = userName
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // 背景色を黒に設定（余白を隠す）
            Color.black
                .ignoresSafeArea()

            // 背景: 配信WebView
            if !viewModel.streamUrl.isEmpty {
                StreamWebViewWrapper(urlString: viewModel.streamUrl)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .id(viewModel.videoReloadID)
            } else {
                // URL未設定時の説明
                emptyStateView
            }

            // ドラッグ可能なハートアニメーション
            draggableHeartView

            // コントロールボタン（通常時のみ表示、フルスクリーンは非表示）
            if !viewModel.isFullscreen && !viewModel.streamUrl.isEmpty {
                controlButtons
            }

            // フルスクリーン時の解除ボタン（タップ時のみ表示）
            if viewModel.isFullscreen && viewModel.showControls {
                fullscreenExitButton
            }

            // フルスクリーン時のタップ検出エリア
            if viewModel.isFullscreen {
                fullscreenTapArea
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if !viewModel.isFullscreen {
                toolbarContent
            }
        }
        .toolbar(viewModel.isFullscreen ? .hidden : .visible, for: .navigationBar)
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

    // MARK: - Subviews

    /// URL未設定時の説明View
    private var emptyStateView: some View {
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
    }

    /// ドラッグ可能なハートアニメーション
    private var draggableHeartView: some View {
        HeartAnimationView(
            bpm: viewModel.currentBpm,
            heartSize: heartSize,
            showBPM: true,
            enableHaptic: false,
            heartColor: .red,
            syncWithVibration: false
        )
        .offset(viewModel.heartOffset)
        .zIndex(1000)
        .gesture(
            DragGesture()
                .onChanged { value in
                    viewModel.updateHeartOffset(translation: value.translation)
                }
                .onEnded { _ in
                    viewModel.saveHeartOffset()
                }
        )
    }

    /// コントロールボタン（通常時のみ）
    private var controlButtons: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()

                // ハート位置リセットボタン
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        viewModel.resetHeartPosition()
                    }
                }) {
                    Image(systemName: "scope")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .padding(.trailing, 10)

                // フルスクリーンボタン
                Button(action: {
                    withAnimation {
                        viewModel.enterFullscreen()
                    }
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .padding(.trailing, 20)
            }
            .padding(.bottom, 20)
        }
        .zIndex(999)
    }

    /// フルスクリーン時の解除ボタン
    private var fullscreenExitButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()

                // フルスクリーン終了ボタン
                Button(action: {
                    withAnimation {
                        viewModel.exitFullscreen()
                    }
                }) {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .padding(.trailing, 20)
            }
            .padding(.bottom, 20)
        }
        .zIndex(999)
        .transition(.opacity)
    }

    /// フルスクリーン時のタップ検出エリア
    private var fullscreenTapArea: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    viewModel.toggleControls()
                }
            }
            .allowsHitTesting(true)
            .zIndex(998)
    }

    /// ツールバーコンテンツ
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("戻る")
                    }
                }
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.5), radius: 2, x: 0, y: 1)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // リロードボタン
                    Button(action: {
                        viewModel.reloadVideo()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                            .font(.title3)
                    }

                    // URL設定ボタン
                    Button(action: {
                        viewModel.showingUrlInput = true
                    }) {
                        Image(systemName: "link.circle")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                }
            }
        }
    }
}
