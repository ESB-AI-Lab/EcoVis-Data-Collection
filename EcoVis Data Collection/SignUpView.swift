//
//  SignUpView.swift
//  EcoVis Data Collection
//
//  Created by Aryaman Dayal on 12/21/24.
//



//
//  SignUpView.swift
//  EcoVis Data Collection
//
//  Created by Aryaman Dayal on 12/21/24.
//

import SwiftUI
import ClerkSDK
import FirebaseFirestore    // ← for Firestore access

struct SignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var code = ""
    @State private var isVerifying = false
    @State private var feedbackMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Sign Up")
                .font(.title)

            if isVerifying {
                TextField("Verification Code", text: $code)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Verify") {
                    Task { await verify(code: code) }
                }
                .buttonStyle(.borderedProminent)

            } else {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Continue") {
                    Task { await signUp(email: email, password: password) }
                }
                .buttonStyle(.borderedProminent)
            }

            if !feedbackMessage.isEmpty {
                Text(feedbackMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
    }
}

extension SignUpView {
    func signUp(email: String, password: String) async {
        do {
            let signUp = try await SignUp.create(
                strategy: .standard(emailAddress: email, password: password)
            )
            try await signUp.prepareVerification(strategy: .emailCode)
            isVerifying = true

        } catch {
            feedbackMessage = "Sign‑up failed: \(error.localizedDescription)"
            print("Sign‑up Error: \(error)")
        }
    }

    func verify(code: String) async {
        do {
            guard let signUp = Clerk.shared.client?.signUp else { return }
            try await signUp.attemptVerification(.emailCode(code: code))

            // On successful email verification, also write the new user into Firestore:
            if let user = Clerk.shared.user {
                let db = Firestore.firestore()
                let docRef = db.collection("users").document(user.id)
                let emailAddr = user.primaryEmailAddress?.emailAddress ?? email
                try await docRef.setData([
                    "email": emailAddr,
                    "createdAt": FieldValue.serverTimestamp()
                ], merge: true)
                print("Firestore: created /users/\(user.id)")
            }

        } catch {
            feedbackMessage = "Verification failed: \(error.localizedDescription)"
            print("Verification Error: \(error)")
        }
    }
}


