//
// created by musesum.

import Metal
import MetalKit
import ARKit
import Spatial
import CompositorServices

/// This is the example specific part of rendering metal within VisionOS.
/// The example uses earth in the foreground and stars in the background.
class SpatialRenderer: Renderer {

    var starsPipe: MTLRenderPipelineState?
    var earthPipe: MTLRenderPipelineState?
    var earthMesh: MeshEllipsoid?
    var starsMesh: MeshEllipsoid?
    var starsEyeBuf: UniformEyeBuf<Uniforms>?
    var earthEyeBuf: UniformEyeBuf<Uniforms>?

    override init(_ layerRenderer: LayerRenderer) {
        super.init(layerRenderer)
        setDelegate(self)
        startRenderLoop()
    }
}

extension SpatialRenderer: UniformEyeDelegate {

    func eyeUniforms(_ projection: matrix_float4x4,
                     _ viewModel: matrix_float4x4) -> Any {

        return Uniforms(projection,viewModel) 
    }

}
extension SpatialRenderer: RendererProtocol {

    func makeResources() {
        // stars is from 8k_stars_milky_way.jpg via
        // https://www.solarsystemscope.com/textures/ -- CC Atribution 4.0
        starsEyeBuf = UniformEyeBuf(self, device, "stars", infinitelyFar: true)
        earthEyeBuf = UniformEyeBuf(self, device, "earth", infinitelyFar: false)
        do {
            try earthMesh = MeshEllipsoid(device, "Earth", .less,    radius: 2.5, inward: false)
            try starsMesh = MeshEllipsoid(device, "Stars", .greater, radius: 3.0, inward: true)
        } catch {
            fatalError("\(#function) Error: \(error)")
        }
    }
    func makePipeline(_ layerRenderer: LayerRenderer) {
        guard let library = device.makeDefaultLibrary() else { return err("library = nil")}
        guard let earthMesh else { return err("earthMesh")}
        guard let starsMesh else { return err("starsMesh")}
        do {
            let configuration = layerRenderer.configuration
            let pd = MTLRenderPipelineDescriptor()
            pd.colorAttachments[0].pixelFormat = configuration.colorFormat
            pd.depthAttachmentPixelFormat = configuration.depthFormat

            // earth.metal
            pd.vertexFunction   = library.makeFunction(name: "vertexEarth")
            pd.fragmentFunction = library.makeFunction(name: "fragmentEarth")
            pd.vertexDescriptor = earthMesh.metalVD
            earthPipe = try device.makeRenderPipelineState(descriptor: pd)

            // stars.metal
            pd.vertexFunction   = library.makeFunction(name: "vertexStars")
            pd.fragmentFunction = library.makeFunction(name: "fragmentStars")
            pd.vertexDescriptor = starsMesh.metalVD
            starsPipe = try device.makeRenderPipelineState(descriptor: pd)

        } catch let error {
            err("compile \(error.localizedDescription)")
        }

        func err(_ msg: String) {
            print("⁉️ SpatialRenderer::\(#function) error: \(msg)")
        }
    }

    /// Update projection and rotation
    func updateUniforms(_ layerDrawable: LayerRenderer.Drawable) {
        
        let translateMat = translateQuat(x: 0.0, y: 0.0, z: -8.0)
        let rotationAxis = SIMD3<Float>(0, 1, 0)

        let earthRotation = rotateQuat(radians: rotation, 
                                       axis: rotationAxis)
        let earthModelMat = translateMat * earthRotation
        earthEyeBuf?.updateUniforms(layerDrawable, earthModelMat)

        let starsRotation = rotateQuat(radians: 0, 
                                       axis: rotationAxis)
        let starsModelMat = translateMat * starsRotation
        starsEyeBuf?.updateUniforms(layerDrawable, starsModelMat)

        rotation += 0.003
    }

    func renderLayer(_ commandBuf    : MTLCommandBuffer,
                     _ layerFrame    : LayerRenderer.Frame,
                     _ layerDrawable : LayerRenderer.Drawable) {

        let renderPass = makeRenderPass(layerDrawable: layerDrawable)

        guard let starsMesh, let starsPipe, let starsEyeBuf,
              let earthMesh, let earthPipe, let earthEyeBuf,
              let renderCmd = commandBuf.makeRenderCommandEncoder(
                descriptor: renderPass) else { fatalError(#function) }

        renderCmd.label = "Spatial"
        renderCmd.pushDebugGroup("Spatial")

        let viewports = layerDrawable.views.map { $0.textureMap.viewport }
        renderCmd.setViewports(viewports)

        starsEyeBuf.setMappings(layerDrawable, viewports, renderCmd)
        starsMesh.drawMesh(renderCmd, starsPipe, .clockwise)

        earthEyeBuf.setMappings(layerDrawable, viewports, renderCmd)
        earthMesh.drawMesh(renderCmd, earthPipe, .counterClockwise)

        renderCmd.popDebugGroup()
        renderCmd.endEncoding()
        layerDrawable.encodePresent(commandBuffer: commandBuf)
        commandBuf.commit()
    }

}

