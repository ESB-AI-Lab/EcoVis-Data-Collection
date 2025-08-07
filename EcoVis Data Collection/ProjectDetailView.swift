//
//  ProjectDetailView.swift
//  EcoVis Data Collection
//
//  Created by Aryaman Dayal on 6/5/25.
//
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ProjectDetailView: View {
    let projectName: String
    
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    @State private var objectModeURLs: [String]?
    @State private var rowModeURLs: [String: [String]]?
    
    private let db = Firestore.firestore()
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading…")
            }
            else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            else if let urls = objectModeURLs {
                RemoteSavedImagesView(imageURLs: urls)
            }
            else if let rows = rowModeURLs {
                RemoteSavedRowObjectsView(rowImageURLs: rows)
            }
            else {
                Text("No images found for \(projectName).")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .navigationTitle(projectName)
        .onAppear {
            fetchProjectData()
        }
    }
    
    private func fetchProjectData() {
        guard let uid = Auth.auth().currentUser?.uid else {
            self.errorMessage = "Missing user ID."
            self.isLoading = false
            return
        }
        
        let projectDocRef = db
            .collection("users")
            .document(uid)
            .collection("projects")
            .document(projectName)
        
        projectDocRef.getDocument { snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    return
                }
                
                guard let data = snapshot?.data() else {
                    self.errorMessage = "No project data."
                    self.isLoading = false
                    return
                }
                
                // Check if “objects” field exists (object mode)
                if let objectURLs = data["objects"] as? [String] {
                    self.objectModeURLs = objectURLs
                    self.isLoading = false
                } else {
                    // Otherwise, treat as row mode: fetch subcollection “rows”
                    projectDocRef
                        .collection("rows")
                        .getDocuments { rowSnapshot, rowError in
                            DispatchQueue.main.async {
                                if let rowError = rowError {
                                    self.errorMessage = rowError.localizedDescription
                                    self.isLoading = false
                                    return
                                }
                                
                                var temp: [String: [String]] = [:]
                                if let docs = rowSnapshot?.documents {
                                    for doc in docs {
                                        let key = doc.documentID
                                        if let urls = doc.data()["images"] as? [String] {
                                            temp[key] = urls
                                        }
                                    }
                                }
                                // Even if there are no documents, temp is set (possibly empty)
                                self.rowModeURLs = temp
                                self.isLoading = false
                            }
                        }
                }
            }
        }
    }
}

