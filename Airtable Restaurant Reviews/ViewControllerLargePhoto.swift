//
//  ViewControllerPhotos.swift
//  Airtable Restaurant Reviews
//
//  Created by Timothy Dietrich on 9/30/15.
//
//  Displays the original / large version of
//  a photo that was selected from the collection view.
//  

import UIKit

var zoomedPhotoIndex: Int = 0

class ViewControllerLargePhoto : UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
                
        // Get the array of pictures.
        let pictures = ( selectedRestaurant["Pictures"] as! NSArray )
        
        // Get the picture for this cell.
        let picture = ( pictures[zoomedPhotoIndex] as! NSDictionary )
        
        // Get the URL.
        let pictureURL = picture["url"] as! String
        
        // Load the image view (asynchronously) via the URL.
        let imageURL = NSURL(string: pictureURL)
        let urlRequest = NSURLRequest(URL: imageURL!)
        NSURLConnection.sendAsynchronousRequest(urlRequest, queue: NSOperationQueue.mainQueue()) {
            response, data, error in
            if error == nil && data != nil {
                
                self.imageView.image = UIImage(data: data!)
                self.imageView.contentMode = UIViewContentMode.ScaleAspectFit
                
            }
        }
        
    }
    
}
