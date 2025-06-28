@preconcurrency import MetalKit
import Combine
import simd
import Img2Cubemap
import UIKit

class ViewController: UIViewController {
    var device: MTLDevice!
    var commandQueue: (any MTLCommandQueue)!

    var cubemapView: CubeMapView!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            print("Metal is not supported on this device.")
            return
        }
        self.device = device
        self.commandQueue = commandQueue

        let url = Bundle.main.url(forResource: "sample", withExtension: "exr")!
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let texture = try await generateCubeTexture(device: device, exr: url)
                setupUI(initialTexture: texture)
                cubemapView.cubemap = texture
            } catch {
                print("Failed to generate cube texture: \(error)")
            }
        }
    }

    func setupUI(initialTexture: any MTLTexture) {
        cubemapView = try? CubeMapView(
            frame: view.frame,
            device: device,
            commandQueue: commandQueue,
            cubemap: initialTexture
        )
        view.addSubview(cubemapView)
        cubemapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cubemapView.topAnchor.constraint(equalTo: view.topAnchor),
            cubemapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cubemapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cubemapView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
}

