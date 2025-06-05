//  ProjectNamingView.swift
//  EcoVis Data Collection
//
//  Created by Aryaman Dayal on 5/14/25.
//
//

import SwiftUI

struct ProjectNamingView: View {
    @Binding var projectName: String
    @Binding var isUploading: Bool
    var onSave: () -> Void
    @Environment(\.presentationMode) private var presentation

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Name this session")
                    .font(.headline)

                TextField("Project Title", text: $projectName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Spacer()

                if isUploading {
                    ProgressView("Uploading…")
                } else {
                    Button("Save") {
                        presentation.wrappedValue.dismiss()
                        onSave()
                    }
                    .disabled(projectName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationBarTitle("New Project", displayMode: .inline)
            // ← Back arrow on the left that simply dismisses
            .navigationBarItems(leading:
                Button {
                    presentation.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
            )
        }
    }
}



//import SwiftUI
//
//struct ProjectNamingView: View {
//    @Binding var projectName: String
//    @Binding var isUploading: Bool
//    var onSave: () -> Void
//    @Environment(\.presentationMode) private var presentation
//
//    var body: some View {
//        NavigationView {
//            VStack(spacing: 20) {
//                Text("Name this session")
//                    .font(.headline)
//
//                TextField("Project Title", text: $projectName)
//                    .textFieldStyle(.roundedBorder)
//                    .padding(.horizontal)
//
//                Spacer()
//
//                if isUploading {
//                    ProgressView("Uploading…")
//                } else {
//                    Button("Save") {
//                        presentation.wrappedValue.dismiss()
//                        onSave()
//                    }
//                    .disabled(projectName.trimmingCharacters(in: .whitespaces).isEmpty)
//                    .buttonStyle(.borderedProminent)
//
//                    Button("Cancel") {
//                        presentation.wrappedValue.dismiss()
//                    }
//                    .buttonStyle(.bordered)
//                }
//            }
//            .padding()
//            .navigationBarTitle("New Project", displayMode: .inline)
//        }
//    }
//}
