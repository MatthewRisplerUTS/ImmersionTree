import SwiftUI
import RealityKit
import RealityKitContent
import Charts
import Firebase

struct HeartRate: Identifiable {
    let id = UUID()
    let time: Int
    let rate: Double
}

struct ImmersiveView: View {
    @State private var modelScale: CGFloat = 1
    private let targetScale: CGFloat = 1.02
    private let initialScale: CGFloat = 1
    private let growthThreshold: CGFloat = 80 // Heart rate threshold for stopping animation
    private let growthIncrement: CGFloat = 0.0001
    @State private var treeEntity: Entity? = nil
    @State private var playbackController: AnimationPlaybackController? = nil
    private let animationSpeed: Float = 0.1 // Speed factor for slowing down the animation
    @State private var hrVals = [HeartRate]()
    @State private var count: Int = 0

    var body: some View {
        VStack {
            TreeView(modelScale: $modelScale, treeEntity: $treeEntity, playbackController: $playbackController, animationSpeed: animationSpeed)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    setupFirebaseListener()
                }

            GroupBox("Heart Rate Monitor:") {
                Chart {
                    ForEach(hrVals) { heartRate in
                        LineMark(x: .value("Time", heartRate.time), y: .value("Heart Rate", heartRate.rate))
                    }
                }
                .chartXScale(domain: count > 20 ? [count - 20, count] : [0, 20])
                .foregroundStyle(.red)
            }

            Text("Current heart rate: \(hrVals.last?.rate ?? 0, specifier: "%.2f") BPM")
        }
    }

    private func setupFirebaseListener() {
        let ref = Database.database().reference(withPath: "heartRates")
        ref.queryOrdered(byChild: "timestamp").observe(.value) { snapshot in
            var newItems: [HeartRate] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any],
                   let timestamp = dict["timestamp"] as? Int,
                   let heartRate = dict["heartRate"] as? Double {
                    let hrItem = HeartRate(time: timestamp, rate: heartRate)
                    newItems.append(hrItem)
                }
            }
            hrVals = newItems
            if let lastRate = hrVals.last {
                updateHeartRateBasedOnLatest(rate: lastRate.rate)
            }
        }
    }

    private func updateHeartRateBasedOnLatest(rate: Double) {
        if rate < Double(growthThreshold) {
            incrementTreeGrowth()
        } else {
            stopAnimation()
        }
    }

    private func incrementTreeGrowth() {
        let newScale = min(modelScale + growthIncrement, targetScale)
        if modelScale != newScale {
            modelScale = newScale
            updateTreeScale(to: modelScale)
            if modelScale >= targetScale {
                spawnNewTreeNearby()
                stopAnimation()
            } else if modelScale < targetScale {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    incrementTreeGrowth()
                }
            } else {
                stopTreeGrowth()
            }
        }
    }

    private func updateTreeScale(to scale: CGFloat) {
        if let tree = treeEntity {
            let scaleVector = SIMD3<Float>(repeating: Float(scale))
            tree.move(to: Transform(scale: scaleVector), relativeTo: tree.parent, duration: 2, timingFunction: .easeInOut)
        }
    }

    private func stopAnimation() {
        playbackController?.stop()
    }

    private func stopTreeGrowth() {
        print("Tree has reached its target scale and will stop growing.")
    }

    private func spawnNewTreeNearby() {
        print("Spawning a new tree nearby")
        Task {
            do {
                let newTree = try await Entity(named: "Working_Tree")
                await MainActor.run {
                    newTree.position = SIMD3<Float>(x: 1.0, y: 0.0, z: 1.0)
                    treeEntity?.parent?.addChild(newTree)
                    print("New tree spawned successfully")
                }
            } catch {
                print("Error loading the new tree model: \(error)")
            }
        }
    }
}

struct TreeView: View {
    @Binding var modelScale: CGFloat
    @Binding var treeEntity: Entity?
    @Binding var playbackController: AnimationPlaybackController?
    var animationSpeed: Float

    var body: some View {
        RealityView { content in
            do {
                let tree = try await Entity(named: "Working_Tree")
                treeEntity = tree
                treeEntity?.scale = SIMD3<Float>(repeating: Float(modelScale))
                treeEntity?.position = SIMD3<Float>(x: 0, y: 0, z: 0)
                content.add(tree)

                if let animationResource = tree.availableAnimations.first {
                    playbackController = tree.playAnimation(animationResource.repeat())
                    playbackController?.speed = animationSpeed
                }
            } catch {
                print("Error loading the tree model: \(error)")
            }
        }
    }
}

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}

