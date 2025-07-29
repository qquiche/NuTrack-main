//
//  ScanPageViewController.swift
//  NuTrack
//
//  Created by Anthony Rojas on 3/7/25.
//

//
//  ViewController.swift
//  Scanner Test
//
//  Created by Anthony Rojas on 3/6/25.
//

import UIKit
import AVFoundation

protocol NutritionalInfoDisplayer {
    func displayFoodInfo(food: Food)
    func foodNotFound()
}

class ScanPageViewController: UIViewController,
                              AVCaptureMetadataOutputObjectsDelegate,
                              AVCapturePhotoCaptureDelegate,
                              NutritionalInfoDisplayer {
    @IBOutlet weak var cameraPreviewView: UIView!
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var metadataOutputConnection: AVCaptureConnection!
    var metadataOutput: AVCaptureMetadataOutput!
    
    var photoOutput: AVCapturePhotoOutput!

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var discoverNutritionButton: UIButton!
    
    var scannedBarcode: String!
    var scannedFood: Food!
    
    var image: UIImage!
    
    var imageData: Data!
    
    let loadingSegueID = "loadingSegue"

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if captureSession != nil {
            captureSession.startRunning()
        }
    }
    
    @IBAction func segmentedControlChanged(_ sender: Any) {
        discoverNutritionButton.isHidden = segmentedControl.selectedSegmentIndex == 0
        
        if metadataOutputConnection != nil {
            metadataOutputConnection.isEnabled = segmentedControl.selectedSegmentIndex == 0
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        discoverNutritionButton.isHidden = true
        
        captureSession = AVCaptureSession()
        
        // Set up the camera input
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            scanningNotSupported()
            return
        }
        
        // Set up the barcode scanning output
        metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            
            // Set the barcode types you want to support
            metadataOutput.metadataObjectTypes = [
                .ean8, .ean13, .upce, .code39, .code39Mod43, .code93, .code128, .interleaved2of5, .itf14
            ]
        } else {
            scanningNotSupported()
            return
        }
        
        // Have a connection to the metadataOutput so we can manually enable or
        // disable it whenever the user changes the segmented control
        if let connection = metadataOutput.connections.first {
            metadataOutputConnection = connection
        } else {
            scanningNotSupported()
            return
        }
        
        // Set up the photo output
        photoOutput = AVCapturePhotoOutput();
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        } else {
            // If Photo Ouput can't be added, don't worry about if for now
            photoOutput = nil
        }
        
        // Configure the preview layer to show camera input on the screen
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        cameraPreviewView.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Update the camera preview's bounds to match the cameraPreviewView's bounds
        if previewLayer != nil {
            previewLayer.frame = cameraPreviewView.bounds
        }
    }
    
    // Notify user if scanning is not supported
    func scanningNotSupported() {
        makePopup(popupTitle: "Scanning not supported", popupMessage: "Your device does not support scanning a code.")
        captureSession = nil
    }
    
    func makePopup(popupTitle:String, popupMessage:String) {
        let controller = UIAlertController(
            title: popupTitle,
            message: popupMessage,
            preferredStyle: .alert)
        
        controller.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(controller,animated:true)
    }
    
    // Delegate method that gets called when a barcode is detected
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        // Stop scanning once a barcode is detected
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first,
           let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
           let code = readableObject.stringValue {
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: code)
        }
    }
    
    // Error message in case food could not be read
    func foodNotFound() {
        DispatchQueue.main.async {
            let controller = UIAlertController(
                title: "Error",
                message: "Failed to fetch food",
                preferredStyle: .alert)
            
            controller.addAction(UIAlertAction(title: "OK", style: .default) { action in
                self.captureSession.startRunning()
            })
            
            self.present(controller,animated:true)
        }
    }
    
    // Process the scanned barcode result
    func found(code: String) {
        // makePopup(popupTitle: "Scanned Barcode", popupMessage: code)
        self.scannedBarcode = code
        fetchFoodData(for: scannedBarcode) { foodResponse in
            if foodResponse == nil {
                print("Food response was nil")
                self.foodNotFound()
                return
            }
            
            guard let response = foodResponse else {
                print("Could not assign foodResponse to response")
                self.foodNotFound()
                return
            }
            
            guard let firstFood = response.foods.first else {
                print("Could not retrieve first food")
                self.foodNotFound()
                return
            }
            
            print("Food was found")
            self.scannedFood = firstFood
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "barcodeScannedSegue", sender: self)
            }
        }

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "barcodeScannedSegue",
           let nextVC = segue.destination as? BarcodeNutritionFactsViewController {
            nextVC.barcode = scannedBarcode
            nextVC.food = scannedFood
        }
        
        if segue.identifier == loadingSegueID,
           let destination = segue.destination as? ImageScanLoadingPageViewController {
            destination.delegate = self
            destination.imageData = self.imageData
        }
    }

    @IBAction func discoverNutritionButtonPressed(_ sender: Any) {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: (any Error)?) {
        
        // Stop scanning once a picture is taken
        captureSession.stopRunning()
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))


        if let error = error {
            print("Error Capturing photo: \(error.localizedDescription)")
            self.foodNotFound()
            return
        }
        
        // We now have the JPEG data, create the UI Image
        guard let imgData = photo.fileDataRepresentation(),
              var image = UIImage(data: imgData)  else {
            print("Could not parse image")
            self.foodNotFound()
            return
        }
        
        print("Image Captured!")

        // Resize and compress
        image = image.resized(to: 1200) // Adjust max dimension as needed (makes compression better)
        guard let compressedData = image.compressTo(maxSizeMB: 1) else {
            print("Could not compress image")
            self.foodNotFound()
            return
        }
        
        print("Compressed size: \(compressedData.count / 1024) KB")
        
        self.imageData = compressedData
        
        // Do the API Request in loading page
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: self.loadingSegueID, sender: self)
        }

    }
    
    func displayFoodInfo(food: Food) {
        self.scannedFood = food
        self.scannedBarcode = ""
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "barcodeScannedSegue", sender: self)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

