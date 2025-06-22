import MetalKit

enum CubeMapViewError: Error {
    case initFailed
}

class CubeMapView: MTKView {
    let commandQueue: any MTLCommandQueue

    // cubemap properties
    let cubemapPSO: any MTLRenderPipelineState
    let cubemapDSO: any MTLDepthStencilState
    let cubeMesh: MTKMesh
    var cubemap: any MTLTexture

    // skybox properties
    let skyboxPSO: any MTLRenderPipelineState
    let skyboxDSO: any MTLDepthStencilState
    let skyboxMesh: MTKMesh

    // buffers
    let modelBuffer: any MTLBuffer
    let viewBuffer: any MTLBuffer
    let projectionBuffer: any MTLBuffer

    let skyboxModelBuffer: any MTLBuffer
    let skyboxViewBuffer: any MTLBuffer
    let skyboxProjectionBuffer: any MTLBuffer

    // variables
    var modelMatrix: float4x4 = float4x4(1.0)
    var cubePosition: simd_float3 = simd_float3(0.0, 0.0, 0.0)
    var fov: Float = .pi / 3
    var aspect: Float { Float(drawableSize.width / drawableSize.height) }
    var near: Float = 0.1
    var far: Float = 100.0
    var rotationX: Float32 = .pi / 2
    var rotationY: Float32 = .pi / 2
    var upSign: Float32 = 1
    var distance: Float32 = 5

    // constants
    let cubemapVertexShader = "cubemap_vertex"
    let cubemapFragmentShader = "cubemap_fragment"

    init(
        frame: CGRect,
        device: any MTLDevice,
        commandQueue: any MTLCommandQueue,
        cubemap: any MTLTexture
    ) throws {
        guard let library = device.makeDefaultLibrary() else {
            throw CubeMapViewError.initFailed
        }

        let depthFormat: MTLPixelFormat = .depth32Float
        let pixelFormat: MTLPixelFormat = .rgba16Float
        let rasterSampleCount: Int = 4

        self.commandQueue = commandQueue
        self.cubemap = cubemap

        // Create cube mesh
        let cubeAsset = MDLAsset(
            url: Bundle.main.url(forResource: "cube", withExtension: "obj")!,
            vertexDescriptor: nil,
            bufferAllocator: MTKMeshBufferAllocator(device: device)
        )
        let (_, metalKitMesh) = try MTKMesh.newMeshes(asset: cubeAsset, device: device)
        self.cubeMesh = metalKitMesh[0]

        // Create render pipeline state
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: cubemapVertexShader)
        descriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(cubeMesh.vertexDescriptor)!
        descriptor.fragmentFunction = library.makeFunction(name: cubemapFragmentShader)
        descriptor.colorAttachments[0].pixelFormat = pixelFormat
        descriptor.depthAttachmentPixelFormat = depthFormat
        descriptor.rasterSampleCount = rasterSampleCount
        self.cubemapPSO = try device.makeRenderPipelineState(descriptor: descriptor)

        let dsoDescriptor = MTLDepthStencilDescriptor()
        dsoDescriptor.depthCompareFunction = .less
        dsoDescriptor.isDepthWriteEnabled = true
        guard let cubemapDSO = device.makeDepthStencilState(descriptor: dsoDescriptor) else {
            throw CubeMapViewError.initFailed
        }
        self.cubemapDSO = cubemapDSO

        // Create cubemap buffers
        var model: float4x4 = float4x4(1.0)
        self.modelBuffer = device.makeBuffer(
            bytes: &model,
            length: MemoryLayout<float4x4>.size,
            options: []
        )!
        var view: float4x4 = float4x4(1.0)
        self.viewBuffer = device.makeBuffer(
            bytes: &view,
            length: MemoryLayout<float4x4>.size,
            options: []
        )!
        var projection: float4x4 = float4x4(1.0)
        self.projectionBuffer = device.makeBuffer(
            bytes: &projection,
            length: MemoryLayout<float4x4>.size,
            options: []
        )!

        // Skybox mesh
        self.skyboxMesh = cubeMesh

        // Create skybox pipeline state
        let skyboxPSODescriptor = MTLRenderPipelineDescriptor()
        skyboxPSODescriptor.label = "Skybox Pipeline"
        skyboxPSODescriptor.vertexFunction = library.makeFunction(name: "skybox_vertex")
        skyboxPSODescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(cubeMesh.vertexDescriptor)!
        skyboxPSODescriptor.fragmentFunction = library.makeFunction(name: "skybox_fragment")
        skyboxPSODescriptor.colorAttachments[0].pixelFormat = pixelFormat
        skyboxPSODescriptor.depthAttachmentPixelFormat = .depth32Float
        skyboxPSODescriptor.rasterSampleCount = rasterSampleCount
        self.skyboxPSO = try! device.makeRenderPipelineState(descriptor: skyboxPSODescriptor)

        // Create skybox depth stencil state
        let skyboxDSODescriptor = MTLDepthStencilDescriptor()
        skyboxDSODescriptor.depthCompareFunction = .always
        skyboxDSODescriptor.isDepthWriteEnabled = false
        skyboxDSODescriptor.label = "Skybox depth stencil"
        self.skyboxDSO = device.makeDepthStencilState(descriptor: skyboxDSODescriptor)!

