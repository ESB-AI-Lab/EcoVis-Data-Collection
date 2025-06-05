//  HistoryView.swift
//  EcoVis Data Collection
//
//  Created by Aryaman Dayal on 6/5/25.

import SwiftUI
import FirebaseFirestore
import ClerkSDK

struct HistoryView: View {
    @State private var projectNames: [String] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading projects…")
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            } else if projectNames.isEmpty {
                Text("No previous projects found.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(projectNames, id: \.self) { projectName in
                    NavigationLink(destination: ProjectDetailView(projectName: projectName)) {
                        Text(projectName)
                    }
                }
            }
        }
        .navigationTitle("History")
        .onAppear {
            loadProjectNames()
        }
    }
    
    private func loadProjectNames() {
        guard let uid = Clerk.shared.user?.id else {
            errorMessage = "Missing user ID."
            isLoading = false
            return
        }
        
        db.collection("users")
            .document(uid)
            .collection("projects")
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                    } else if let docs = snapshot?.documents {
                        self.projectNames = docs.map { $0.documentID }.sorted()
                    }
                    self.isLoading = false
                }
            }
    }
}
