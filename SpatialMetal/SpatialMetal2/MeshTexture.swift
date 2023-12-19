// created by musesum on 12/19/23

import MetalKit
import Spatial

class MeshTexture: MeshBase {

    var texName: String!
    var texture: MTLTexture!

    init(device  : MTLDevice,
         texName : String,
         compare : MTLCompareFunction,
         winding : MTLWinding ) throws {

        super.init(device: device,
                   compare: compare,
                   winding: winding)

        self.texName = texName
        self.texture = loadTexture(device, texName)
    }

    override func drawMesh(_ renderCmd: MTLRenderCommandEncoder,
                           _ renderPipe: MTLRenderPipelineState) {

        renderCmd.setFragmentTexture(texture, index: Texturei.colori)
        super.drawMesh(renderCmd, renderPipe)
    }
}

