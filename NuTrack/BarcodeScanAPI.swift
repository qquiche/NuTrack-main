import Foundation

// Define the struct models

struct Config {
    static func value(forKey key: String) -> String {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
              let value = dict[key] as? String else {
            fatalError("Missing key: \(key) in Config.plist")
        }
        return value
    }
}


struct FoodResponse: Codable {
    let foods: [Food]
}



struct Food: Codable {
    let food_name: String?
    let brand_name: String
    let serving_qty: Int?
    let serving_unit: String?
    let serving_weight_grams: Double?
    let nf_metric_qty: Double?
    let nf_metric_uom: String?
    let nf_calories: Double?
    let nf_total_fat: Double?
    let nf_saturated_fat: Double?
    let nf_sodium: Double?
    let nf_total_carbohydrate: Double?
    let nf_protein: Double?
    let nf_dietary_fiber: Double?
    let nf_sugars: Double?
    let nf_potassium: Double?
    let nf_ingredient_statement: String?
    

    struct Photo: Codable {
        let thumb: String?
    }
    let photo: Photo?
    let nix_item_id: String?
}

// Function to fetch food data using a barcode
func fetchFoodData(for barcode: String, completion: @escaping (FoodResponse?) -> Void) {
    let urlString = "https://trackapi.nutritionix.com/v2/search/item/?upc=\(barcode)"
    guard let url = URL(string: urlString) else {
        print("Invalid URL")
        completion(nil)
        return
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.addValue(Config.value(forKey: "NUTRITIONIX_APP_ID"), forHTTPHeaderField: "x-app-id") // Replace with actual app ID
    request.addValue(Config.value(forKey: "NUTRITIONIX_API_KEY"), forHTTPHeaderField: "x-app-key") // Replace with actual app key
    request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error: \(error.localizedDescription)")
            completion(nil)
            return
        }
        
        guard let data = data else {
            print("No data received")
            completion(nil)
            return
        }
        
        do {
            let decoder = JSONDecoder()
            let foodResponse = try decoder.decode(FoodResponse.self, from: data)
            completion(foodResponse)
        } catch {
            print("Decoding error: \(error)")
            completion(nil)
        }
    }
    
    task.resume()
}

func main() {
    let barcode = "49000000450"
    
    fetchFoodData(for: barcode) { foodResponse in
        if let foodResponse = foodResponse {
            if let firstFood = foodResponse.foods.first {
                print("Food Name: \(firstFood.food_name ?? "Name not found")")
                print("Brand: \(firstFood.brand_name)")
                print("Calories: \(firstFood.nf_calories ?? 0)")
                print("Ingredients: \(firstFood.nf_ingredient_statement ?? "N/A")")
                print("Thumbnail: \(firstFood.photo?.thumb ?? "No image available")")
            }
        } else {
            print("Failed to fetch food data")
        }
        exit(0) // Terminate program (useful for command-line apps)
    }
}





