import Cocoa
@preconcurrency import MetalKit
import Combine
import simd
import EXR2Cubemap

class ViewController: NSViewController {
    var device: MTLDevice!
    var commandQueue: (any MTLCommandQueue)!

    var cubemapView: CubeMapView!
    @objc dynamic var exrUrl: URL!

    var cancellables = Set<AnyCancellable>()

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
        self.exrUrl = url
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let texture = try await generateCubeTexture(device: device, from: url)
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

        let optionContainerView = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
        optionContainerView.wantsLayer = true
        optionContainerView.layer?.backgroundColor = NSColor.gray.cgColor.copy(alpha: 0.8)
        optionContainerView.translatesAutoresizingMaskIntoConstraints = false

        let optionStackView = NSStackView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
        optionStackView.orientation = .vertical
        optionStackView.alignment = .leading
        optionStackView.spacing = 8
        optionStackView.translatesAutoresizingMaskIntoConstraints = false

        let openFileButton = NSButton(title: "Open .EXR", target: self, action: #selector(openFile))
        openFileButton.frame = NSRect(x: 20, y: 20, width: 100, height: 30)
        openFileButton.translatesAutoresizingMaskIntoConstraints = false

        let urlLabel = NSTextField(labelWithString: exrUrl?.lastPathComponent ?? "No file selected")
        urlLabel.translatesAutoresizingMaskIntoConstraints = false
        urlLabel.font = .systemFont(ofSize: 12)
        urlLabel.textColor = .white
        publisher(for: \.exrUrl)
            .map { $0?.lastPathComponent ?? "" }
            .assign(to: \.stringValue, on: urlLabel)
            .store(in: &cancellables)



        optionStackView.addArrangedSubview(openFileButton)
        optionStackView.addArrangedSubview(urlLabel)
        optionContainerView.addSubview(optionStackView)
        view.addSubview(optionContainerView)

        NSLayoutConstraint.activate([
            optionContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            optionContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            optionContainerView.widthAnchor.constraint(lessThanOrEqualToConstant: 400),

            optionStackView.topAnchor.constraint(equalTo: optionContainerView.topAnchor, constant: 8),
            optionStackView.bottomAnchor.constraint(equalTo: optionContainerView.bottomAnchor, constant: -8),
            optionStackView.leadingAnchor.constraint(equalTo: optionContainerView.leadingAnchor, constant: 8),
            optionStackView.trailingAnchor.constraint(equalTo: optionContainerView.trailingAnchor, constant: -8)
        ])
    }

    @objc func openFile() {
        let dialog = NSOpenPanel()
        dialog.title = "Choose an EXR file"
        dialog.allowedContentTypes = [.exr]
        dialog.allowsMultipleSelection = false

        dialog.beginSheetModal(for: self.view.window!) { [weak self] (result) in
            guard let self = self else { return }
            if result == .OK, let url = dialog.url {
                self.exrUrl = url

                Task { @MainActor [weak self] in
                    guard let self else { return }
                    do {
                        let texture = try await generateCubeTexture(device: device, from: url)
                        cubemapView.cubemap = texture
                    } catch {
                        print("Failed to generate cube texture: \(error)")
                    }
                }
            }
        }
    }
}
