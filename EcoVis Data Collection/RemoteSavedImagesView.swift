//
//  RemoteSavedImagesView.swift
//  EcoVis Data Collection
//
//  Created by Aryaman Dayal on 6/5/25.
//

import SwiftUI

struct RemoteSavedImagesView: View {
    let imageURLs: [String]
    var body: some View {
        List {
            if imageURLs.isEmpty {
                Text("No images to display.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                Section(header: Text("All Images")) {
                    ForEach(imageURLs.indices, id: \.self) { idx in
                        if let url = URL(string: imageURLs[idx]) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(maxWidth: .infinity, minHeight: 150)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity, minHeight: 150)
                                case .failure:
                                    VStack {
                                        Image(systemName: "photo")
                                        Text("Failed to load")
                                    }
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, minHeight: 150)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Text("Invalid URL")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, minHeight: 150)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}
