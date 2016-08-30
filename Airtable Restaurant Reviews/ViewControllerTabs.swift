//
//  ViewControllerDetails.swift
//  Airtable Restaurant Reviews
//
//  Created by Timothy Dietrich on 9/30/15.
//
//  Serves as the view controller for the tab bar controller.
//  This handles all of the views that show more detailed info
//  for a restaurant that was selected by clicking on a row in 
//  the table. Note that tabs are removed if they are not 
//  applicable. For example, the "Menu" tab is removed if
//  no scanned menu document is available for the restaurant.
// 

import UIKit

class ViewControllerTabs: UITabBarController {
    
    override func viewDidLoad() {
        
        super.viewDidLoad()        
        
        // Set the title to the restaurant name.
        self.title = selectedRestaurant["Name"] as? String
                
        // Remove any tabs that aren't applicable for this restaurant.
        // Note: This needs to be done from right to left, to avoid an "Array index out of range" error.
        
        var tabBarViewControllers = self.viewControllers
        
        if selectedRestaurant["Menu"] == nil {
            tabBarViewControllers?.removeAtIndex(2)
        }
        
        if selectedRestaurant["Pictures"] == nil {
            tabBarViewControllers?.removeAtIndex(1)
        }
        
        self.setViewControllers(tabBarViewControllers, animated: true)

        
    }
        
}
