//
//  ContentView.swift
//  Florida Tides
//
//  Created by Barry Hayes on 10/8/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "smiley")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, Barry!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
