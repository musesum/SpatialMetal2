//  Created by musesum on 8/4/23.

import MetalKit
import Spatial

public class MeshTexture: MeshBase {

    private var texName: String!
    public var texture: MTLTexture!

    public init(device  : MTLDevice,
                texName : String,
                compare : MTLCompareFunction,
                winding : MTLWinding ) throws {

        super.init(device: device,
                   compare: compare,
                   winding: winding)

        self.texName = texName
        self.texture = device.load(texName)
    }

    override open func drawMesh(_ renderCmd: MTLRenderCommandEncoder) {

        renderCmd.setFragmentTexture(texture, index: TextureIndex.colori)
        super.drawMesh(renderCmd)
    }
}