        // Create skybox buffers
        var skyboxModel: float4x4 = float4x4(1.0)
        self.skyboxModelBuffer = device.makeBuffer(
            bytes: &skyboxModel,
            length: MemoryLayout<float4x4>.size,
            options: []
        )!

        var skyboxView: float4x4 = float4x4(1.0)
        self.skyboxViewBuffer = device.makeBuffer(
            bytes: &skyboxView,
            length: MemoryLayout<float4x4>.size,
            options: []
        )!

        var skyboxProjection: float4x4 = float4x4(1.0)
        self.skyboxProjectionBuffer = device.makeBuffer(
            bytes: &skyboxProjection,
            length: MemoryLayout<float4x4>.size,
            options: []
        )!

        super.init(frame: frame, device: device)

        self.colorPixelFormat = pixelFormat
        self.depthStencilPixelFormat = depthFormat
        self.sampleCount = rasterSampleCount
        self.clearColor = .init(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let drawable = currentDrawable,
              let descriptor = currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) else {
            return
        }

        // Render skybox

        updateSkyboxBuffer()

        renderEncoder.setRenderPipelineState(skyboxPSO)
        renderEncoder.setDepthStencilState(skyboxDSO)

        renderEncoder.setVertexBuffer(skyboxMesh.vertexBuffers[0].buffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(skyboxModelBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(skyboxViewBuffer, offset: 0, index: 2)
        renderEncoder.setVertexBuffer(skyboxProjectionBuffer, offset: 0, index: 3)
        renderEncoder.setFragmentTexture(cubemap, index: 0)

        let skyboxSubmesh = skyboxMesh.submeshes[0]
        renderEncoder.drawIndexedPrimitives(
            type: skyboxSubmesh.primitiveType,
            indexCount: skyboxSubmesh.indexCount,
            indexType: skyboxSubmesh.indexType,
            indexBuffer: skyboxSubmesh.indexBuffer.buffer,
            indexBufferOffset: skyboxSubmesh.indexBuffer.offset
        )



        // Render cubemap

        updateCubeMapBuffer()

        renderEncoder.setRenderPipelineState(cubemapPSO)
        renderEncoder.setDepthStencilState(cubemapDSO)

        renderEncoder.setVertexBuffer(cubeMesh.vertexBuffers[0].buffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(modelBuffer, offset: 0, index: 1)
        renderEncoder.setVertexBuffer(viewBuffer, offset: 0, index: 2)
        renderEncoder.setVertexBuffer(projectionBuffer, offset: 0, index: 3)

        renderEncoder.setFragmentTexture(cubemap, index: 0)

        let submesh = cubeMesh.submeshes[0]
        renderEncoder.drawIndexedPrimitives(
            type: submesh.primitiveType,
            indexCount: submesh.indexCount,
            indexType: submesh.indexType,
            indexBuffer: submesh.indexBuffer.buffer,
            indexBufferOffset: submesh.indexBuffer.offset
        )

        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    func updateCubeMapBuffer() {
        modelBuffer.contents().copyMemory(from: &modelMatrix, byteCount: MemoryLayout<float4x4>.size)

        let cameraPosition = simd_float3(
            distance * cos(rotationX) * sin(rotationY),
            distance * cos(rotationY),
            distance * sin(rotationX) * sin(rotationY)
        )
        let cameraUp = simd_float3(0, upSign, 0)
        var viewMatrix = lookAt(
            eye: cameraPosition,
            target: cubePosition,
            up: cameraUp
        )
        viewBuffer.contents().copyMemory(from: &viewMatrix, byteCount: MemoryLayout<float4x4>.size)

        var projectionMatrix = perspectiveMatrix(fov: fov, aspect: aspect, near: near, far: far)
        projectionBuffer.contents().copyMemory(from: &projectionMatrix, byteCount: MemoryLayout<float4x4>.size)
    }

    func updateSkyboxBuffer() {
        var skyboxModel = simd_float4x4(1.0)
        skyboxModelBuffer.contents().copyMemory(from: &skyboxModel, byteCount: MemoryLayout<float4x4>.size)

        let skyboxTarget = simd_float3(
            -cos(rotationX) * sin(rotationY),
            -cos(rotationY),
            -sin(rotationX) * sin(rotationY)
        )
        var skyboxViewMatrix = lookAt(
            eye: simd_float3(repeating: 0),
            target: skyboxTarget,
            up: simd_float3(0, upSign, 0)
        )
        skyboxViewBuffer.contents().copyMemory(from: &skyboxViewMatrix, byteCount: MemoryLayout<float4x4>.size)

        var projectionMatrix = perspectiveMatrix(fov: fov, aspect: aspect, near: near, far: far)
        skyboxProjectionBuffer.contents().copyMemory(from: &projectionMatrix, byteCount: MemoryLayout<float4x4>.size)
    }

    // MAKR: - UI Events

    override func scrollWheel(with event: NSEvent) {
        let multiplier: Float32 = 1
        rotationY = rotationY - multiplier * 2.0 * .pi * Float32(event.scrollingDeltaY) / Float32(self.frame.height)
        upSign = sin(rotationY) >= 0 ? 1 : -1
        rotationX = rotationX - upSign * multiplier * 2.0 * .pi * Float32(event.scrollingDeltaX) / Float32(self.frame.width)
    }

    override func magnify(with event: NSEvent) {
        let threshold: Float32 = 2
        distance = distance - Float32(event.magnification) * 10.0
        if distance < threshold {
            distance = threshold
        }
    }
}
