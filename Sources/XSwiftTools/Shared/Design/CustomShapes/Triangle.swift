import SwiftCrossUI
import Foundation

struct Triangle: @preconcurrency Shape {
    func path(in bounds: SwiftCrossUI.Path.Rect) -> SwiftCrossUI.Path {
        let side = min(bounds.width, bounds.height)
        let center = bounds.center
        let circumradius = side / 2.0
        let cornerRadius = side * 0.08 // adjust ratio to taste
        
        return roundedTrianglePath(
            center: center,
            circumradius: circumradius,
            cornerRadius: cornerRadius
        )
    }
    
    func roundedTrianglePath(
        center: SIMD2<Double>,
        circumradius: Double,
        cornerRadius: Double
    ) -> Path {
        let R = circumradius
        let cr = cornerRadius
        
        // Vertex angles (clockwise from right, screen coords y-down)
        // 0 = right, 2π/3 = lower-left, 4π/3 = upper-left
        let vertexAngles: [Double] = [0, 2.0 * .pi / 3.0, 4.0 * .pi / 3.0]
        
        // Arc centers: vertices inset toward centroid by 2*cr along bisector
        let arcCenters = vertexAngles.map { angle in
            SIMD2<Double>(
                x: center.x + (R - 2.0 * cr) * cos(angle),
                y: center.y + (R - 2.0 * cr) * sin(angle)
            )
        }
        
        // Each arc spans 2π/3 (120°), centered on the outward direction
        // from centroid through vertex. Arc: [vertexAngle - π/3, vertexAngle + π/3]
        func normalizedAngle(_ a: Double) -> Double {
            var a = a
            if a < 0 { a += 2.0 * .pi }
            if a >= 2.0 * .pi { a -= 2.0 * .pi }
            return a
        }
        
        let arcStart = vertexAngles.map { normalizedAngle($0 - .pi / 3.0) }
        let arcEnd   = vertexAngles.map { normalizedAngle($0 + .pi / 3.0) }
        
        // Point on arc boundary at a given angle
        func arcPoint(_ idx: Int, angle: Double) -> SIMD2<Double> {
            SIMD2<Double>(
                x: arcCenters[idx].x + cr * cos(angle),
                y: arcCenters[idx].y + cr * sin(angle)
            )
        }
        
        // Trace: arc0 → line → arc1 → line → arc2 → line (close)
        return Path()
            .move(to: arcPoint(0, angle: arcStart[0]))
            .addArc(
                center: arcCenters[0], radius: cr,
                startAngle: arcStart[0], endAngle: arcEnd[0], clockwise: true
            )
            .addLine(to: arcPoint(1, angle: arcStart[1]))
            .addArc(
                center: arcCenters[1], radius: cr,
                startAngle: arcStart[1], endAngle: arcEnd[1], clockwise: true
            )
            .addLine(to: arcPoint(2, angle: arcStart[2]))
            .addArc(
                center: arcCenters[2], radius: cr,
                startAngle: arcStart[2], endAngle: arcEnd[2], clockwise: true
            )
            .addLine(to: arcPoint(0, angle: arcStart[0]))
    }
}
