import SwiftUI

struct HeartbeatDetailView: View {
    @StateObject private var viewModel: HeartbeatDetailViewModel

    init(userId: String) {
        _viewModel = StateObject(
            wrappedValue: HeartbeatDetailViewModel(userId: userId)
        )
    }

    var body: some View {
        VStack(spacing: 20) {
            if let user = viewModel.user {
                Text(user.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
            } else {
                Text("Loading user...")
                    .font(.largeTitle)
            }

            Text(viewModel.connectionStatus.displayName)
                .font(.caption)
                .foregroundColor(viewModel.connectionStatus.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(viewModel.connectionStatus.color.opacity(0.2))
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

extension RealtimeService.ConnectionStatus {
    var displayName: String {
        switch self {
        case .connected: return "Connected"
        case .disconnected: return "Disconnected"
        case .error(_):
            return "Error"
        }
    }

    var color: Color {
        switch self {
        case .connected: return .green
        case .disconnected: return .red
        case .error(_):
            return .red
        }
    }
}

struct HeartbeatDetailView_Previews: PreviewProvider {
    static var previews: some View {
        HeartbeatDetailView(userId: "preview_user_id")
    }
}
