//
//  ImageScanAPI.swift
//  NuTrack
//
//  Created by Anthony Rojas on 4/7/25.
//

import UIKit

extension UIImage {
    func resized(to maxDimension: CGFloat) -> UIImage {
        let aspectRatio = size.width / size.height
        var newSize: CGSize
        
        if aspectRatio > 1 { // Landscape
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else { // Portrait or square
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

extension UIImage {
    func compressTo(maxSizeMB: Int) -> Data? {
        let maxSizeBytes = maxSizeMB * 1000 * 1000
        var compressionQuality: CGFloat = 1.0
        var compressedData: Data?
        
        // Binary search parameters
        var low: CGFloat = 0
        var high: CGFloat = 1.0
        let threshold: CGFloat = 0.05
        
        for _ in 0..<10 { // Max 10 iterations
            compressionQuality = (low + high) / 2
            guard let data = jpegData(compressionQuality: compressionQuality) else { return nil }
            
            if data.count < maxSizeBytes {
                low = compressionQuality
                compressedData = data
            } else {
                high = compressionQuality
            }
            
            if abs(high - low) < threshold { break }
        }
        
        return compressedData ?? jpegData(compressionQuality: compressionQuality)
    }
}


func getLogMealNutritionalInfo(imageData: Data, apiUserToken: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
    // Step 1: Upload Image for Segmentation
    uploadImageForSegmentation(imageData: imageData, apiUserToken: apiUserToken) { result in
        switch result {
        case .success(let imageId):
            // Step 2: Fetch Nutritional Information
            fetchNutritionalInfo(imageId: imageId, apiUserToken: apiUserToken, completion: completion)
        case .failure(let error):
            completion(.failure(error))
        }
    }
}

// Helper function to upload image for segmentation
private func uploadImageForSegmentation(imageData: Data, apiUserToken: String, completion: @escaping (Result<String, Error>) -> Void) {
    guard let url = URL(string: "https://api.logmeal.com/v2/image/segmentation/complete") else {
        completion(.failure(NSError(domain: "LogMealError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(apiUserToken)", forHTTPHeaderField: "Authorization")
    
    // Create multipart form data
    let boundary = "Boundary-\(UUID().uuidString)"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    
    var body = Data()
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"image\"; filename=\"food.jpg\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
    body.append(imageData)
    body.append("\r\n".data(using: .utf8)!)
    body.append("--\(boundary)--\r\n".data(using: .utf8)!)
    
    request.httpBody = body
    
    // Perform the request
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error performing Image Segmentation API Request")
            completion(.failure(error))
            return
        }
        
        guard let data = data else {
            completion(.failure(NSError(domain: "LogMealError", code: 2, userInfo: [NSLocalizedDescriptionKey: "No Image Segmentation data received"])))
            return
        }
        
        do {
            guard let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                completion(.failure(NSError(domain: "LogMealError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to unpack image segmentation JSON"])))
                return
            }
            
            print(jsonResponse)
            
            guard let imageId = jsonResponse["imageId"] as? Int else {
                completion(.failure(NSError(domain: "LogMealError", code: 9, userInfo: [NSLocalizedDescriptionKey: "Failed to get imageId"])))
                return
            }
            
            completion(.success("\(imageId)"))
        } catch {
            print("Unexpected Error while unpacking image segmentation JSON")
            completion(.failure(error))
        }
    }
    
    task.resume()
}

// Helper function to fetch nutritional information
private func fetchNutritionalInfo(imageId: String, apiUserToken: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
    guard let url = URL(string: "https://api.logmeal.com/v2/recipe/nutritionalInfo") else {
        completion(.failure(NSError(domain: "LogMealError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(apiUserToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    // Create JSON body
    let requestBody = ["imageId": imageId]
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
    } catch {
        print("Could not serialize JSON for nutritional informational request")
        completion(.failure(error))
        return
    }
    
    print("--- Performing Nutritional Information API Request ---")
    
    // Perform the request
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("API Request Failed")
            completion(.failure(error))
            return
        }
        
        guard let data = data else {
            completion(.failure(NSError(domain: "LogMealError", code: 5, userInfo: [NSLocalizedDescriptionKey: "No nutritional data received"])))
            return
        }
        
        do {
            if let nutritionalInfo = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                completion(.success(nutritionalInfo))
            } else {
                completion(.failure(NSError(domain: "LogMealError", code: 6, userInfo: [NSLocalizedDescriptionKey: "Could not turn nutrition data into JSON"])))
            }
        } catch {
            print("Unexpected error occurred while Serializing Nutritional Information JSON")
            completion(.failure(error))
        }
    }
    
    task.resume()
}

private func getNutrient(nutrients: NSDictionary, nutrientCode: String) -> Double {
    guard let nutrientDict = nutrients[nutrientCode] as? NSDictionary else {
        return 0
    }
    
    var result = nutrientDict.object(forKey: "quantity") as? Double ?? 0
    
    return round(num: result, sigFigs: 3)
}

func stringListToString(list: [String]) -> String {
    var result = ""
    
    for i in 0..<list.count {
        result += list[i]
        if i != list.count - 1 {
            result += ", "
        }
    }
    
    return result
}

private func round(num: Double, sigFigs: Int) -> Double {
    let formatter = NumberFormatter()

    formatter.usesSignificantDigits = true
    formatter.maximumSignificantDigits = sigFigs
    formatter.minimumSignificantDigits = sigFigs
    
    return Double(formatter.string(from: num as NSNumber)!)!
}

func jsonToFood(nutritionalInfo: [String : Any]) -> Food? {
    
    guard let hasNutritionalInfo = nutritionalInfo["hasNutritionalInfo"] as? Int else {
        print("No nutritional Info")
        return nil
    }
    
    guard hasNutritionalInfo == 1 else {
        print("No nutritional Info")
        return nil
    }
    
    guard let facts = nutritionalInfo["nutritional_info"] as? NSDictionary else {
        print("Error Reading Nutritional Info")
        return nil
    }
    
    let foodNamesList = nutritionalInfo["foodName"] as? [String] ?? ["Name Not Available"]
    
    var foodNames = stringListToString(list: foodNamesList)
    
    guard let nutrients = facts["totalNutrients"] as? NSDictionary else {
        print("Error Reading Nutrients")
        return nil
    }

    let food = Food(
        food_name: foodNames,
        brand_name: "",
        serving_qty: nil,
        serving_unit: nil,
        serving_weight_grams: round(num: nutritionalInfo["serving_size"] as? Double ?? 0, sigFigs: 3),
        nf_metric_qty: nil,
        nf_metric_uom: nil,
        nf_calories: round(num: facts["calories"] as? Double ?? 0, sigFigs: 3),
        nf_total_fat: getNutrient(nutrients: nutrients, nutrientCode: "FAT"),
        nf_saturated_fat: getNutrient(nutrients: nutrients, nutrientCode: "FASAT"),
        nf_sodium: getNutrient(nutrients: nutrients, nutrientCode: "NA"),
        nf_total_carbohydrate: getNutrient(nutrients: nutrients, nutrientCode: "CHOCDF"),
        nf_protein: getNutrient(nutrients: nutrients, nutrientCode: "PROCNT"),
        nf_dietary_fiber: getNutrient(nutrients: nutrients, nutrientCode: "FIBTG"),
        nf_sugars: getNutrient(nutrients: nutrients, nutrientCode: "SUGAR"),
        nf_potassium: getNutrient(nutrients: nutrients, nutrientCode: "K"),
        nf_ingredient_statement: "Not Available",
        photo: nil,
        nix_item_id: nil
    )

    return food
}
