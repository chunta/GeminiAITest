//
//  ViewController.swift
//  GeminiAIApiDemo
//
//  Created by Rex Chen on 2024/4/12.
//

import UIKit
import Photos
import GoogleGenerativeAI

class ViewController: UIViewController {
    
    @IBOutlet private var frontCleanFaceImageView: UIImageView!
    @IBOutlet private var fullBodyNaturePostImageView: UIImageView!
    @IBOutlet private var frontCleanFaceButton: UIButton!
    @IBOutlet private var fullBodyNaturePostButton: UIButton!
    @IBOutlet private var loadingActivity: UIActivityIndicatorView!
    private lazy var fronCleanFaceImagePicker = UIImagePickerController()
    private lazy var fullBodyNaturePoseImagePicker = UIImagePickerController()
    
    private let visionProModel = GenerativeModel(name: "gemini-pro-vision", apiKey: APIKey.default)
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
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
            await verifyFrontCleanFaceWithAIImpl(image) { verified in
                let fixedMessage = "a person presenting a front and clean face"
                print(verified ? "This is \(fixedMessage)" : "This is not \(fixedMessage)")
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

    private func takeFrontCleanFaceImageFromLibrary() {
        fronCleanFaceImagePicker.delegate = self
        fronCleanFaceImagePicker.sourceType = .photoLibrary
        present(fronCleanFaceImagePicker, animated: true, completion: nil)
    }
    
    private func verifyFullBodyNaturePoseWithAI(_ image: UIImage) {
        Task.init {
            presentLoadingActivity(true)
            enableUserInteraction(false)
            await verifyFullBodyNaturePoseWithAIImpl(image) { verified in
                let fixedMessage = "a person presenting in a fullbody and nature pose"
                print(verified ? "This is \(fixedMessage)" : "This is not \(fixedMessage)")
                self.presentLoadingActivity(false)
                self.enableUserInteraction(true)
            }
        }
    }
    
    private func verifyFullBodyNaturePoseWithAIImpl(_ image: UIImage, completion: @escaping (Bool) -> Void) async {
        print("Task inside")
        let prompt = """
                    Can we see only a person presenting his/her fullbody and lges ?. If no, return No.
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
        let verified = !responseMessage.contains("NO")
        return verified
    }
    
    private func takeFullBodyNaturePoseImageFromLibrary() {
        fullBodyNaturePoseImagePicker.delegate = self
        fullBodyNaturePoseImagePicker.sourceType = .photoLibrary
        present(fullBodyNaturePoseImagePicker, animated: true, completion: nil)
    }
    
    private func presentLoadingActivity(_ show: Bool) {
        show ? loadingActivity.startAnimating() : loadingActivity.stopAnimating()
    }
    
    private func enableUserInteraction(_ enable: Bool) {
        view.isUserInteractionEnabled = enable
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            if picker == fronCleanFaceImagePicker
            {
                frontCleanFaceImageView.image = pickedImage
                verifyFrontCleanFaceWithAI(pickedImage)
            }
            else if picker == fullBodyNaturePoseImagePicker
            {
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
