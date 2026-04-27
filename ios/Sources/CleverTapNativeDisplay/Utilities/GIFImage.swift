import SwiftUI
import UIKit
import ImageIO

/// SwiftUI view for displaying animated GIFs
public struct GIFImage: UIViewRepresentable {
    let url: URL
    let contentMode: ContentMode

    public init(url: URL, contentMode: ContentMode) {
        self.url = url
        self.contentMode = contentMode
    }

    public func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = contentMode == .fit ? .scaleAspectFit : .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }

    public func updateUIView(_ uiView: UIImageView, context: Context) {
        Task {
            if let image = await loadAnimatedGIF(from: url) {
                await MainActor.run {
                    uiView.image = image
                }
            }
        }
    }

    private func loadAnimatedGIF(from url: URL) async -> UIImage? {
        guard let data = try? await URLSession.shared.data(from: url).0 else {
            return nil
        }

        // Try to load as animated GIF
        // If it's not a GIF or has only 1 frame, this will return a static UIImage
        // which is fine - graceful degradation
        return UIImage.animatedGIF(from: data)
    }
}

extension UIImage {
    /// Creates an animated UIImage from GIF data
    /// Gracefully handles non-GIF data and single-frame images
    static func animatedGIF(from data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        let count = CGImageSourceGetCount(source)

        // Single frame or static image - return as static UIImage
        if count <= 1 {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                return nil
            }
            return UIImage(cgImage: cgImage)
        }

        // Multiple frames - create animated image
        var images: [UIImage] = []
        var duration: TimeInterval = 0

        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                let image = UIImage(cgImage: cgImage)
                images.append(image)

                // Get frame duration
                if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
                   let gifInfo = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                   let frameDuration = gifInfo[kCGImagePropertyGIFDelayTime as String] as? Double {
                    duration += frameDuration
                } else {
                    duration += 0.1  // Default 100ms per frame
                }
            }
        }

        // Return animated image if we have frames, otherwise return first frame as static
        return images.isEmpty ? nil : UIImage.animatedImage(with: images, duration: duration)
    }
}
