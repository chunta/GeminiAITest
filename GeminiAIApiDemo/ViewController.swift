import UIKit
import Photos
import GoogleGenerativeAI

class ViewController: UIViewController {

    @IBOutlet private var frontCleanFaceImageView: UIImageView!
    @IBOutlet private var fullBodyNaturePostImageView: UIImageView!
    @IBOutlet private var frontCleanFaceButton: UIButton!
    @IBOutlet private var fullBodyNaturePoseButton: UIButton!
    @IBOutlet private var loadingActivity: UIActivityIndicatorView!
    @IBOutlet private var frontCleanFaceVerifyLabel: UILabel!
    @IBOutlet private var fullbodyNaturePoseVerifyLabel: UILabel!
    private lazy var fronCleanFaceImagePicker = UIImagePickerController()
    private lazy var fullBodyNaturePoseImagePicker = UIImagePickerController()

    private let visionProModel = GenerativeModel(name: "gemini-pro-vision", apiKey: APIKey.default)

    @IBAction func selectFrontCleanFacePhoto(_ sender: UIControl) {
        takeFrontCleanFaceImageFromLibrary()
    }

    @IBAction func selectFullBodyNaturePostPhoto(_ sender: UIControl) {
        takeFullBodyNaturePoseImageFromLibrary()
    }

    private func verifyFrontCleanFaceWithAI(_ image: UIImage) {
        Task.init {
            presentLoadingActivity(true)
            enableUserInteraction(false)
            cleanFrontCleanFaceStatueLabel()
            await verifyFrontCleanFaceWithAIImpl(image) { verified in
                print(Thread.isMainThread)
                let fixedMessage = "a person presenting a front and clean face"
                print(verified ? "This is \(fixedMessage)" : "This is not \(fixedMessage)")
                self.updateFrontCleanFaceStatueLabel(verified)
                self.presentLoadingActivity(false)
                self.enableUserInteraction(true)
            }
        }
    }

    private func verifyFrontCleanFaceWithAIImpl(_ image: UIImage, completion: @escaping (Bool) -> Void) async {
        print("Task inside")
        let prompt = """
                    Can we see only a person with his/her frontface and less makeup ?. If no, return NO.
                    """
        do {
            let response = try await visionProModel.generateContent(prompt, image)
            guard let responseMessage = response.text else {
                completion(false)
                return
            }
            completion(doesAIResponseSayYes(responseMessage))
        } catch {
            print("Gemini AI Error:\(error)")
            completion(false)
        }
    }

    private func cleanFrontCleanFaceStatueLabel() {
        frontCleanFaceVerifyLabel.text = ""
    }

    private func updateFrontCleanFaceStatueLabel(_ verified: Bool) {
        frontCleanFaceVerifyLabel.textColor = verified ? .green : .red
        frontCleanFaceVerifyLabel.text = verified ? "Pass" : "No"
    }

    private func takeFrontCleanFaceImageFromLibrary() {
        fronCleanFaceImagePicker.delegate = self
        fronCleanFaceImagePicker.sourceType = .photoLibrary
        present(fronCleanFaceImagePicker, animated: true, completion: nil)
    }

    private func verifyFullBodyNaturePoseWithAI(_ image: UIImage) {
        Task.init {
            presentLoadingActivity(true)
            enableUserInteraction(false)
            cleanFullbodyNaturePoseStatueLabel()
            await verifyFullBodyNaturePoseWithAIImpl(image) { verified in
                let fixedMessage = "a person presenting his/her fullbody"
                print(verified ? "This is \(fixedMessage)" : "This is not \(fixedMessage)")
                self.updateFullbodyNaturePoseStatueLabel(verified)
                self.presentLoadingActivity(false)
                self.enableUserInteraction(true)
            }
        }
    }

    private func verifyFullBodyNaturePoseWithAIImpl(_ image: UIImage, completion: @escaping (Bool) -> Void) async {
        print("Task inside")
        let prompt = """
                    Can we see a person's head and legs?. If no, return NO.
                    """
        do {
            let response = try await visionProModel.generateContent(prompt, image)
            guard let responseMessage = response.text else {
                completion(false)
                return
            }
            completion(doesAIResponseSayYes(responseMessage))
        } catch {
            print("Gemini AI Error:\(error)")
            completion(false)
        }
    }

    private func doesAIResponseSayYes(_ responseMessage: String) -> Bool {
        print("ResponseMessage from AI:\(responseMessage) [end]")
        let verified = !responseMessage.uppercased().contains("NO")
        return verified
    }

    private func cleanFullbodyNaturePoseStatueLabel() {
        fullbodyNaturePoseVerifyLabel.text = ""
    }

    private func updateFullbodyNaturePoseStatueLabel(_ verified: Bool) {
        fullbodyNaturePoseVerifyLabel.textColor = verified ? .green : .red
        fullbodyNaturePoseVerifyLabel.text = verified ? "Pass" : "No"
    }

    private func takeFullBodyNaturePoseImageFromLibrary() {
        fullBodyNaturePoseImagePicker.delegate = self
        fullBodyNaturePoseImagePicker.sourceType = .photoLibrary
        present(fullBodyNaturePoseImagePicker, animated: true, completion: nil)
    }

    private func presentLoadingActivity(_ show: Bool) {
        DispatchQueue.main.async {
            show ? self.loadingActivity.startAnimating() : self.loadingActivity.stopAnimating()
        }
    }

    private func enableUserInteraction(_ enable: Bool) {
        DispatchQueue.main.async {
            self.view.isUserInteractionEnabled = enable
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            if picker == fronCleanFaceImagePicker {
                frontCleanFaceImageView.image = pickedImage
                verifyFrontCleanFaceWithAI(pickedImage)
            } else if picker == fullBodyNaturePoseImagePicker {
                fullBodyNaturePostImageView.image = pickedImage
                verifyFullBodyNaturePoseWithAI(pickedImage)
            }
        }
        dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
