//
//  ContentView.swift
//  TestingTreeYo
//
//  Created by Matthew Rispler on 9/4/2024.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    var body: some View {
        VStack(alignment: .leading, content: {
            Text("Welcome to Psithurism")
                .font(.extraLargeTitle2)
        })
        .padding(50)
        .glassBackgroundEffect()
        .onAppear(perform: {
            Task {
                await openImmersiveSpace(id: "ImmersiveSpace")
            }
        })
        Button("Spawn Tree") {
            
        }
    }
}

#Preview {
    ContentView()
}
