//
//  ViewControllerPhotos.swift
//  Airtable Restaurant Reviews
//
//  Created by Timothy Dietrich on 9/30/15.
//
//  Serves as the view controller for the Photos collection view.
//  If applicable, thumbnails of all photos of a restaurant 
//  are displayed in a collection / grid view. If a user
//  clicks on a photo, then a full size version is displayed.
//

import UIKit

class ViewControllerPhotos : UICollectionViewController {
    
    private let reuseIdentifier = "PhotoCell"
    
    // We're presenting all photos in a single section.
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        // If there are pictures of the restaurant...
        if let _: AnyObject = selectedRestaurant["Pictures"] {
            
            // Get the array of pictures.
            let pictures = ( selectedRestaurant["Pictures"] as! NSArray )
            
            // Return the number of pictures in the array.
            return pictures.count
            
            
        } else {
            return 0
        }

    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! PhotoCell

        
        // Get the array of pictures.
        let pictures = ( selectedRestaurant["Pictures"] as! NSArray )
        
        // Get the picture for this cell.
        let picture = ( pictures[indexPath.row] as! NSDictionary )
        
        // Get the thumbnails.
        let thumbnails = ( picture["thumbnails"] as! NSDictionary )
        
        // Get the large thumbnail.
        let large_thumbnail = ( thumbnails["large"] as! NSDictionary )
        
        // Get the URL.
        let pictureURL = large_thumbnail["url"] as! String                
        
        // Load the image view (asynchronously) via the URL.
        let imageURL = NSURL(string: pictureURL)
        let urlRequest = NSURLRequest(URL: imageURL!)
        NSURLConnection.sendAsynchronousRequest(urlRequest, queue: NSOperationQueue.mainQueue()) {
            response, data, error in
            if error == nil && data != nil {
                cell.imageView.image = UIImage(data: data!)
                cell.imageView.contentMode = UIViewContentMode.ScaleAspectFit                
                cell.imageView.layer.borderColor = UIColor.lightGrayColor().CGColor
                cell.imageView.layer.borderWidth = 1.5
                cell.imageView.layer.cornerRadius = 5.0
                cell.imageView.clipsToBounds = true
                
            }
        }
        
        return cell
        
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        zoomedPhotoIndex = indexPath.row
        
    }

    
    
}
