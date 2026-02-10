@propertyWrapper
struct UncheckedSendable<V>: @unchecked Sendable {
    var wrappedValue: V
}
