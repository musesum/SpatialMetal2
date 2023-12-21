
import MetalKit
import simd

// Generic matrix math utility functions
func rotateQuat(radians: Float, axis: SIMD3<Float>) -> matrix_float4x4 {
    let rotateQuat = normalize(axis)
    let ct = cosf(radians)
    let st = sinf(radians)
    let ci = 1 - ct
    let x = rotateQuat.x, y = rotateQuat.y, z = rotateQuat.z
    let col0 = vector_float4(x*x*ci + ct  , y*x*ci + z*st, z*x*ci - y*st, 0)
    let col1 = vector_float4(x*y*ci - z*st, y*y*ci +   ct, z*y*ci + x*st, 0)
    let col2 = vector_float4(x*z*ci + y*st, y*z*ci - x*st, z*z*ci + ct  , 0)
    let col3 = vector_float4(            0,             0,             0, 1)
    return matrix_float4x4.init(columns:(col0,col1,col2,col3))
}

func translateQuat(x: Float, y: Float, z: Float) -> matrix_float4x4 {

    return matrix_float4x4.init(columns:(vector_float4(1, 0, 0, 0),
                                         vector_float4(0, 1, 0, 0),
                                         vector_float4(0, 0, 1, 0),
                                         vector_float4(x, y, z, 1)))
}

func radians_from_degrees(_ degrees: Float) -> Float {
    return (degrees / 180) * .pi
}

