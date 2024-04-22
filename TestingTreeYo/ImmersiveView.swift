
import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    // Initial scale of the model
    @State private var modelScale: CGFloat = 0.001
    // Target scale value for the model to grow to
    private let targetScale: CGFloat = 0.5
    // Controls whether the tree is growing or not
    @State private var isGrowing = false
    // State to hold the tree entity
    @State private var treeEntity: Entity? = nil

    var body: some View {
        VStack {
            RealityView { content in
                do {
                    let tree = try await Entity(named: "Old_Tree", in: realityKitContentBundle)
                    treeEntity = tree
                    treeEntity?.scale = SIMD3<Float>(repeating: Float(modelScale))
                    content.add(tree)
                } catch {
                    print("Error loading the tree model: \(error)")
                }
            }
            .frame(height: 300)

            // Button to toggle the growth of the tree
            Button("Grow") {
                print("Grow button pressed. Current scale: \(modelScale), isGrowing: \(isGrowing)")
                guard modelScale < targetScale else {
                    print("Model scale \(modelScale) is already at or beyond target \(targetScale)")
                    return
                }
                isGrowing.toggle()
                print("Toggled isGrowing to \(isGrowing)")

                if isGrowing {
                    withAnimation(.easeInOut(duration: 2)) {
                        modelScale = targetScale
                        updateTreeScale(to: modelScale)
                    }
                } else {
                    modelScale = 0.15
                    isGrowing = false
                    updateTreeScale(to: modelScale)
                    print("Reset modelScale to 0.15 and set isGrowing to false")
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
    
    private func updateTreeScale(to scale: CGFloat) {
        if let tree = treeEntity {
            let scaleVector = SIMD3<Float>(repeating: Float(scale))
            tree.move(to: Transform(scale: scaleVector), relativeTo: tree.parent, duration: 2, timingFunction: .easeInOut)
            print("Animating tree scale to \(scale)")
        }
    }
}

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}
