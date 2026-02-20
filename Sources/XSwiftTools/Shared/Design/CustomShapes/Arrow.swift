import SwiftCrossUI

struct Arrow: @preconcurrency Shape {
    func path(in bounds: SwiftCrossUI.Path.Rect) -> SwiftCrossUI.Path {
        Path()
        .move(to: SIMD2(0, 0))
        .addLine(to: SIMD2(0.5 * bounds.width, 0.5 * bounds.height))
        .addLine(to: SIMD2(0, bounds.height))
    }
}
