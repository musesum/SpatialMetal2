// created by musesum on 12/18/23

import Spatial
import CompositorServices

class RenderNode {

    var renderer: RenderLayer

    var renderPipe: MTLRenderPipelineState?
    var mesh: MeshBase?
    var eyeBuf: UniformEyeBuf<UniformEye>?


    init(_ renderer: RenderLayer) {
        self.renderer = renderer
    }

    func makePipeline(_ vertexName: String,
                      _ fragmentName: String) {

        let configuration = renderer.layerRenderer.configuration
        let library = renderer.library
        let device = renderer.device
        let colorFormat = configuration.colorFormat
        let depthFormat = configuration.depthFormat

        guard let mesh else { return err("mesh")}

        do {
            let pd = MTLRenderPipelineDescriptor()

            pd.colorAttachments[0].pixelFormat = colorFormat
            pd.depthAttachmentPixelFormat = depthFormat
            
            pd.vertexFunction   = library.makeFunction(name: vertexName)
            pd.fragmentFunction = library.makeFunction(name: fragmentName)
            pd.vertexDescriptor = mesh.metalVD
            renderPipe = try device.makeRenderPipelineState(descriptor: pd)

        } catch let error {
            err("compile \(error.localizedDescription)")
        }

        func err(_ msg: String) {
            print("⁉️ SpatialRenderer::\(#function) error: \(msg)")
        }
    }

    func drawLayer(_ layerDrawable: LayerRenderer.Drawable,
                   _ renderCmd: MTLRenderCommandEncoder,
                   _ viewports: [MTLViewport]) {

        guard let eyeBuf, let mesh, let renderPipe else { return }
        eyeBuf.setViewMappings(renderCmd, layerDrawable, viewports)
        eyeBuf.setUniformBuf(renderCmd)
        renderCmd.setRenderPipelineState(renderPipe)
        mesh.drawMesh(renderCmd)
    }
}
