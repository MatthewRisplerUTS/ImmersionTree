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
    private let targetScale: CGFloat = 9
    private let initialScale: CGFloat = 0.5
    private let growthThreshold: CGFloat = 80 // Heart rate threshold for stopping animation
    private let growthIncrement: CGFloat = 0.01
    private let shrinkIncrement: CGFloat = 0.005 // Slower shrink increment
    @State private var treeEntity: Entity? = nil
    @State private var playbackController: AnimationPlaybackController? = nil
    private let animationSpeed: Float = 0.05 // Speed factor for slowing down the animation
    @State private var hrVals = [HeartRate]()
    @State private var count: Int = 0
    @State private var timer: Timer?
    @State private var isGrowing: Bool = false
    @State private var isShrinking: Bool = false
    @State private var latestSessionKey: String?

    var body: some View {
        VStack {
            TreeView(modelScale: $modelScale, treeEntity: $treeEntity, playbackController: $playbackController, animationSpeed: animationSpeed)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    findLatestSession()
                }
                .onDisappear {
                    stopTimer()
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

    private func findLatestSession() {
        let ref = Database.database().reference(withPath: "sessions").queryOrderedByKey().queryLimited(toLast: 1)
        ref.observeSingleEvent(of: .value) { snapshot in
            if let latestSession = snapshot.children.allObjects.first as? DataSnapshot {
                self.latestSessionKey = latestSession.key
                startTimer()
            }
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            fetchLatestHeartRate()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func fetchLatestHeartRate() {
        guard let sessionKey = latestSessionKey else { return }

        let ref = Database.database().reference(withPath: "sessions/\(sessionKey)").queryOrdered(byChild: "timestamp").queryLimited(toLast: 1)
        ref.observeSingleEvent(of: .value) { snapshot in
            if let snapshot = snapshot.children.allObjects.first as? DataSnapshot,
               let dict = snapshot.value as? [String: Any],
               let timestamp = dict["timestamp"] as? Int,
               let heartRate = dict["heartRate"] as? Double {
                let hrItem = HeartRate(time: timestamp, rate: heartRate)
                
                // Ensure thread-safe updates to hrVals and avoid duplicate entries
                DispatchQueue.main.async {
                    if self.hrVals.isEmpty || self.hrVals.last?.time != timestamp {
                        self.hrVals.append(hrItem)
                        self.count += 1  // Increment the count for the x-axis domain
                        print("Fetched Heart Rate: \(heartRate), Timestamp: \(timestamp)")
                        self.updateHeartRateBasedOnLatest(rate: heartRate)
                    }
                }
            }
        }
    }

    private func updateHeartRateBasedOnLatest(rate: Double) {
        print("Checking heart rate: \(rate)")
        if rate < Double(growthThreshold) {
            print("Heart rate \(rate) is below threshold \(growthThreshold) - incrementing tree growth")
            if !isGrowing {
                print("Starting tree growth and animation")
                isGrowing = true
                isShrinking = false
                startAnimation()
                incrementTreeGrowth()
            }
        } else {
            print("Heart rate \(rate) is above threshold \(growthThreshold) - stopping animation and shrinking tree")
            stopAnimation()
            if !isShrinking {
                isShrinking = true
                isGrowing = false
                decrementTreeGrowth()
            }
        }
    }

    private func incrementTreeGrowth() {
        print("Incrementing tree growth")
        if !isGrowing {
            print("Tree growth is stopped")
            return
        }
        let newScale = min(modelScale + growthIncrement, targetScale)
        if modelScale != newScale {
            print("Updating tree scale from \(modelScale) to \(newScale)")
            modelScale = newScale
            updateTreeScale(to: modelScale)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if self.isGrowing {
                    self.incrementTreeGrowth()
                }
            }
        } else {
            print("Tree has reached target scale or cannot grow further")
            isGrowing = false
        }
    }

    private func decrementTreeGrowth() {
        print("Decrementing tree growth")
        if !isShrinking {
            print("Tree shrinking is stopped")
            return
        }
        let newScale = max(modelScale - shrinkIncrement, initialScale)
        if modelScale != newScale {
            print("Updating tree scale from \(modelScale) to \(newScale)")
            modelScale = newScale
            updateTreeScale(to: modelScale)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { // Slower interval for shrinking
                if self.isShrinking {
                    self.decrementTreeGrowth()
                }
            }
        } else {
            print("Tree has reached initial scale or cannot shrink further")
            isShrinking = false
        }
    }

    private func updateTreeScale(to scale: CGFloat) {
        print("Updating tree scale to \(scale)")
        if let tree = treeEntity {
            let scaleVector = SIMD3<Float>(repeating: Float(scale))
            tree.move(to: Transform(scale: scaleVector), relativeTo: tree.parent, duration: 2, timingFunction: .easeInOut)
        }
    }

    private func startAnimation() {
        if let controller = playbackController {
            print("Starting animation")
            controller.resume()
        } else {
            print("No playback controller available to start animation")
        }
    }

    private func stopAnimation() {
        print("Stopping animation")
        playbackController?.pause()
        isGrowing = false
    }

    private func spawnNewTreeNearby() {
        Task {
            do {
                let newTree = try await Entity(named: "Working_Tree")
                await MainActor.run {
                    newTree.position = SIMD3<Float>(x: 1.0, y: 0.0, z: 1.0)
                    treeEntity?.parent?.addChild(newTree)
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
                    playbackController = tree.playAnimation(animationResource)
                    playbackController?.speed = animationSpeed
                    print("Animation playback controller created")
                } else {
                    print("No available animations for the tree model")
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

