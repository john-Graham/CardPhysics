//
//  ContentView.swift
//  CardPhysicsApp
//
//  Created by John D Graham on 2/7/26.
//

import SwiftUI
import CardPhysicsSandbox

struct ContentView: View {
    var body: some View {
        CardPhysicsView()
            .statusBarHidden()
    }
}

#Preview {
    ContentView()
}
