import Foundation

public enum Img2CubemapError: LocalizedError {
    case failedToReadFile
    case failedToCreateTexture
    case invalidMetalDevice
    case failedToCreateCubeTexture
    case failedToCreateComputeFunction
    case failedToCreateComputePipelineState

    public var errorDescription: String? {
        switch self {
        case .failedToReadFile:
            return "[Img2Cubemap] Failed to read the EXR file."
        case .failedToCreateTexture:
            return "[Img2Cubemap] Failed to create a Metal texture."
        case .invalidMetalDevice:
            return "[Img2Cubemap] Invalid Metal device configuration."
        case .failedToCreateCubeTexture:
            return "[Img2Cubemap] Failed to create a cube texture."
        case .failedToCreateComputeFunction:
            return "[Img2Cubemap] Failed to create compute function for cube map generation."
        case .failedToCreateComputePipelineState:
            return "[Img2Cubemap] Failed to create compute pipeline state."
        }
    }
}
