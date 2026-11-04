import PhotosUI
import SwiftUI
import UIKit

/// 1.13: one photo per expense — taken with the camera or chosen from the photo library,
/// kept as a JPEG (longest side 1600 px) with a small copy (120 px) for the list rows.
enum Photos {
    static func jpeg(_ image: UIImage, longest: CGFloat, quality: CGFloat) -> Data? {
        let size = image.size
        let scale = min(1, longest / max(size.width, size.height, 1))
        let target = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: quality)
    }

    /// The photo and its small copy.
    static func both(_ image: UIImage) -> (photo: Data?, thumb: Data?) {
        (jpeg(image, longest: 1600, quality: 0.7), jpeg(image, longest: 120, quality: 0.7))
    }

    /// UI tests cannot use the camera or the library: a made-up picture instead.
    static var testImage: UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 400, height: 300)).image { ctx in
            UIColor.systemTeal.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 400, height: 300))
        }
    }
}

/// The Photo section of the check sheet.
struct PhotoSection: View {
    @Binding var photo: Data?
    @Binding var thumb: Data?
    @State private var libraryItem: PhotosPickerItem?
    @State private var showLibrary = false
    @State private var showCamera = false
    @State private var showBig = false

    private var hasCamera: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    var body: some View {
        Section {
            if let photo, let image = UIImage(data: photo) {
                Button { showBig = true } label: {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .accessibilityLabel("Photo")
                .accessibilityIdentifier("entry-photo")
                .sheet(isPresented: $showBig) {
                    PhotoViewer(image: image)
                }
                Button("Remove photo", role: .destructive) {
                    self.photo = nil
                    thumb = nil
                }
                .accessibilityIdentifier("entry-photo-remove")
            } else {
                HStack(spacing: 10) {
                    if hasCamera {
                        Button { showCamera = true } label: {
                            Label("Take photo", systemImage: "camera")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("entry-photo-camera")
                    }
                    Button {
                        if ExpensesApp.uiTesting { set(Photos.testImage) } else { showLibrary = true }
                    } label: {
                        Label("Choose photo", systemImage: "photo")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("entry-photo-choose")
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .photosPicker(isPresented: $showLibrary, selection: $libraryItem, matching: .images)
                .onChange(of: libraryItem) { _, item in
                    guard let item else { return }
                    Task {
                        if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                            set(image)
                        }
                        libraryItem = nil
                    }
                }
                .fullScreenCover(isPresented: $showCamera) {
                    CameraPicker { image in set(image) }
                        .ignoresSafeArea()
                }
            }
        }
    }

    private func set(_ image: UIImage) {
        let made = Photos.both(image)
        photo = made.photo
        thumb = made.thumb
    }
}

/// The photo big, with Done.
struct PhotoViewer: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("Photo")
                .accessibilityIdentifier("photo-viewer-image")
                .navigationTitle("Photo")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                            .accessibilityIdentifier("photo-viewer-done")
                    }
                }
        }
    }
}

/// The iPhone's camera, for one photo.
struct CameraPicker: UIViewControllerRepresentable {
    let onPick: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onPick(image) }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}
