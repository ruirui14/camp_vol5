// Views/Settings/LicenseDetailView.swift
// License detail screen - ライセンス詳細画面
// 個別のライセンス情報（著作権、URL、ライセンステキスト）を表示

import SwiftUI

struct LicenseDetailView: View {
    let license: License

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Copyright Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Copyright")
                        .font(.headline)
                    Text(license.copyright)
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                // URL Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Repository")
                        .font(.headline)
                    Link(license.url, destination: URL(string: license.url)!)
                        .font(.body)
                }

                // License Text Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("License Text")
                        .font(.headline)
                    Text(license.licenseText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
            }
            .padding()
        }
        .navigationTitle(license.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LicenseDetailView(license: License.allLicenses[0])
    }
}
