//
//  CardPhysicsAppApp.swift
//  CardPhysicsApp
//
//  Created by John D Graham on 2/7/26.
//

import SwiftUI

@main
struct CardPhysicsAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Lock to landscape orientation
                    UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                }
        }
    }
}
