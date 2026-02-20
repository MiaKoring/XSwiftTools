import SwiftCrossUI

struct TestOutput: View {
    let runOutput: String
    
    var body: some View {
        ScrollView {
            Text(runOutput)
                .rotationEffect(degrees: 180)
        }
        .rotationEffect(degrees: 180)
    }
}
