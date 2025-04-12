//
//  provaApp.swift
//  prova
//
//  Created by Davide Perrotta on 11/04/25.
//

import SwiftUI

@main
struct provaApp: App {
    
    @StateObject var health: HealthManager = .shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(health)
        }
    }
}
