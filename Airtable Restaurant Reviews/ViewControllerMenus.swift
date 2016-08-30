//
//  ViewControllerDetails.swift
//  Airtable Restaurant Reviews
//
//  Created by Timothy Dietrich on 9/30/15.
//
//  Serves as the view controller for the Menus view.
//  Uses a web viewer to display a scanned copy of
//  the restaurant's menu.
//

import UIKit

class ViewControllerMenus: UIViewController {
    
    // Primary web view.
    @IBOutlet weak var webViewPrimary: UIWebView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // If the restaurant has a menu associated with it...
        if let _: AnyObject = selectedRestaurant["Menu"] {
            
            // Init the dynamic HTML var.
            var _: String
            
            // Get the URL to the menu document.
            // Note: We're only displaying the first menu document.
            // It could be a PDF, or an image... So we're displaying it in a web viewer.
            let menus: NSArray = ( selectedRestaurant["Menu"] as! NSArray )
            let menu: NSDictionary = ( menus[0] as! NSDictionary )
            let menuURL: String = menu["url"] as! String
            
            // Load the web viewer.
            webViewPrimary.loadRequest(NSURLRequest(URL: NSURL(string: menuURL)!))
            
        }
        
    }
    
}
