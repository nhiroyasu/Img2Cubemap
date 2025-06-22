public enum Img2CubemapError: Error {
    case failedToReadFile
    case failedToCreateTexture
    case invalidMetalDevice
    case failedToCreateCubeTexture
    case failedToCreateComputeFunction
}
