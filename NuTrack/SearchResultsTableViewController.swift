import UIKit
import Firebase
import FirebaseAuth

class SearchResultsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UITextFieldDelegate {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var foodTypeSegmentedControl: UISegmentedControl!
    //    let db = Firestore.firestore()
//    let userID = Auth.auth().currentUser?.uid
    
    var commonFoods: [Food] = []
    var brandedFoods: [Food] = []
    var searchResults: [Food] = []

       override func viewDidLoad() {
           super.viewDidLoad()
//           db.collection("users").document(userID!).getDocument { (document, error) in
//               if let document = document, document.exists {
//                   
//               } else {
//                   print("Error fetching document: \(error?.localizedDescription ?? "Unknown error")")
//               }
//           }

           self.hideKeyboardWhenTappedAround()
           updateDisplayedFoods(selectedIndex: 1)
           
           tableView.dataSource = self
           tableView.delegate = self
           searchBar.delegate = self
           //tableView.rowHeight = UITableView.automaticDimension
           tableView.rowHeight = 70
           
           searchBar.delegate = self
       }
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        updateDisplayedFoods(selectedIndex: sender.selectedSegmentIndex)
    }
  
    
        func updateDisplayedFoods(selectedIndex: Int) {
            switch selectedIndex {
            case 0:
                searchResults = commonFoods
            case 1:
                searchResults = brandedFoods
            default:
                searchResults = []
            }
            tableView.reloadData()
        }
    
       // Called when 'return' key pressed
       func textFieldShouldReturn(_ textField:UITextField) -> Bool {
           textField.resignFirstResponder()
           return true
       }
        
       // Called when the user clicks on the view outside of the UITextField
       override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
           self.view.endEditing(true)
       }
       
       
       func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
           searchItems(query: searchBar.text ?? "")
           searchBar.resignFirstResponder()
       }
           
               
       func searchItems(query: String) {
           guard let url = URL(string: "https://trackapi.nutritionix.com/v2/search/instant?query=\(query)") else { return }
           
           var request = URLRequest(url: url)
           request.httpMethod = "GET"
           request.setValue(Config.value(forKey: "NUTRITIONIX_SEARCH_ID"), forHTTPHeaderField: "x-app-id")
           request.setValue(Config.value(forKey: "NUTRITIONIX_SEARCH_KEY"), forHTTPHeaderField: "x-app-key")
           
           fetchAndParseData(request: request) { commonFoods, brandedFoods in
                       self.commonFoods = commonFoods
                       self.brandedFoods = brandedFoods
                       self.updateDisplayedFoods(selectedIndex: self.foodTypeSegmentedControl.selectedSegmentIndex)
            }
       }
           
           
       func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
           return searchResults.count
       }
           
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath) as! SearchResultCell
        
        let food = searchResults[indexPath.row]
        cell.foodImageView.contentMode = .scaleAspectFit
        cell.foodNameLabel.text = food.food_name
        cell.contentView.backgroundColor = .oppositeBackground
        cell.contentView.layer.cornerRadius = 15
        
        if let cals = food.nf_calories {
                cell.caloriesLabel.text = "\(Int(round(cals))) cals"
            cell.caloriesLabel.textColor = .backgroundColors
            } else {
                cell.caloriesLabel.text = ""
            }
        
        if let photoURL = food.photo?.thumb, let url = URL(string: photoURL) {
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("Error fetching image: \(error)")
                    return
                }
                
                guard let data = data else { return }
                
                DispatchQueue.main.async {
                    if let image = UIImage(data: data) {
                        cell.foodImageView.image = image
                    }
                }
            }.resume()
        }
        
        return cell
    }

                          
       func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
           self.view.endEditing(true)

           tableView.deselectRow(at: indexPath, animated: true)
           let selectedFood = searchResults[indexPath.row]
           
           getNutritionInfo(food: selectedFood) { food in
               if let food = food {
                   DispatchQueue.main.async {
                       self.performSegue(withIdentifier: "showNutritionFacts", sender: food)
                   }
               }
           }
       }
           
               
       override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
           if segue.identifier == "showNutritionFacts",
              let nextVC = segue.destination as? BarcodeNutritionFactsViewController,
              let food = sender as? Food {
               nextVC.food = food
           }
       }
               

    func fetchAndParseData(request: URLRequest, completion: @escaping ([Food], [Food]) -> Void) {
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error)")
                completion([], [])
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion([], [])
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    var commonFoods: [Food] = []
                    var brandedFoods: [Food] = []
                    
                    if let commonFoodsData = json["common"] as? [[String: Any]] {
                        for foodDict in commonFoodsData {
                            let photoDict = foodDict["photo"] as? [String: String]
                            let photoThumb = photoDict?["thumb"]
                            
                            let food = Food(
                                food_name: foodDict["food_name"] as? String,
                                brand_name: "",
                                serving_qty: nil,
                                serving_unit: nil,
                                serving_weight_grams: nil,
                                nf_metric_qty: nil,
                                nf_metric_uom: nil,
                                nf_calories: foodDict["nf_calories"] as? Double, // Try to get calories if available
                                nf_total_fat: nil,
                                nf_saturated_fat: nil,
                                nf_sodium: nil,
                                nf_total_carbohydrate: nil,
                                nf_protein: nil,
                                nf_dietary_fiber: nil,
                                nf_sugars: nil,
                                nf_potassium: nil,
                                nf_ingredient_statement: nil,
                                photo: Food.Photo(thumb: photoThumb),
                                nix_item_id: nil
                            )
                            commonFoods.append(food)
                        }
                    }
                    
                    if let brandedFoodsData = json["branded"] as? [[String: Any]] {
                        for foodDict in brandedFoodsData {
                            let photoDict = foodDict["photo"] as? [String: String]
                            let photoThumb = photoDict?["thumb"]
                            
                            let food = Food(
                                food_name: foodDict["brand_name_item_name"] as? String,
                                brand_name: foodDict["brand_name"] as? String ?? "",
                                serving_qty: nil,
                                serving_unit: nil,
                                serving_weight_grams: nil,
                                nf_metric_qty: nil,
                                nf_metric_uom: nil,
                                nf_calories: foodDict["nf_calories"] as? Double, // Get calories from API
                                nf_total_fat: nil,
                                nf_saturated_fat: nil,
                                nf_sodium: nil,
                                nf_total_carbohydrate: nil,
                                nf_protein: nil,
                                nf_dietary_fiber: nil,
                                nf_sugars: nil,
                                nf_potassium: nil,
                                nf_ingredient_statement: nil,
                                photo: Food.Photo(thumb: photoThumb),
                                nix_item_id: foodDict["nix_item_id"] as? String
                            )
                            brandedFoods.append(food)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        completion(commonFoods, brandedFoods)
                    }
                } else {
                    print("Failed to parse JSON")
                    completion([], [])
                }
            } catch {
                print("JSON Error: \(error)")
                completion([], [])
            }
        }.resume()
    }


                          
       func getNutritionInfo(food: Food, completion: @escaping (Food?) -> Void) {
           if let nix_item_id = food.nix_item_id {
               guard let url = URL(string: "https://trackapi.nutritionix.com/v2/search/item?nix_item_id=\(nix_item_id)") else { return }
               
               var request = URLRequest(url: url)
               request.httpMethod = "GET"
               request.setValue(Config.value(forKey: "NUTRITIONIX_SEARCH_ID"), forHTTPHeaderField: "x-app-id")
               request.setValue(Config.value(forKey: "NUTRITIONIX_SEARCH_KEY"), forHTTPHeaderField: "x-app-key")
               
               fetchNutritionData(request: request, completion: completion)
           } else {
               guard let url = URL(string: "https://trackapi.nutritionix.com/v2/natural/nutrients") else { return }
               
               var request = URLRequest(url: url)
               request.httpMethod = "POST"
               request.setValue("application/json", forHTTPHeaderField: "Content-Type")
               request.setValue(Config.value(forKey: "NUTRITIONIX_SEARCH_ID"), forHTTPHeaderField: "x-app-id")
               request.setValue(Config.value(forKey: "NUTRITIONIX_SEARCH_KEY"), forHTTPHeaderField: "x-app-key")
               
               do {
                   let query = ["query": food.food_name ?? ""]
                   request.httpBody = try JSONSerialization.data(withJSONObject: query, options: [])
               } catch {
                   print("JSON Body Error: \(error)")
                   return
               }
               
               fetchNutritionData(request: request, completion: completion)
           }
       }
       
       func fetchNutritionData(request: URLRequest, completion: @escaping (Food?) -> Void) {
           URLSession.shared.dataTask(with: request) { data, response, error in
               if let error = error {
                   print("Error: \(error)")
                   completion(nil)
                   return
               }
               
               guard let data = data else {
                   print("No data received")
                   completion(nil)
                   return
               }
               
               do {
                   if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                       if let foods = json["foods"] as? [[String: Any]] {
                           if let firstFood = foods.first {
                               let food = Food(
                                   food_name: firstFood["food_name"] as? String,
                                   brand_name: firstFood["brand_name"] as? String ?? "",
                                   serving_qty: firstFood["serving_qty"] as? Int,
                                   serving_unit: firstFood["serving_unit"] as? String,
                                   serving_weight_grams: firstFood["serving_weight_grams"] as? Double,
                                   nf_metric_qty: firstFood["nf_metric_qty"] as? Double,
                                   nf_metric_uom: firstFood["nf_metric_uom"] as? String,
                                   nf_calories: firstFood["nf_calories"] as? Double,
                                   nf_total_fat: firstFood["nf_total_fat"] as? Double,
                                   nf_saturated_fat: firstFood["nf_saturated_fat"] as? Double,
                                   nf_sodium: firstFood["nf_sodium"] as? Double,
                                   nf_total_carbohydrate: firstFood["nf_total_carbohydrate"] as? Double,
                                   nf_protein: firstFood["nf_protein"] as? Double,
                                   nf_dietary_fiber: firstFood["nf_dietary_fiber"] as? Double,
                                   nf_sugars: firstFood["nf_sugars"] as? Double,
                                   nf_potassium: firstFood["nf_potassium"] as? Double,
                                   nf_ingredient_statement: firstFood["nf_ingredient_statement"] as? String,
                                   photo: nil,
                                   nix_item_id: firstFood["nix_item_id"] as? String
                               )
                               completion(food)
                           } else {
                               completion(nil)
                           }
                       } else {
                           completion(nil)
                       }
                   } else {
                       print("Failed to parse JSON")
                       completion(nil)
                   }
               } catch {
                   print("JSON Error: \(error)")
                   completion(nil)
               }
           }.resume()
       }
   }
