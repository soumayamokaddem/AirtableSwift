//
//  ViewControllerDetails.swift
//  Airtable Restaurant Reviews
//
//  Created by Timothy Dietrich on 9/30/15.
//
//  Serves as the view controller for the Details view.
//  Displays detailed information about the selected
//  restaurant, including location, rating, price
//  cuisine, and notes. If applicable, a photo of
//  the restaurant is displayed. Note that calls
//  are made to the Airtable API when needed to
//  to get related records from the Cuisines and 
//  City Districts table, and that all calls
//  are asynchronous.
//

import UIKit


class ViewControllerDetails: UIViewController {
    
    // Text labels.
    @IBOutlet weak var textLabelDistrict: UILabel!
    @IBOutlet weak var textLabelRating: UILabel!
    @IBOutlet weak var textLabelCost: UILabel!    
    @IBOutlet weak var textLabelCuisine: UILabel!
    
    // Text view for notes.
    @IBOutlet weak var textViewNotes: UITextView!
    
    // Image view for the primary photo.
    @IBOutlet weak var imageViewPrimary: UIImageView!
    
    // Object used for the activity indicator.
    var activityIndicator: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Display any notes.
        var notes: String
        if let _: AnyObject = selectedRestaurant["Notes"] {
            notes = selectedRestaurant["Notes"] as! String
        } else {
            notes = "None."
        }
        textViewNotes.text = notes
        
        
        // Display the cost.
        var cost: String
        if let _: AnyObject = selectedRestaurant["Cost"] {
            cost = selectedRestaurant["Cost"] as! String
        } else {
            cost = "Unknown"
        }
        textLabelCost.text = cost

        
        // Display the rating.
        var rating: String
        if let _: AnyObject = selectedRestaurant["My Rating"] {
            rating = selectedRestaurant["My Rating"] as! String
        } else {
            rating = ""
        }
        
        
        // Map the rating to emoji stars.
        switch ( rating ) {
            case ( "1 - Amazing" ): rating = "⭐️⭐️⭐️⭐️";
            case ( "2 - Great" ): rating = "⭐️⭐️⭐️";
            case ( "3 - Good" ): rating = "⭐️⭐️";
            case ( "4 - Meh" ): rating = "⭐️";
            default: rating = "Not Rated";
        }
        textLabelRating.text = rating
        
        
        // If there are pictures of the restaurant...
        if let _: AnyObject = selectedRestaurant["Pictures"] {
            
            // Note: We're only displaying the first picture here.
            let pictures = ( selectedRestaurant["Pictures"] as! NSArray )
            let picture = ( pictures[0] as! NSDictionary )
            let pictureURL = picture["url"] as! String
            
            // Load the image view (asynchronously) via the URL.
            let imageURL = NSURL(string: pictureURL)
            let urlRequest = NSURLRequest(URL: imageURL!)
            NSURLConnection.sendAsynchronousRequest(urlRequest, queue: NSOperationQueue.mainQueue()) {
                response, data, error in
                    if error == nil && data != nil {
                        self.imageViewPrimary.image = UIImage(data: data!)
                        self.imageViewPrimary.contentMode = UIViewContentMode.ScaleAspectFit
                    }
            }
            
        }
        
        
        // If the restaurant has been assigned to one or more districts...
        if let _: AnyObject = selectedRestaurant["District"] {
            
            // Get the restaurant's district ID, and the name from the districts dictionary.
            let assignedDistricts: NSArray = selectedRestaurant["District"] as! NSArray
            let districtID: String = assignedDistricts[0] as! String
            
            
            // If we already have that district loaded into the districts array...
            if let districtName: String = districts[districtID] as? String {
                
                // Display the district name.
                textLabelDistrict.text = districtName
                
            } else {
                
                // Get the district info via the API.
                textLabelDistrict.text = "Loading..."
                getDistrictFromAPI(districtID)
                                
            }
 
        } else {
            textLabelDistrict.text = "Not Available"
        }

        
        // If the restaurant has been assigned to one or more cuisines...
        if let _: AnyObject = selectedRestaurant["Cuisine"] {
            
            // Get the restaurant's cuisine ID, and the name from the cuisines dictionary.
            let assignedCuisines: NSArray = selectedRestaurant["Cuisine"] as! NSArray
            let cuisineID: String = assignedCuisines[0] as! String
            
            // If we already have the cuisine loaded into the cuisines array...
            if let cuisineName: String = cuisines[cuisineID] as? String {
                
                // Display the cuisine name.
                textLabelCuisine.text = cuisineName
                
            } else {
                
                // Get the cuisine info via the API.
                textLabelCuisine.text = "Loading..."
                getCuisineFromAPI(cuisineID)
                
            }
            
        } else {
            textLabelCuisine.text = "Not Available"
        }
        
    }
    
    
    
    
    // Loads a district record, specified by it's ID, via the API.
    func getDistrictFromAPI(districtID: String) {
        
        
        // Prepare the URL request.
        let url = "https://api.airtable.com/v0/\(airtableAppID)/City%20Districts/" + districtID
        let urlRequest = NSMutableURLRequest(URL: NSURL(string: url)!)
        
        // Specify the Authorization header.
        urlRequest.addValue("Bearer \(airtableAPIKey)", forHTTPHeaderField: "Authorization")
        
        // Prepare an NSURLSession to send the data request.
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        
        // Create the data task, along with a completion handler.
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(urlRequest, completionHandler: {(data, response, error) in
            
            // Catch general errors (such as unsupported URLs).
            guard error == nil else {
                print("Error")
                print(error)
                restaurantsLoading = false
                return
            }
            
            // Catch HTTP errors (anything other than "200 OK").
            let httpResponse: NSHTTPURLResponse = (response as? NSHTTPURLResponse)!
            if httpResponse.statusCode != 200 {
                print("HTTP Error")
                print(httpResponse.statusCode)
                restaurantsLoading = false
                return
            }
            
            // Check to see that the response included data.
            guard let responseData = data else {
                print("Error: No data was found in the response.")
                restaurantsLoading = false
                return
            }
            
            // Try to serialize the data to JSON.
            do {
                
                let jsonData = try NSJSONSerialization.JSONObjectWithData(responseData, options:[]) as! NSDictionary
                
                // Get the fields from the JSON data.
                if let fields = (jsonData["fields"] as? NSDictionary) {
                    
                    // Get the Name from the fields.
                    if let districtName = (fields["Name"] as? String) {
                        
                        // Store the district name in the array for later use.
                        districts[districtID] = districtName
                        
                        // Display the district name.
                        dispatch_async(dispatch_get_main_queue(), {
                            self.textLabelDistrict.text = districtName
                        })
                        
                    } else {
                        print("Error: No name received.")
                    }
                    
                } else {
                    print("Error: No fields received.")
                }
                
            } catch {
                print("Error: Unable to convert data to JSON.")
                return
            }
            
        })
        
        // Start / resume the data task.
        task.resume()
        
        
    }
    
    
    
    
    // Loads a cuisine record, specified by it's ID, via the API.
    func getCuisineFromAPI(cuisineID: String) {
        
        // Prepare the URL request.
        let url = "https://api.airtable.com/v0/\(airtableAppID)/Cuisines/" + cuisineID
        let urlRequest = NSMutableURLRequest(URL: NSURL(string: url)!)
        
        // Specify the Authorization header.
        urlRequest.addValue("Bearer \(airtableAPIKey)", forHTTPHeaderField: "Authorization")
        
        // Prepare an NSURLSession to send the data request.
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: config)
        
        // Create the data task, along with a completion handler.
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(urlRequest, completionHandler: {(data, response, error) in
            
            // Catch general errors (such as unsupported URLs).
            guard error == nil else {
                print("Error")
                print(error)
                restaurantsLoading = false
                return
            }
            
            // Catch HTTP errors (anything other than "200 OK").
            let httpResponse: NSHTTPURLResponse = (response as? NSHTTPURLResponse)!
            if httpResponse.statusCode != 200 {
                print("HTTP Error")
                print(httpResponse.statusCode)
                restaurantsLoading = false
                return
            }
            
            // Check to see that the response included data.
            guard let responseData = data else {
                print("Error: No data was found in the response.")
                restaurantsLoading = false
                return
            }
            
            // Try to serialize the data to JSON.
            do {
                
                let jsonData = try NSJSONSerialization.JSONObjectWithData(responseData, options:[]) as! NSDictionary
                
                // Get the fields from the JSON data.
                if let fields = (jsonData["fields"] as? NSDictionary) {
                    
                    // Get the Name from the fields.
                    if let cuisineName = (fields["Name"] as? String) {
                        
                        // Store the cuisine name in the array for later use.
                        cuisines[cuisineID] = cuisineName
                        
                        // Display the cuisine name.
                        dispatch_async(dispatch_get_main_queue(), {
                            self.textLabelCuisine.text = cuisineName
                        })
                        
                    } else {
                        print("Error: No name received.")
                    }
                    
                } else {
                    print("Error: No fields received.")
                }
                
            } catch {
                print("Error: Unable to convert data to JSON.")
                return
            }
            
        })
        
        // Start / resume the data task.
        task.resume()
        
    }
    
    
    
    
}
