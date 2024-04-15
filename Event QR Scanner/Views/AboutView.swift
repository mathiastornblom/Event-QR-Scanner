//
//  AboutView.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-09.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                    Text(NSLocalizedString("app_name", comment: "App name on the About page"))
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text(NSLocalizedString("version", comment: "Version information")) // "Version:"
                        .font(.headline)
                    Text(appVersion()) // "x.x (Build xxx)"
                        .font(.headline)
                }
                
                Text(NSLocalizedString("app_description", comment: "Description of the app"))
                
                VStack(alignment: .leading) {
                    Text(NSLocalizedString("developed_by", comment: "Prefix for developer information"))
                        .font(.headline)
                    Text(NSLocalizedString("developer_name", comment: "Developer's name"))
                    Text(NSLocalizedString("contact_info", comment: "Developer contact information"))
                }
                
                Text(NSLocalizedString("acknowledgments", comment: "Acknowledgments text"))
            }
            .padding()
        }
        .navigationTitle(NSLocalizedString("about_title", comment: "Title for the About page"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

func appVersion() -> String {
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    return "\(version) (Build \(build))"
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AboutView()
        }
    }
}
