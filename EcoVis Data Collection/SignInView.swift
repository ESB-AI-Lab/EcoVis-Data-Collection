//
//  SignInView.swift
//  EcoVis Data Collection
//
//  Created by Aryaman Dayal on 12/21/24.
//



//
//  SignInView.swift
//  EcoVis Data Collection
//
//  Created by Aryaman Dayal on 12/21/24.
//

import SwiftUI
import ClerkSDK
import FirebaseFirestore    // ← for Firestore access

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var feedbackMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Sign In")
                .font(.title)

            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Continue") {
                Task { await submit(email: email, password: password) }
            }
            .buttonStyle(.borderedProminent)

            if !feedbackMessage.isEmpty {
                Text(feedbackMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
    }
}

extension SignInView {
    func submit(email: String, password: String) async {
        do {
            // 1) Sign in with Clerk
            try await SignIn.create(strategy: .identifier(email, password: password))

            // 2) On success, write/update the user record in Firestore
            if let user = Clerk.shared.user {
                let db = Firestore.firestore()
                let docRef = db.collection("users").document(user.id)
                let emailAddr = user.primaryEmailAddress?.emailAddress ?? email
                try await docRef.setData([
                    "email": emailAddr,
                    "lastSeen": FieldValue.serverTimestamp()
                ], merge: true)
                print("Firestore: wrote /users/\(user.id)")
            }

        } catch {
            feedbackMessage = "Sign‑in failed: \(error.localizedDescription)"
            print("Sign‑in Error: \(error)")
        }
    }
}

