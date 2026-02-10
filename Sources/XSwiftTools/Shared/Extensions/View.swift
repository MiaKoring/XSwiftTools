import SwiftCrossUI

extension View {
    func rotationEffect(degrees: Double) -> some View {
        self.inspect { view in
            #if canImport(AppKitBackend)
            view.rotate(byDegrees: degrees)
            #endif
            // Gtk sadly isn't that easy
        }
    }
    
    func informedLeadingPadding(_ amount: Int) -> some View {
        return PaddingApplicator(child: self, padding: amount)
    }
    
    func splitScrollViewWidth(_ width: Int) -> some View {
        self
            .frame(width: width)
            .environment(\.testListWidth, width)
    }
}

fileprivate struct PaddingApplicator<Child: View>: View {
    @Environment(\.externallyAppliedLeadingPadding) var externalPadding
    let child: Child
    let padding: Int
    
    var body: some View {
        child
            .padding(.leading, padding)
            .environment(\.externallyAppliedLeadingPadding, externalPadding + padding)
    }
}
