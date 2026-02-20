import SwiftCrossUI

struct SBunAppView: View {
    @Environment(SBunViewModel.self) var viewModel
    
    var body: some View {
        ScrollView {
            Text(viewModel.output)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
