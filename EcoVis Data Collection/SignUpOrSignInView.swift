//
//  SignUpOrSignInView.swift
//  EcoVis Data Collection
//
//  Created by Aryaman Dayal on 12/21/24.
//

import SwiftUI

struct SignUpOrSignInView: View {
    @State private var isSignUp = true

    var body: some View {
        VStack {
            if isSignUp {
                SignUpView()
            } else {
                SignInView()
            }

            Button {
                isSignUp.toggle()
            } label: {
                if isSignUp {
                    Text("Already have an account? Sign In")
                } else {
                    Text("Don't have an account? Sign Up")
                }
            }
            .padding()
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
