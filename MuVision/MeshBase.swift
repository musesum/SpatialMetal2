// created by musesum on 12/19/23

import MetalKit
import Spatial

open class MeshBase {

    private var device: MTLDevice
    public var winding: MTLWinding
    public var stencil: MTLDepthStencilState
    public var metalVD: MTLVertexDescriptor
    public var mtkMesh: MTKMesh?

    public init(device  : MTLDevice,
                compare : MTLCompareFunction,
                winding : MTLWinding)  {

        self.device = device
        self.winding = winding
        self.metalVD = MTLVertexDescriptor()

        let sd = MTLDepthStencilDescriptor()
        sd.isDepthWriteEnabled = true
        sd.depthCompareFunction = compare
        self.stencil = device.makeDepthStencilState(descriptor: sd)!

        makeMetalVD()
    }
    func makeMetalVD() {
        addVertexFormat(.float3, VertexIndex.position)
        addVertexFormat(.float2, VertexIndex.texcoord)
        addVertexFormat(.float3, VertexIndex.normal  )
    }
    public func addVertexFormat(_ format: MTLVertexFormat,
                                _ index: Int) {
        let stride: Int
        switch format {
        case .float2: stride = MemoryLayout<Float>.size * 2
        case .float3: stride = MemoryLayout<Float>.size * 3
        case .float4: stride = MemoryLayout<Float>.size * 4
        default: return err("unknown format \(format)")
        }
        metalVD.attributes[index].format = format
        metalVD.attributes[index].offset = 0
        metalVD.attributes[index].bufferIndex = index

        metalVD.layouts[index].stride = stride
        metalVD.layouts[index].stepRate = 1
        metalVD.layouts[index].stepFunction = .perVertex

        func err(_ msg: String) {
            print("⁉️ addVertexFormat error: \(msg)")
        }
    }

    open func drawMesh(_ renderCmd: MTLRenderCommandEncoder) {

        guard let mtkMesh else { return err("mesh") }

        //???? renderCmd.setCullMode(.back)
        renderCmd.setFrontFacing(winding)
        renderCmd.setDepthStencilState(stencil)

        for (index, element) in mtkMesh.vertexDescriptor.layouts.enumerated() {
            guard let layout = element as? MDLVertexBufferLayout else { return }
            if layout.stride != 0 {
                let vb = mtkMesh.vertexBuffers[index]
                renderCmd.setVertexBuffer(vb.buffer,
                                          offset: vb.offset,
                                          index: index)
            }
        }

        for submesh in mtkMesh.submeshes {
            renderCmd.drawIndexedPrimitives(
                type              : submesh.primitiveType,
                indexCount        : submesh.indexCount,
                indexType         : submesh.indexType,
                indexBuffer       : submesh.indexBuffer.buffer,
                indexBufferOffset : submesh.indexBuffer.offset)
        }
        func err(_ msg: String) {
            print("⁉️ drawMesh error: \(msg)")
        }
    }
}
