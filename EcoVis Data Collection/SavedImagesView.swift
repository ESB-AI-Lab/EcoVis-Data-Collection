//
//  SavedImagesView.swift
//  EcoVis Data Collection
//
//  Created by Aryaman Dayal on 3/11/25.
//

import SwiftUI

struct SavedImagesView: View {
    let leftImages: [UIImage]
    let rightImages: [UIImage]
    var onReset: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                if !leftImages.isEmpty {
                    Section(header: Text("Left Images")) {
                        ForEach(leftImages.indices, id: \.self) { i in
                            Image(uiImage: leftImages[i])
                                .resizable()
                                .scaledToFit()
                        }
                    }
                }
                if !rightImages.isEmpty {
                    Section(header: Text("Right Images")) {
                        ForEach(rightImages.indices, id: \.self) { i in
                            Image(uiImage: rightImages[i])
                                .resizable()
                                .scaledToFit()
                        }
                    }
                }
            }
            .navigationBarTitle("All Captured Images", displayMode: .inline)
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
