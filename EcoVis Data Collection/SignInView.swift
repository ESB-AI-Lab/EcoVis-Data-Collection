//
//  SignInView.swift
//  EcoVis Data Collection
//
//  Created by Aryaman Dayal on 12/21/24.
//

import SwiftUI
import ClerkSDK

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var feedbackMessage = ""

    var body: some View {
        VStack(spacing: 20) { // Add spacing between elements
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
            try await SignIn.create(strategy: .identifier(email, password: password))
        } catch {
            feedbackMessage = "Sign-in failed: \(error.localizedDescription)"
            print("Sign-in Error: \(error)")
        }
    }
}


