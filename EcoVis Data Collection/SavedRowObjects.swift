//
//  SavedRowObjects.swift
//  EcoVis Data Collection
//
//  Created by Aryaman Dayal on 4/30/25.
//

import SwiftUI

// Displays saved images grouped by "Row R Object O"
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
                leading: Button("Done") { presentation.wrappedValue.dismiss() },
                trailing: Button("Reset") {
                    presentation.wrappedValue.dismiss()
                    onReset()
                }
            )
        }
    }
}
