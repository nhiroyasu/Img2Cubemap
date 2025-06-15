@preconcurrency import Metal
import OpenEXRWrapper

private class DummyClassInFramework {}

public enum OpenEXRConnectionError: Error {
    case failedToReadFile
    case failedToCreateTexture
    case invalidMetalDevice
    case failedToCreateCubeTexture
}

func fetchExrData(url: URL) throws -> ReadExrOut {
    var cchar: [CChar] = Array(url.path.utf8CString)
    var out = ReadExrOut()

    if readExrFile(&cchar, &out) == SUCCESS {
        return out
    } else {
        throw OpenEXRConnectionError.failedToReadFile
    }
}

public func generateMetalTexture(device: MTLDevice, from exr: ReadExrOut) throws -> MTLTexture {
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .rgba16Float,
        width: Int(exr.width),
        height: Int(exr.height),
        mipmapped: false
    )
    descriptor.usage = [.shaderRead, .shaderWrite]

    guard let texture = device.makeTexture(descriptor: descriptor) else {
        throw OpenEXRConnectionError.failedToCreateTexture
    }

    var color = Array(UnsafeBufferPointer(start: exr.color, count: Int(exr.width * exr.height)))

    let region = MTLRegionMake2D(0, 0, Int(exr.width), Int(exr.height))
    texture.replace(
        region: region,
        mipmapLevel: 0,
        withBytes: &color,
        bytesPerRow: Int(exr.width) * MemoryLayout<simd_half4>.size
    )

    return texture
}

public func generateCubeTexture(device: MTLDevice, from exr: ReadExrOut, size: Int) throws -> MTLTexture {
    guard let library = try? device.makeDefaultLibrary(bundle: Bundle(for: DummyClassInFramework.self)),
          let commandQueue = device.makeCommandQueue(),
          let commandBuffer = commandQueue.makeCommandBuffer() else {
        throw OpenEXRConnectionError.invalidMetalDevice
    }

    // Create a Metal texture from the EXR data
    let baseTexture = try generateMetalTexture(device: device, from: exr)

    // Create a cube texture descriptor
    let cubeDescriptor = MTLTextureDescriptor.textureCubeDescriptor(
        pixelFormat: .rgba16Float,
        size: size,
        mipmapped: true
    )
    cubeDescriptor.usage = [.shaderRead, .shaderWrite]
    guard let cubeTexture = device.makeTexture(descriptor: cubeDescriptor) else {
        throw OpenEXRConnectionError.failedToCreateCubeTexture
    }

    // Create a compute pipeline state
    let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()
    let computePipelineState = try! device.makeComputePipelineState(function: library.makeFunction(name: "generateCubeMap")!)

    // Set the compute pipeline state
    for face in 0..<6 {
        computeCommandEncoder?.setComputePipelineState(computePipelineState)
        computeCommandEncoder?.setTexture(baseTexture, index: 0)
        computeCommandEncoder?.setTexture(cubeTexture, index: 1)

        var faceIndex: UInt32 = UInt32(face)
        let faceIndexBuffer = device.makeBuffer(bytes: &faceIndex, length: MemoryLayout<UInt32>.size, options: [])
        var size: UInt32 = UInt32(size)
        let sizeBuffer = device.makeBuffer(bytes: &size, length: MemoryLayout<UInt32>.size, options: [])
        computeCommandEncoder?.setBuffer(faceIndexBuffer, offset: 0, index: 0)
        computeCommandEncoder?.setBuffer(sizeBuffer, offset: 0, index: 1)

        let threadsPerGroup = Int(sqrt(Double(computePipelineState.maxTotalThreadsPerThreadgroup)))
        let threadsPerGroupSize = MTLSize(width: threadsPerGroup, height: threadsPerGroup, depth: 1)
        let threadgroups = MTLSize(
            width: (Int(size) + threadsPerGroup - 1) / threadsPerGroup,
            height: (Int(size) + threadsPerGroup - 1) / threadsPerGroup,
            depth: 1
        )
        computeCommandEncoder?.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerGroupSize)
    }
    computeCommandEncoder?.endEncoding()

    // Generate mipmaps for the cube texture
    let mipmapCommandEncoder = commandBuffer.makeBlitCommandEncoder()!
    mipmapCommandEncoder.generateMipmaps(for: cubeTexture)
    mipmapCommandEncoder.endEncoding()

    // Commit the command buffer and wait for completion
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()

    return cubeTexture
}

public func generateCubeTexture(device: any MTLDevice, from url: URL) async throws -> MTLTexture {
    try await withCheckedThrowingContinuation { continuation in
        DispatchQueue.global().async {
            do {
                let exrData = try fetchExrData(url: url)
                defer { free(exrData.color) }

                let texture = try generateCubeTexture(device: device, from: exrData, size: Int(exrData.width) / 4)
                continuation.resume(returning: texture)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
