//
//  AllergyDetectionService.swift
//  NuTrack
//
//  Created by Zuhair Merali on 4/9/25.
//

import Foundation

class AllergyDetectionService {
    // Gemini API key
    private let apiKey = Config.value(forKey: "GEMINI_API_KEY")
    
    // Function to analyze food for allergies using Gemini API
    func analyzeFood(foodName: String, completion: @escaping ([String: Int]?, Error?) -> Void) {
        // Gemini API endpoint
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "AllergyDetectionService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare prompt for the API
        let prompt = """
        Analyze this food: "\(foodName)" and determine if it contains or is likely to contain:
        1. Nuts (any kind of nuts including peanuts, tree nuts, etc.)
        2. Dairy (milk, cheese, cream, etc.)
        3. Seafood (fish, shellfish, etc.)
        
        Return the result in JSON format with exactly this structure:
        {
          "allergies": {
            "nuts": 0 or 1,
            "dairy": 0 or 1,
            "seafood": 0 or 1
          }
        }
        
        Use 0 if the allergen is present (meaning there IS an allergy concern)
        Use 1 if the allergen is NOT present (meaning it's safe)
        """
        
        // Create request body
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.0,
                "responseMimeType": "application/json"
            ]
        ]
        
        // Convert request body to JSON data
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
        } catch {
            completion(nil, error)
            return
        }
        
        // Make API request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, error ?? NSError(domain: "AllergyDetectionService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Network error"]))
                return
            }
            
            do {
                // Parse the response
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let candidates = jsonResponse["candidates"] as? [[String: Any]],
                   let firstCandidate = candidates.first,
                   let content = firstCandidate["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let firstPart = parts.first,
                   let text = firstPart["text"] as? String {
                    
                    // Extract JSON from the response text
                    if let jsonStartIndex = text.range(of: "{")?.lowerBound,
                       let jsonEndIndex = text.range(of: "}", options: .backwards)?.upperBound {
                        let jsonSubstring = text[jsonStartIndex..<jsonEndIndex]
                        let jsonData = Data(jsonSubstring.utf8)
                        
                        if let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                           let allergies = json["allergies"] as? [String: Int] {
                            completion(allergies, nil)
                            return
                        }
                    }
                }
                
                completion(nil, NSError(domain: "AllergyDetectionService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"]))
                
            } catch {
                completion(nil, error)
            }
        }
        
        task.resume()
    }
    
    // Helper method to check if a food conflicts with user allergies
    func checkAllergyConflicts(foodName: String, userAllergies: [String: Int], completion: @escaping ([String]?, Error?) -> Void) {
        analyzeFood(foodName: foodName) { foodAllergens, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let foodAllergens = foodAllergens else {
                completion(nil, NSError(domain: "AllergyDetectionService", code: 4, userInfo: [NSLocalizedDescriptionKey: "No allergen data"]))
                return
            }
            
            // Check for conflicts (user is allergic (0) and food contains allergen (0))
            var conflicts: [String] = []
            
            for (allergen, userValue) in userAllergies {
                if let foodValue = foodAllergens[allergen], userValue == 0 && foodValue == 0 {
                    conflicts.append(allergen)
                }
            }
            
            completion(conflicts.isEmpty ? nil : conflicts, nil)
        }
    }
}
