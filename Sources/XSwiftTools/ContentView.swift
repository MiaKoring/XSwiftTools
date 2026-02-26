import SwiftCrossUI
import XSwiftToolsSupport

struct ContentView: View {
    @Environment(TopBarViewModel.self) var topBarModel
    @AppStorage(\.sbunLocation) var sbunLocation
    
    var body: some View {
        VStack {
            TopBar()
            if let selected = topBarModel.selected {
                switch selected {
                    case .test: TestView()
                    case .sbun:
                        SBunAppView()
                }
            } else if sbunLocation == nil {
                Text("please set an sbun location via File>Set SBun Path")
                    .frame(maxHeight: .infinity)
            } else {
                Text("please select a target")
                    .frame(maxHeight: .infinity)
            }
        }
        .padding()
        .frame(alignment: .top)
    }
}
