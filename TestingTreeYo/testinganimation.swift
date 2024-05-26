//
//  testinganimation.swift
//  TestingTreeYo
//
//  Created by Matthew Rispler on 26/5/2024.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct testinganimation: View {
    var body: some View {
        ZStack {
            // Check if the Package.reality file exists in the bundle
            if let filePath = Bundle.main.path(forResource: "Package", ofType: "reality") {
                print("Package.reality file found at path: \(filePath)")
                Model3D(named: "Package", bundle: realityKitContentBundle)
                    .padding(.bottom, 40)
                    .onAppear {
                        print("Attempting to load Model3D named 'Package' from the bundle.")
                    }
                    .onDisappear {
                        print("Model3D view disappeared.")
                    }
            } else {
                print("Package.reality file not found in the bundle.")
                Text("Model not found")
            }

            Text("Hello world")
                .font(.largeTitle) // Corrected .extraLargeTitle to .largeTitle
        }
        .padding()
        .onAppear {
            print("testinganimation view appeared.")
        }
        .onDisappear {
            print("testinganimation view disappeared.")
        }
    }
}

#Preview(windowStyle: .automatic) {
    testinganimation()
}

