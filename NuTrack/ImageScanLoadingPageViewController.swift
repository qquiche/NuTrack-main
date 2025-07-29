//
//  ImageScanLoadingPageViewController.swift
//  NuTrack
//
//  Created by Anthony Rojas on 4/8/25.
//

import UIKit

class ImageScanLoadingPageViewController: UIViewController {
    
    var imageData: Data!
    
    var delegate: UIViewController!

    @IBOutlet weak var nutrackImage: UIImageView!
    
    private func fetchInfo() {
        let apiUserToken = Config.value(forKey: "LOGMEAL_API_USER_TOKEN")
        getLogMealNutritionalInfo(imageData: imageData, apiUserToken: apiUserToken) { result in
            let destination = self.delegate as! NutritionalInfoDisplayer
            
            DispatchQueue.main.async {
                self.dismiss(animated: true)
            }
            
            switch result {
            case .success(let nutritionalInfo):
                print("Nutritional Info:", nutritionalInfo)
                guard let food = jsonToFood(nutritionalInfo: nutritionalInfo) else {
                    destination.foodNotFound()
                    return
                }
                destination.displayFoodInfo(food: food)
            
            case .failure(let error):
                print("Error:", error.localizedDescription)
                destination.foodNotFound()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        startLoadingAnimation()
        
        fetchInfo()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Start with logo invisible and small
        nutrackImage.alpha = 0.0
        nutrackImage.transform = CGAffineTransform(scaleX: 0.5, y: 0.5).rotated(by: -.pi/2)
    }
    
    private func startLoadingAnimation() {
        UIView.animate(
            withDuration: 1.0,
            delay: 0,
            usingSpringWithDamping: 0.5,
            initialSpringVelocity: 0.5,
            options: [.curveEaseInOut],
            animations: {
                // Fade in, scale up, and rotate to normal
                self.nutrackImage.alpha = 1.0
                self.nutrackImage.transform = .identity
            },
            completion: { _ in
                self.pulseAndShakeLogo()
            }
        )
    }
    
    func pulseAndShakeLogo() {
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.autoreverse, .curveEaseInOut, .repeat, .allowUserInteraction],
            animations: {
                // Pulse up
                self.nutrackImage.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            },
            completion: nil
        )
    }
}
