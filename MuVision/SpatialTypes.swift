//  Created by musesum on 9/17/23.

import simd

public struct VertexIndex {
    static public let position = 0
    static public let texcoord = 1
    static public let normal   = 2
    static public let uniforms = 3
}

public struct TextureIndex {
    static public let colori = 0
}

public enum RendererError: Error {
    case badVertex
}

public struct UniformEye {

    var projection: matrix_float4x4
    var viewModel: matrix_float4x4

    public init(_ projection: matrix_float4x4,
                _ viewModel: matrix_float4x4) {

        self.projection = projection
        self.viewModel = viewModel
    }
}

public struct UniformEyes {
    // a uniform for each eye
    public var eye: (UniformEye, UniformEye)
}
