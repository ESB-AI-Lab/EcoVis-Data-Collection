//
//  GoogleSignInView.swift
//  EcoVis Data Collection
//
//  Created by Kan on 7/31/25.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import FirebaseCore
import FirebaseAuth

struct GoogleSignInView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Welcome to Avocado Vision")
                .font(.title)
                .padding()

            Button(action: signInWithGoogle) {
                HStack {
                    Image(systemName: "globe")
                    Text("Sign in with Google")
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
                .padding(.horizontal)
            }

            Spacer()
        }
    }

    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("No rootViewController found.")
            return
        }

        GIDSignIn.sharedInstance.signIn(
            withPresenting: rootViewController
        ) { result, error in
            guard let user = result?.user else { return }
            let idToken = user.idToken?.tokenString
            let accessToken = user.accessToken.tokenString

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken ?? "",
                accessToken: accessToken
            )

            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    print("Firebase sign-in failed: \(error.localizedDescription)")
                } else {
                    print("User signed in: \(result?.user.email ?? "")")
                }
            }
        }
    }
}
