import SwiftUI
import RealityKit
import RealityKitContent
import Charts

struct HeartRate: Identifiable {
    let id = UUID()
    let time: Int
    let rate: Double
}

struct ImmersiveView: View {
    @State private var modelScale: CGFloat = 0.0002
    private let targetScale: CGFloat = 0.008
    private let initialScale: CGFloat = 0.0002
    private let growthThreshold: Double = 80
    private let growthIncrement: CGFloat = 0.0001  // Increment the scale by this amount
    @State private var treeEntity: Entity? = nil
    @State private var hrVals = [HeartRate(time: 0, rate: 120.786)]
    @State private var count: Int = 1

    var body: some View {
        VStack {
            RealityView { content in
                do {
                    guard let skyBoxEntity = createSkyBox() else{
                                    print("Error")
                                    return
                                }
                                
                                content.add(skyBoxEntity)
                    let tree = try await Entity(named: "Old_Tree", in: realityKitContentBundle)
                    treeEntity = tree
                    treeEntity?.scale = SIMD3<Float>(repeating: Float(modelScale))
                    content.add(tree)
                    
                } catch {
                    print("Error loading the tree model: \(error)")
                }
            }
            .frame(height: 300)

            GroupBox("Heart Rate Monitor:") {
                Chart {
                    ForEach(hrVals) { HeartRate in
                        LineMark(x: .value("Time", HeartRate.time), y: .value("Heart Rate", HeartRate.rate))
                    }
                }
                .chartXScale(domain: count > 20 ? [count-20, count] : [0, 20])
                .foregroundStyle(.red)
            }

            Button("Update Heart Rate") {
                updateHeartRate()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            Text("Current heart rate: \(hrVals.last?.rate ?? 0, specifier: "%.2f") BPM")
        }
    }

    private func updateHeartRate() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let newRate = Double.random(in: 60...120)
            hrVals.append(HeartRate(time: count, rate: newRate))
            if hrVals.count > 20 {
                hrVals.removeFirst()
            }
            count += 1

            // Check if the current heart rate allows for tree growth or needs scale resetting
            if let currentRate = hrVals.last?.rate {
                if currentRate < growthThreshold {
                    incrementTreeGrowth()
                } else {
                    resetTreeScale()
                }
            }
        }
    }
    
    private func createSkyBox() -> Entity? {
            let largeSphere = MeshResource.generateSphere(radius: 1000)
            
            var skyBoxMaterial = UnlitMaterial()
            
            
            do{
                let texture = try  TextureResource.load(named: "mossy_forest")
                skyBoxMaterial.color = .init(texture: .init(texture))
            } catch{
                print("error")
            }
            
            let skyBoxEntity = Entity()
            skyBoxEntity.components.set(ModelComponent(mesh: largeSphere, materials: [skyBoxMaterial]))
            
            skyBoxEntity.scale *= .init(x:-1, y: 1, z: 1)
            
            return skyBoxEntity
            
        }

    private func incrementTreeGrowth() {
        let newScale = min(modelScale + growthIncrement, targetScale)
        if modelScale != newScale {
            modelScale = newScale
            updateTreeScale(to: modelScale)
        }
    }
    
    private func resetTreeScale() {
        withAnimation(.easeInOut(duration: 2)) {
            modelScale = initialScale
            updateTreeScale(to: modelScale)
        }
    }
    
    private func updateTreeScale(to scale: CGFloat) {
        if let tree = treeEntity {
            let scaleVector = SIMD3<Float>(repeating: Float(scale))
            tree.move(to: Transform(scale: scaleVector), relativeTo: tree.parent, duration: 2, timingFunction: .easeInOut)
        }
    }
}

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}


