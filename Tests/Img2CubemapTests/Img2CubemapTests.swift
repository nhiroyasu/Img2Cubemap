import Testing
import MetalKit
@testable import Img2Cubemap

@Test func testGenerateTexture() async throws {
    guard let device = MTLCreateSystemDefaultDevice(),
          let url = Bundle.module.url(forResource: "test_exr", withExtension: "exr") else {
        throw NSError(domain: "Img2CubemapTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Metal device or EXR file not found"])
    }
    let texture = try await generateCubeTexture(device: device, exr: url)

    #expect(texture.width == 300)
    #expect(texture.height == 300)
    #expect(texture.textureType == .typeCube)
    #expect(texture.mipmapLevelCount == 9)
    #expect(texture.pixelFormat == .rgba32Float)
}
