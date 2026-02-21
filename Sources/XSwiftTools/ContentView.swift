import SwiftCrossUI
import XSwiftToolsSupport

struct ContentView: View {
    @Environment(TopBarViewModel.self) var topBarModel
    
    var body: some View {
        VStack {
            TopBar()
            if let selected = topBarModel.selected {
                switch selected {
                    case .test: TestView()
                    case .sbun(let name):
                        SBunAppView()
                }
            } else {
                Text("please select a target")
                .frame(maxHeight: .infinity)
            }
        }
        .padding()
        .frame(alignment: .top)
    }
}
