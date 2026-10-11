//
//  Explosive_PotatoeApp.swift
//  Explosive Potatoe
//
//  Created by cam  on 10/7/26.
//

import SwiftUI

@main
struct Explosive_PotatoeApp: App {
    init() {
        Theme.registerFonts()
        SFX.preload()
        Haptics.prepare()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
