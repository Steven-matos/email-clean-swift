//
//  EmailCleanApp.swift
//  EmailClean
//
//  Created by Steven Matos on 7/4/25.
//

import SwiftUI

@main
struct EmailCleanApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
