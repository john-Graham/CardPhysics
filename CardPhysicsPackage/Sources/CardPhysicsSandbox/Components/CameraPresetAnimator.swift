import Foundation
import simd
import CardEngine

@MainActor
enum CameraPresetAnimator {
    static func animate(
        fromPosition: SIMD3<Float>,
        fromTarget: SIMD3<Float>,
        toPosition: SIMD3<Float>,
        toTarget: SIMD3<Float>,
        duration: Double = 0.45,
        update: (SIMD3<Float>, SIMD3<Float>) -> Void
    ) async {
        let stepCount = max(1, Int((duration / 0.016).rounded()))
        for step in 1...stepCount {
            if Task.isCancelled { return }
            let t = Float(step) / Float(stepCount)
            let easedT = t * t * (3.0 - (2.0 * t))
            update(
                lerp(fromPosition, toPosition, t: easedT),
                lerp(fromTarget, toTarget, t: easedT)
            )
            try? await Task.sleep(for: .milliseconds(16))
        }

        update(toPosition, toTarget)
    }

    private static func lerp(_ a: SIMD3<Float>, _ b: SIMD3<Float>, t: Float) -> SIMD3<Float> {
        a + (b - a) * t
    }
}
