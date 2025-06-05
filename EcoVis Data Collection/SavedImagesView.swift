//
//  SavedImagesView.swift
//  EcoVis Data Collection
//
//  Created by Aryaman Dayal on 3/11/25.
//
//


import SwiftUI

struct SavedImagesView: View {
    let images: [UIImage]
    var onReset: () -> Void

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                if !images.isEmpty {
                    Section(header: Text("All Captured Images")) {
                        ForEach(images.indices, id: \.self) { i in
                            Image(uiImage: images[i])
                                .resizable()
                                .scaledToFit()
                        }
                    }
                } else {
                    Text("No saved images.")
                        .foregroundColor(.gray)
                        .italic()
                }
            }
            .navigationBarTitle("All Saved Images", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Reset") {
                    presentationMode.wrappedValue.dismiss()
                    onReset()
                }
            )
        }
    }
}

