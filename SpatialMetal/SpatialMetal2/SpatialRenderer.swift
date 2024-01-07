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
            try earthNode.mesh = MeshTexEllipse(device, texName: "Earth", compare: .less,    radius: 2.5, inward: false, winding: .counterClockwise)
            try starsNode.mesh = MeshTexEllipse(device, texName: "Stars", compare: .greater, radius: 3.0, inward: true, winding: .clockwise)
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

        let viewports = layerDrawable.views.map { $0.textureMap.viewport }
        renderCmd.setViewports(viewports)
        
        setViewMappings(renderCmd, layerDrawable, viewports)
        updateUniforms(layerDrawable)

        starsNode.drawLayer(renderCmd)
        earthNode.drawLayer(renderCmd)

        renderCmd.popDebugGroup()
        renderCmd.endEncoding()
        layerDrawable.encodePresent(commandBuffer: commandBuf)
        commandBuf.commit()
    }

}

