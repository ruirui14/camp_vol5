// UserHeartbeatCard.swift
// フォローユーザーの心拍数情報を表示するカードコンポーネント
// NavigationLinkの中で使用されるリスト項目として設計

import SwiftUI

struct UserHeartbeatCard: View {
    let userWithHeartbeat: UserWithHeartbeat

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(userWithHeartbeat.user.name)
                    .font(.headline)

                if let heartbeat = userWithHeartbeat.heartbeat {
                    Text(
                        "更新: \(timeAgoString(from: heartbeat.timestamp))"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                } else {
                    Text("データなし")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing) {
                if let heartbeat = userWithHeartbeat.heartbeat {
                    HStack {
                        Text("\(heartbeat.bpm)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("bpm")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                } else {
                    Text("--")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
