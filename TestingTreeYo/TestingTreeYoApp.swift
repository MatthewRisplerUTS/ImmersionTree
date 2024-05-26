import SwiftUI
import Firebase

@main
struct TestingTreeYoApp: App {
    
    @State private var viewModel = ViewModel()
    @State var immersionMode: ImmersionStyle = .progressive

    // Add an initializer to configure Firebase
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }.windowStyle(.plain)

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
        .immersionStyle(selection: $immersionMode, in: .progressive)
        .defaultSize(CGSize(width: 1200, height: 450))
    }
}


