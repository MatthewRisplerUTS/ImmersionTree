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
    @State private var modelScale: CGFloat = 0.0002
    private let targetScale: CGFloat = 0.008
    private let initialScale: CGFloat = 0.0002
    private let growthThreshold: Double = 80
    private let growthIncrement: CGFloat = 0.0001
    @State private var treeEntity: Entity? = nil
    @State private var playbackController: AnimationPlaybackController? = nil
    @State private var hrVals = [HeartRate]()
    @State private var count: Int = 0

    var body: some View {
        VStack {
            RealityView { content in
                do {
                    let tree = try await Entity(named: "growing_tree_no_branch_ani")
                    treeEntity = tree
                    treeEntity?.scale = SIMD3<Float>(repeating: Float(modelScale))
                    content.add(tree)

                    print("Tree loaded successfully.")

                    // Extract animations from the tree entity
                    if let animationResource = tree.availableAnimations.first {
                        // Create an AnimationPlaybackController to manage the animation playback (just for testing)
                        playbackController = tree.playAnimation(animationResource.repeat())
                    } else {
                        print("No animations found in the tree entity.")
                    }
                } catch {
                    print("Error loading the tree model: \(error)")
                }
            }
            .frame(height: 300)

            GroupBox("Heart Rate Monitor:") {
                Chart {
                    ForEach(hrVals) { heartRate in
                        LineMark(x: .value("Time", heartRate.time), y: .value("Heart Rate", heartRate.rate))
                    }
                }
                .chartXScale(domain: count > 20 ? [count-20, count] : [0, 20])
                .foregroundStyle(.red)
            }

            Button("Start Monitoring") {
                print("Start Monitoring Button Pressed")
                setupFirebaseListener()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            Text("Current heart rate: \(hrVals.last?.rate ?? 0, specifier: "%.2f") BPM")
        }
    }

    private func setupFirebaseListener() {
        print("Setting up Firebase Listener")
        let ref = Database.database().reference(withPath: "heartRates")
        ref.queryOrdered(byChild: "timestamp").observe(.value) { snapshot in
            print("Firebase data received")
            var newItems: [HeartRate] = []
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let dict = snapshot.value as? [String: Any],
                   let timestamp = dict["timestamp"] as? Int,
                   let heartRate = dict["heartRate"] as? Double {
                    let hrItem = HeartRate(time: timestamp, rate: heartRate)
                    newItems.append(hrItem)
                    print("HeartRate updated: \(hrItem.rate) at time \(hrItem.time)")
                }
            }
            hrVals = newItems
            if hrVals.isEmpty {
                print("No heart rate data found.")
            }
            updateHeartRateBasedOnLatest()
        }
    }

    private func updateHeartRateBasedOnLatest() {
        guard let lastRate = hrVals.last else {
            print("No latest heart rate available.")
            return
        }
        count += 1
        print("Updating heart rate based on latest: \(lastRate.rate)")

        if lastRate.rate < growthThreshold {
            incrementTreeGrowth()
        } else {
            resetTreeScale()
        }
    }

    private func incrementTreeGrowth() {
        let newScale = min(modelScale + growthIncrement, targetScale)
        if modelScale != newScale {
            modelScale = newScale
            print("Tree growth incremented to scale: \(newScale)")
            updateTreeScale(to: modelScale)
        }
    }

    private func resetTreeScale() {
        withAnimation(.easeInOut(duration: 2)) {
            modelScale = initialScale
            print("Tree scale reset to initial scale.")
            updateTreeScale(to: modelScale)
        }
    }

    private func updateTreeScale(to scale: CGFloat) {
        if let tree = treeEntity {
            let scaleVector = SIMD3<Float>(repeating: Float(scale))
            print("Updating tree scale to: \(scale)")
            tree.move(to: Transform(scale: scaleVector), relativeTo: tree.parent, duration: 2, timingFunction: .easeInOut)
        }
    }
}

#Preview {
    ImmersiveView()
        .previewLayout(.sizeThatFits)
}

