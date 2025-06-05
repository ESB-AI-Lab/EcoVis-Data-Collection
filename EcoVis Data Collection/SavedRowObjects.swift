//
//  SavedRowObjects.swift
//  EcoVis Data Collection
//
//  Created by Aryaman Dayal on 4/30/25.
//

import SwiftUI

struct SavedRowObjectsView: View {
    let savedData: [String: [UIImage]]
    let onReset: () -> Void
    @Environment(\.presentationMode) var presentation

    var body: some View {
        NavigationView {
            List {
                ForEach(Array(savedData.keys).sorted(), id: \.self) { key in
                    Section(header: Text(key)) {
                        ForEach(savedData[key]!, id: \.self) { img in
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                        }
                    }
                }
            }
            .navigationBarTitle("Saved Rows & Objects", displayMode: .inline)
            .navigationBarItems(
                // ← Chevron back arrow to dismiss
                leading: Button {
                    presentation.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                },
                // “Reset” stays on the right
                trailing: Button("Reset") {
                    presentation.wrappedValue.dismiss()
                    onReset()
                }
            )
        }
    }
}


