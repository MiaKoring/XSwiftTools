import SwiftCrossUI
import XSwiftToolsSupport

extension EnvironmentValues {
    @Entry var runTest = UncheckedSendable<((TestRunnable) -> Void)?>(wrappedValue: nil)
    @Entry var testListWidth: Int = 0
    @Entry var externallyAppliedLeadingPadding: Int = 0
}
