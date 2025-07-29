import UIKit
import Firebase
import FirebaseAuth
struct LoggedFood {
    let id: String
    let name: String
    let quantity: Int
    let calories: Double
    let protein: Double
    let carbs: Double
    let sugars: Double
    let fats: Double
    let photo: String?
    let timeStamp: Date?
}
class FoodLogTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var selectedDate: Date?

    @IBOutlet weak var tableView: UITableView!
    //    let db = Firestore.firestore()
    //    let userID = Auth.auth().currentUser?.uid
    
    var foodLog: [LoggedFood] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        //           db.collection("users").document(userID!).getDocument { (document, error) in
        //               if let document = document, document.exists {
        //
        //               } else {
        //                   print("Error fetching document: \(error?.localizedDescription ?? "Unknown error")")
        //               }
        //           }
        fetchFoodLog()
        self.hideKeyboardWhenTappedAround()
        
        tableView.dataSource = self
        tableView.delegate = self
        //tableView.rowHeight = UITableView.automaticDimension
        tableView.rowHeight = 70
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return foodLog.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath) as! SearchResultCell
        
        let food = foodLog[indexPath.row]
        cell.foodImageView.contentMode = .scaleAspectFit
        cell.foodNameLabel.text = food.name
        cell.backgroundColor = .oppositeBackground
        cell.contentView.layer.cornerRadius = 15
        
        if let photoURL = food.photo, let url = URL(string: photoURL) {
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
        let selectedFood = foodLog[indexPath.row]
        let alert = UIAlertController(
            title: selectedFood.name,
            message: """
                               Quantity: \(selectedFood.quantity)
                               Calories: \(selectedFood.calories)cal
                               Protein: \(selectedFood.protein)g
                               Carbs: \(selectedFood.carbs)g
                               Sugars: \(selectedFood.sugars)g
                               Fats: \(selectedFood.fats)g
                               """,
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
//        present(alert, animated: true)
        
        self.performSegue(withIdentifier: "showFoodInfo", sender: selectedFood)
            
        
        
        
    }
    
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "showFoodInfo",
               let nextVC = segue.destination as? FoodLogInfoViewController,
               let food = sender as? LoggedFood {
                nextVC.food = food
            }
        }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completionHandler in
            self?.deleteEntry(at: indexPath)
            completionHandler(true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    func deleteEntry(at indexPath: IndexPath) {
        guard let user = Auth.auth().currentUser else { return }
        guard let date = selectedDate else {
            print("selectedDate is nil")
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateKey = formatter.string(from: date)

        let food = foodLog[indexPath.row]
        let db = Firestore.firestore()

        let logRef = db.collection("users")
            .document(user.uid)
            .collection("logs")
            .document(dateKey)

        logRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching current totals: \(error)")
                return
            }

            guard let data = document?.data() else {
                print("No data found for the date log.")
                return
            }

            let currentCalories = data["calories"] as? Double ?? 0
            let currentProtein = data["protein"] as? Double ?? 0
            let currentCarbs = data["carbs"] as? Double ?? 0
            let currentSugars = data["sugars"] as? Double ?? 0
            let currentFats = data["fats"] as? Double ?? 0

            let newCalories = self.truncateToDecimalPlaces(currentCalories - food.calories, decimalPlaces: 2)
            let newProtein = self.truncateToDecimalPlaces(currentProtein - food.protein, decimalPlaces: 2)
            let newCarbs = self.truncateToDecimalPlaces(currentCarbs - food.carbs, decimalPlaces: 2)
            let newSugars = self.truncateToDecimalPlaces(currentSugars - food.sugars, decimalPlaces: 2)
            let newFats = self.truncateToDecimalPlaces(currentFats - food.fats, decimalPlaces: 2)

            logRef.updateData([
                "calories": newCalories,
                "protein": newProtein,
                "carbs": newCarbs,
                "sugars": newSugars,
                "fats": newFats
            ]) { error in
                if let error = error {
                    print("Failed to update totals: \(error)")
                } else {
                    print("Successfully updated totals after deletion.")
                }
            }

            let foodRef = logRef.collection("foods").document(food.id)
            foodRef.delete { error in
                if let error = error {
                    print("Failed to delete food: \(error)")
                    return
                }

                self.foodLog.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }


    // Truncate function
    func truncateToDecimalPlaces(_ value: Double, decimalPlaces: Int) -> Double {
        let divisor = pow(10.0, Double(decimalPlaces))
        return floor(value * divisor) / divisor
    }
    
    

    
    func fetchFoodLog() {
        guard let user = Auth.auth().currentUser else { return }
        guard let date = selectedDate else {
            print("selectedDate is nil")
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateKey = formatter.string(from: date)

        let db = Firestore.firestore()
        db.collection("users")
            .document(user.uid)
            .collection("logs")
            .document(dateKey)
            .collection("foods")
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching food log: \(error)")
                    return
                }

                self.foodLog = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    return LoggedFood(
                        id: doc.documentID,
                        name: data["name"] as? String ?? "Unknown",
                        quantity: data["quantity"] as? Int ?? 0,
                        calories: data["calories"] as? Double ?? 0,
                        protein: data["protein"] as? Double ?? 0,
                        carbs: data["carbs"] as? Double ?? 0,
                        sugars: data["sugars"] as? Double ?? 0,
                        fats: data["fats"] as? Double ?? 0,
                        photo: data["photo"] as? String ?? "",
                        timeStamp: (data["timestamp"] as? Timestamp)?.dateValue()
                    )
                } ?? []
                self.tableView.reloadData()
            }
    }
}
