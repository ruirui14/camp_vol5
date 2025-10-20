// Views/Settings/LicensesView.swift
// Open Source Licenses list screen - ライセンス一覧画面
// Licenseモデルの配列を表示し、各項目をタップすると詳細画面へ遷移

import SwiftUI

struct LicensesView: View {
    var body: some View {
        List(License.allLicenses) { license in
            NavigationLink(destination: LicenseDetailView(license: license)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(license.name)
                        .font(.headline)
                    Text(license.licenseName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Open Source Licenses")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        LicensesView()
    }
}
