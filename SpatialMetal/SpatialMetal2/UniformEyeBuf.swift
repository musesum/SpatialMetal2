// created by musesum

import Spatial
import CompositorServices

protocol UniformEyeDelegate {
    func eyeUniforms(_ projection: matrix_float4x4,
                     _ viewModel: matrix_float4x4) -> Any
}


/// triple buffered Uniform for either 1 or 2 eyes
class UniformEyeBuf<Item> {
    //typealias UniEyes = UniformEyes
    public struct UniEyes {
        // a uniform for each eye
        var eye: (Item, Item)
    }

    let uniformSize: Int
    let tripleUniformSize: Int
    let uniformBuf: MTLBuffer
    let infinitelyFar: Bool // infinit distance for stars (same background for both eyes)

    var uniformEyes: UnsafeMutablePointer<UniEyes>
    var tripleOffset = 0
    var tripleIndex = 0
    var delegate: UniformEyeDelegate

    init(_ delegate: UniformEyeDelegate,
         _ device: MTLDevice,
         _ label: String,
         infinitelyFar: Bool) {

        // round up to multiple of 256 bytes
        self.delegate = delegate
        self.uniformSize = (MemoryLayout<UniEyes>.size + 0xFF) & -0x100
        self.tripleUniformSize = uniformSize * TripleBufferCount
        self.infinitelyFar = infinitelyFar
        self.uniformBuf = device.makeBuffer(length: tripleUniformSize, options: [.storageModeShared])!
        self.uniformBuf.label = label

        uniformEyes = UnsafeMutableRawPointer(uniformBuf.contents())
            .bindMemory(to: UniEyes.self, capacity: 1)
    }

    /// Update projection and rotation
    func updateUniforms(_ layerDrawable: LayerRenderer.Drawable,
                        _ modelMat: simd_float4x4) {

        let anchor = layerDrawable.deviceAnchor
        updateTripleBufferedUniform()

        let deviceAnchor = anchor?.originFromAnchorTransform ?? matrix_identity_float4x4

        self.uniformEyes[0].eye.0 = uniformForEyeIndex(0)
        if layerDrawable.views.count > 1 {
            self.uniformEyes[0].eye.1 = uniformForEyeIndex(1)
        }
        func updateTripleBufferedUniform() {

            tripleIndex = (tripleIndex + 1) % TripleBufferCount
            tripleOffset = uniformSize * tripleIndex
            let uniformPtr = uniformBuf.contents() + tripleOffset
            uniformEyes = UnsafeMutableRawPointer(uniformPtr)
                .bindMemory(to: UniEyes.self, capacity: 1)
        }

        func uniformForEyeIndex(_ index: Int) -> Item {

            let view = layerDrawable.views[index]
            
            let viewMatrix = (deviceAnchor * view.transform).inverse
            
            let projection = ProjectiveTransform3D(
                leftTangent   : Double(view.tangents[0]),
                rightTangent  : Double(view.tangents[1]),
                topTangent    : Double(view.tangents[2]),
                bottomTangent : Double(view.tangents[3]),
                nearZ         : Double(layerDrawable.depthRange.y),
                farZ          : Double(layerDrawable.depthRange.x),
                reverseZ      : true)

            var viewModel = viewMatrix * modelMat
            
            if infinitelyFar {
                viewModel.columns.3 = simd_make_float4(0.0, 0.0, 0.0, 1.0)
            }
            let eyeUniforms = delegate.eyeUniforms(.init(projection), viewModel)
            return eyeUniforms as! Item
        }
    }
    func setMappings(_ layerDrawable : LayerRenderer.Drawable,
                     _ viewports     : [MTLViewport],
                     _ renderCommand : MTLRenderCommandEncoder) {

        setOptionalStereoAmplification()
        renderCommand.setVertexBuffer(uniformBuf,
                                      offset: tripleOffset,
                                      index: Vertexi.uniforms)

        func setOptionalStereoAmplification() {
            if layerDrawable.views.count > 1 {
                var viewMappings = (0 ..< layerDrawable.views.count).map {
                    MTLVertexAmplificationViewMapping(
                        viewportArrayIndexOffset: UInt32($0),
                        renderTargetArrayIndexOffset: UInt32($0))
                }
                renderCommand.setVertexAmplificationCount(
                    viewports.count,
                    viewMappings: &viewMappings)
            }
        }
    }

}
