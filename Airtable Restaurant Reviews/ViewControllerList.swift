//
//  ViewControllerList.swift
//  Airtable Restaurant Reviews
//
//  Created by Timothy Dietrich on 9/30/15.
//
//  Serves as the view controller for the List view.
//  Makes calls to the Airtable API to retrieve a list of restaurants,
//  which are then displayed in a table view.
//  
//  Note that all calls to the API are done asynchronously,
//  and that in cases where multiple calls are needed,
//  an offset is used to retrieve the next "batch" of records.
//  
//  Also note that the view uses a refresh controller, which
//  allows the user to "pull to refresh" the data, and that
//  data is loaded as needed if the user scrolls the table
//  beyond the point at which data has been pre-loaded.
// 

import UIKit


// Create an array for the restaurants.
// Each restaurant is stored as a dictionary.
var restaurants = [Dictionary<String,AnyObject>]()


// Create dictionaries for the districts and cuisines.
var districts = Dictionary<String,AnyObject>()
var cuisines = Dictionary<String,AnyObject>()


// Create a boolean to track the status of calls being made to the API.
// This is used to prevent multiple simultaneous requests, 
// which could result in data being loaded out of order.
var restaurantsLoading: Bool = false



// The offset to use when requesting the next batch of restaurant records from the API.
var restaurantsNextOffset: String = ""


// A dictionary of fields for the restaurant that was selected by clicking on a table cell.
var selectedRestaurant: Dictionary = Dictionary<String,AnyObject>()


class ViewControllerList: UITableViewController {

    // Outlet for the table object.    
    @IBOutlet var restaurantsTable: UITableView!
    
    // Called when the view loads.
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Load the initial batch of restaurant data from the API.
        self.getRestaurantsFromAPI("")

        // Add a target for the refresh control.
        self.refreshControl?.addTarget(self, action: "handleRefresh:", forControlEvents: UIControlEvents.ValueChanged)

    }
    
    
    // Handles a request to refresh the view.
    func handleRefresh(refreshControl: UIRefreshControl) {
                
        // Purge the restaurants array.
        restaurants.removeAll()
        
        // Reload the restaurant data from the API.
        self.getRestaurantsFromAPI("")
        
        // End the "pull to refresh" process.
        refreshControl.endRefreshing()
        
    }
    
    
     // Returns the number of rows in a specified section of the table.
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // Return the number of items in the restaurants array.
        return restaurants.count
        
    }
    
    
    // Returns a cell for a table row.
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // If we're nearing the end of the table, and if there is additional data available from the API...
        if  ( indexPath.row >= restaurants.count - 3 ) && ( restaurantsNextOffset != "" ) {
            // Let's do this...
            self.getRestaurantsFromAPI(restaurantsNextOffset)
        }
        
        // Create the cell.
        let restaurantCell = UITableViewCell ( style: UITableViewCellStyle.Subtitle, reuseIdentifier: "cell" )
        
        // If the row to be displayed is out of range...
        if indexPath.row > restaurants.count {
            // Return the empty cell.
            return restaurantCell
        }
        
        // Get the element from the "restaurants" array.
        var record: Dictionary = restaurants[ indexPath.row ]
        
        // Get the fields from the dictionary.
        let fields: NSDictionary = record["fields"] as! NSDictionary
        
        // Get the "name" from the fields dictionary.
        let name: String = fields["Name"] as! String
        
        // Get the cost.
        var cost: String
        if let _: AnyObject = fields["Cost"] {
            cost = fields["Cost"] as! String
        } else {
            cost = "?"
        }
        
        // Get the rating value.
        var rating: String
        if let _: AnyObject = fields["My Rating"] {
            rating = fields["My Rating"] as! String
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
        
        // Set the cell's text label.
        restaurantCell.textLabel?.text = name
        
        // Set the detail text label.
        restaurantCell.detailTextLabel?.text = rating + " • " + cost
        
        // Add the disclosure indicator.
        restaurantCell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        
        // Return the cell.
        return restaurantCell
        
    }
    
    
    // Called when a table row is clicked.
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // Get the selected restaurant from the array.
        var record: Dictionary = restaurants[ self.restaurantsTable.indexPathForSelectedRow!.row ]
        
        // Grab the fields and store them in selectedRestaurant.
        selectedRestaurant = record["fields"] as! Dictionary
        
        // Perform the listToTabs segue.
        self.performSegueWithIdentifier("listToTabs" , sender: indexPath)
        
    }
    
    
    // Called when returning from detail view to list view.
    @IBAction func unwindToViewController (sender: UIStoryboardSegue) {
        
    }
    

    // Loads a batch of restaurant records via the API, using a given offset.
    func getRestaurantsFromAPI(offset: String) {
        
        // Specify params for the API call.
        let tableName = "Restaurants"
        let limit = "100"
        let viewName = "Main View"
        let sortField = "Name"
        let sortDirection = "asc"
        
        
        // If we are already loading data...
        if restaurantsLoading {
            return
        }
        
        
        // Set "restaurantsLoading" flag to prevent multiple simultaneous requests.
        restaurantsLoading = true
        
        
        // Prepare the URL request.
        var url = "https://api.airtable.com/v0/\(airtableAppID)/\(tableName)?limit=\(limit)"
        if viewName != "" {
            url = url + "&view=" + viewName.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
        }
        if sortField != "" {
            url = url + "&sortField=" + sortField.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
            url = url + "&sortDirection=" + sortDirection
        }
        if offset != "" {
            url = url + "&offset=" + offset
        }
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
                
                // Try to get the data in JSON format.
                let jsonData = try NSJSONSerialization.JSONObjectWithData(responseData, options:[]) as! NSDictionary
                
                // Get the records from the JSON data.
                if let recordsReceived = (jsonData["records"] as? [Dictionary<String,AnyObject>]) {
                    
                    // Append the records to the array.
                    restaurants = restaurants + recordsReceived
                    
                    // Reload the table.
                    dispatch_async(dispatch_get_main_queue(), {
                        self.restaurantsTable.reloadData()
                    })
                    
                } else {
                    print("Error: No records received.")
                }
                
                // Get the next offset from the JSON data.
                if let offsetReceived = (jsonData["offset"] as? String) {
                    restaurantsNextOffset = offsetReceived
                } else {
                    restaurantsNextOffset = ""
                }
                
            } catch {
                print("Error: Unable to convert data to JSON.")
                return
            }
            
            // Flip the restaurantsLoading flag.
            restaurantsLoading = false
            
            
        })
        
        // Start / resume the data task.
        task.resume()
        
    }
  

}
