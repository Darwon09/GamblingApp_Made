//
//  ContentView.swift
//  GamblingApp
//


import SwiftUI
import SwiftData

struct ContentView: View {

    var body: some View {
        loginview()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
