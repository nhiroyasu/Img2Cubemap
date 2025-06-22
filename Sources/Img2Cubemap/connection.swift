@preconcurrency import Metal
import simd
import OpenEXRWrapper

func generateMetalTexture(
    device: MTLDevice,
    width: Int,
    height: Int,
    data: UnsafeRawPointer
) throws -> MTLTexture {
    let descriptor = MTLTextureDescriptor.texture2DDescriptor(
        pixelFormat: .rgba32Float,
        width: Int(width),
        height: Int(height),
        mipmapped: false
    )
    descriptor.usage = [.shaderRead, .shaderWrite]

    guard let texture = device.makeTexture(descriptor: descriptor) else {
        throw Img2CubemapError.failedToCreateTexture
    }

    let region = MTLRegionMake2D(0, 0, Int(width), Int(height))
    texture.replace(
        region: region,
        mipmapLevel: 0,
        withBytes: data,
        bytesPerRow: Int(width) * MemoryLayout<simd_float4>.size
    )

    return texture
}

func generateCubeTexture(device: MTLDevice, from exr: EXRData, size: Int) throws -> MTLTexture {
    guard let library = try? device.makeDefaultLibrary(bundle: Bundle.module),
          let commandQueue = device.makeCommandQueue(),
          let commandBuffer = commandQueue.makeCommandBuffer() else {
        throw Img2CubemapError.invalidMetalDevice
    }

    // Create a Metal texture from the EXR data
    let baseTexture = try generateMetalTexture(
        device: device,
        width: Int(exr.header.width),
        height: Int(exr.header.height),
        data: try exr.pixels.withUnsafeBytes {
            if let addr = $0.baseAddress {
                return addr
            } else {
                throw Img2CubemapError.failedToCreateTexture
            }
        }
    )

    // Create a cube texture descriptor
    let cubeDescriptor = MTLTextureDescriptor.textureCubeDescriptor(
        pixelFormat: .rgba32Float,
        size: size,
        mipmapped: true
    )
    cubeDescriptor.usage = [.shaderRead, .shaderWrite]
    guard let cubeTexture = device.makeTexture(descriptor: cubeDescriptor) else {
        throw Img2CubemapError.failedToCreateCubeTexture
    }

    // Create a compute pipeline state
    guard let generateCubeMapFunction = library.makeFunction(name: "generateCubeMap") else {
        throw Img2CubemapError.failedToCreateComputeFunction
    }
    let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder()
    let computePipelineState = try device.makeComputePipelineState(function: generateCubeMapFunction)

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

public func generateCubeTexture(device: any MTLDevice, exr url: URL) async throws -> MTLTexture {
    try await withCheckedThrowingContinuation { continuation in
        DispatchQueue.global().async {
            do {
                let exr = try readEXR(url: url)

                let size = Int(exr.header.width) / 4 // Equirectangular to cube map conversion typically uses 1/4 of the width for each face
                let texture = try generateCubeTexture(device: device, from: exr, size: size)
                continuation.resume(returning: texture)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
