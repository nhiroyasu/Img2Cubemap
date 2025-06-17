public enum OpenEXRConnectionError: Error {
    case failedToReadFile
    case failedToCreateTexture
    case invalidMetalDevice
    case failedToCreateCubeTexture
    case failedToCreateComputeFunction
}
