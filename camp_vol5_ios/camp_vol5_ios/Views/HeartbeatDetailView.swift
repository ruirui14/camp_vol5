import SwiftUI

struct HeartbeatDetailView: View {
    @StateObject private var viewModel: HeartbeatDetailViewModel

    init(userId: String) {
        _viewModel = StateObject(wrappedValue: HeartbeatDetailViewModel(userId: userId))
    }

    var body: some View {
        VStack(spacing: 20) {
            // 監視状態を表示
            HStack {
                Circle()
                    .fill(viewModel.isMonitoring ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(viewModel.isMonitoring ? "Monitoring" : "Not Monitoring")
                    .font(.caption)
                    .foregroundColor(viewModel.isMonitoring ? .green : .red)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background((viewModel.isMonitoring ? Color.green : Color.red).opacity(0.2))
            .cornerRadius(10)

            if let heartbeat = viewModel.currentHeartbeat {
                Text("\(heartbeat.bpm)")
                    .font(.system(size: 80, weight: .bold))
                Text("bpm")
                    .font(.title)
                Text(
                    "Last updated: \(heartbeat.timestamp, formatter: dateFormatter)"
                )
                .font(.caption)
                .foregroundColor(.gray)
            } else {
                Text("--")
                    .font(.system(size: 80, weight: .bold))
                Text("bpm")
                    .font(.title)
                Text("No data available")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .navigationTitle(viewModel.user?.name ?? "読み込み中...")
        .navigationBarTitleDisplayMode(.inline)
        .gradientNavigationBar(colors: [.main, .accent], titleColor: .white)
        .onAppear {
            viewModel.startContinuousMonitoring()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
        .onChange(of: viewModel.isMonitoring) { isMonitoring in
            if isMonitoring {
                viewModel.startContinuousMonitoring()
            } else {
                viewModel.stopMonitoring()
            }
        }
        .padding()
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

struct HeartbeatDetailView_Previews: PreviewProvider {
    static var previews: some View {
        HeartbeatDetailView(userId: "preview_user_id")
            .environmentObject(AuthenticationManager())
    }
}
