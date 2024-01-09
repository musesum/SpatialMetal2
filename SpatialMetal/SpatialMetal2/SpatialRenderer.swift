// created by musesum.

import Metal
import MetalKit
import ARKit
import Spatial
import CompositorServices
import MuVision

class SpatialRenderer: RenderLayer {

    var starsNode: RenderLayerNode!
    var earthNode: RenderLayerNode!

    override init(_ layerRenderer: LayerRenderer) {
        super.init(layerRenderer)
        starsNode = RenderLayerNode(self)
        earthNode = RenderLayerNode(self)
        setDelegate(self)
        startRenderLoop()
    }
}

extension SpatialRenderer: RenderLayerProtocol {

    func makeResources() {
        // stars is from 8k_stars_milky_way.jpg via
        // https://www.solarsystemscope.com/textures/ -- CC Atribution 4.0
        starsNode.eyeBuf = UniformEyeBuf(device, "stars", far: true)
        earthNode.eyeBuf = UniformEyeBuf(device, "earth", far: false)
        do {
            let earthDepthRender = DepthRender(.back, .counterClockwise, .less   , true)
            let starsDepthRender = DepthRender(.back, .clockwise       , .greater, true)
            try earthNode.mesh = MeshTexEllipse(device, "Earth", earthDepthRender, radius: 2.5, inward: false)
            try starsNode.mesh = MeshTexEllipse(device, "Stars", starsDepthRender, radius: 3.0, inward: true )
        } catch {
            fatalError("\(#function) Error: \(error)")
        }
    }
    func makePipeline() {

        earthNode.makePipeline("vertexEarth", "fragmentEarth")
        starsNode.makePipeline("vertexStars", "fragmentStars")
    }

    /// Update projection and rotation
    func updateUniforms(_ layerDrawable: LayerRenderer.Drawable) {

        rotation += 0.003

        let translateMatrix = translateQuat(x: 0.0, y: 0.0, z: -8.0)
        starsNode.eyeBuf?.updateEyeUniforms(layerDrawable, translateMatrix)

        let rotationAxis = SIMD3<Float>(0, 1, 0)
        let earthRotation = rotateQuat(radians: rotation, axis: rotationAxis)
        let earthMatrix = translateMatrix * earthRotation
        earthNode.eyeBuf?.updateEyeUniforms(layerDrawable, earthMatrix)
    }

    func renderLayer(_ commandBuf    : MTLCommandBuffer,
                     _ layerDrawable : LayerRenderer.Drawable) {

        let renderPass = makeRenderPass(layerDrawable: layerDrawable)
        guard let renderCmd = commandBuf.makeRenderCommandEncoder(
            descriptor: renderPass) else { fatalError(#function) }

        renderCmd.label = "Spatial"
        renderCmd.pushDebugGroup("Spatial")

        setViewMappings(renderCmd, layerDrawable)
        updateUniforms(layerDrawable)

        starsNode.drawLayer(renderCmd)
        earthNode.drawLayer(renderCmd)

        renderCmd.popDebugGroup()
        renderCmd.endEncoding()
        layerDrawable.encodePresent(commandBuffer: commandBuf)
        commandBuf.commit()
    }

}

