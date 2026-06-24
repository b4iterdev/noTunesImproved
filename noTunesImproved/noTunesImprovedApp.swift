//
//  noTunesImprovedApp.swift
//  noTunesImproved
//
//  Created by Nguyen Minh Thai on 23/6/26.
//

import SwiftUI

@main
struct noTunesImprovedApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
