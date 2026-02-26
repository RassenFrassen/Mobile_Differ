import SwiftUI

struct LicensesView: View {
    var body: some View {
        List {
            Section {
                Text("This app includes MDM payload documentation from multiple open-source projects. We're grateful to these contributors:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            ForEach(licenseAttributions) { attribution in
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(attribution.projectName)
                            .font(.headline)
                        
                        if let license = attribution.licenseName {
                            Label(license, systemImage: "doc.text")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        if let copyright = attribution.copyright {
                            Text(copyright)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        
                        if let terms = attribution.terms {
                            Text(terms)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if let url = attribution.licenseURL {
                        Link(destination: url) {
                            Label("View License", systemImage: "arrow.up.right.square")
                                .font(.subheadline)
                        }
                    }
                    
                    if let repoURL = attribution.repositoryURL {
                        Link(destination: repoURL) {
                            Label("View Repository", systemImage: "chevron.left.forwardslash.chevron.right")
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .navigationTitle("Licenses & Attribution")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LicenseAttribution: Identifiable {
    let id = UUID()
    let projectName: String
    let licenseName: String?
    let copyright: String?
    let terms: String?
    let licenseURL: URL?
    let repositoryURL: URL?
}

private let licenseAttributions: [LicenseAttribution] = [
    LicenseAttribution(
        projectName: "Apple device-management",
        licenseName: "MIT License",
        copyright: "Copyright © 2025 Apple Inc.",
        terms: "Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files, to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, subject to the above copyright notice and this permission notice being included in all copies or substantial portions of the Software.",
        licenseURL: URL(string: "https://github.com/apple/device-management/blob/release/LICENSE"),
        repositoryURL: URL(string: "https://github.com/apple/device-management")
    ),
    LicenseAttribution(
        projectName: "Apple Developer Documentation",
        licenseName: nil,
        copyright: "Copyright © 2025 Apple Inc. All rights reserved.",
        terms: "Content is provided under Apple's Terms of Use for developer documentation.",
        licenseURL: URL(string: "https://www.apple.com/legal/internet-services/terms/site.html"),
        repositoryURL: URL(string: "https://developer.apple.com/documentation/devicemanagement")
    ),
    LicenseAttribution(
        projectName: "ProfileManifests",
        licenseName: "MIT License",
        copyright: "Copyright © ProfileManifests contributors",
        terms: "Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files, to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, subject to the above copyright notice and this permission notice being included in all copies or substantial portions of the Software.",
        licenseURL: URL(string: "https://github.com/ProfileManifests/ProfileManifests/blob/main/LICENSE"),
        repositoryURL: URL(string: "https://github.com/ProfileManifests/ProfileManifests")
    ),
    LicenseAttribution(
        projectName: "rtrouton/profiles",
        licenseName: "MIT License",
        copyright: "Copyright © Rich Trouton",
        terms: "Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files, to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, subject to the above copyright notice and this permission notice being included in all copies or substantial portions of the Software.",
        licenseURL: URL(string: "https://github.com/rtrouton/profiles/blob/main/LICENSE"),
        repositoryURL: URL(string: "https://github.com/rtrouton/profiles")
    )
]

#Preview {
    NavigationStack {
        LicensesView()
    }
}
