//
//  RemoteSavedRowObjectsView.swift
//  EcoVis Data Collection
//
//  Created by Aryaman Dayal on 6/5/25.
//

import SwiftUI

struct RemoteSavedRowObjectsView: View {
    let rowImageURLs: [String: [String]]
    
    var body: some View {
        List {
            ForEach(Array(rowImageURLs.keys).sorted(), id: \.self) { key in
                Section(header: Text(key)) {
                    let urls = rowImageURLs[key] ?? []
                    ForEach(urls.indices, id: \.self) { idx in
                        if let url = URL(string: urls[idx]) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(maxWidth: .infinity, minHeight: 120)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: .infinity, minHeight: 120)
                                case .failure:
                                    VStack {
                                        Image(systemName: "photo")
                                        Text("Failed to load")
                                    }
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, minHeight: 120)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        } else {
                            Text("Invalid URL")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, minHeight: 120)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}
