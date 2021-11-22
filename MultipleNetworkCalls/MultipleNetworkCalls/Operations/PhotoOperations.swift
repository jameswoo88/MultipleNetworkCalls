//
//  PhotoOperations.swift
//  MultipleNetworkCalls
//
//  Created by James Chun on 11/17/21.
//

import UIKit

// This enum contains all the possible states a photo record can be in
enum PhotoRecordState {
    case new, downloaded, filtered, failed
}//End of extension

//This class represents each photo displayed in the app, together with its current state, which defaults to .new. The image defaults to a placeholder.
class PhotoRecord {
    let name: String
    let url: URL
    var state = PhotoRecordState.new
    var image = UIImage(named: "Placeholder")
    
    init(name: String, url: URL) {
        self.name = name
        self.url = url
    }
    
}//End of class


//track the status of each operation
//All of the values are created lazily — they aren’t initialized until they’re first accessed. This improves the performance of your app.
class PendingOperations {
    lazy var downloadsInProgress: [IndexPath: Operation] = [:]
    lazy var downloadQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Download queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    lazy var filterationsInProgress: [IndexPath: Operation] = [:]
    lazy var filterationQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "Image Filteration queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
}//End of class

class ImageDownloader: Operation {
    //Add a constant reference to the PhotoRecord object related to the operation.
    let photoRecord: PhotoRecord
    
    //Create a designated initializer allowing the photo record to be passed in.
    init(_ photoRecord: PhotoRecord) {
        self.photoRecord = photoRecord
    }
    
    //main() is the method you override in Operation subclasses to actually perform work.
    override func main() {
        //Check for cancellation before starting. Operations should regularly check if they have been cancelled before attempting long or intensive work.
        if isCancelled {
            return
        }
        
        guard let imageData = try? Data(contentsOf: photoRecord.url) else { return }
        
        if isCancelled {
            return
        }
        
        if !imageData.isEmpty {
            photoRecord.image = UIImage(data: imageData)
            photoRecord.state = .downloaded
        } else {
            photoRecord.state = .failed
            photoRecord.image = UIImage(named: "Failed")
        }
    }
    
}//End of class

class ImageFiltration: Operation {
    let photoRecord: PhotoRecord
    
    init(_ photoRecord: PhotoRecord) {
        self.photoRecord = photoRecord
    }
    
    override func main() {
        if isCancelled {
            return
        }
        
        guard self.photoRecord.state == .downloaded else {
            return
        }
        
        if let image = photoRecord.image,
           let filteredImage = applySepiaFilter(image) {
            photoRecord.image = filteredImage
            photoRecord.state = .filtered
        }
    }//end of func
    
    func applySepiaFilter(_ image: UIImage) -> UIImage? {
        guard let data = image.pngData() else { return nil }
        let inputImage = CIImage(data: data)
        
        if isCancelled {
            return nil
        }
        
        let context = CIContext(options: nil)
        
        guard let filter = CIFilter(name: "CISepiaTone") else { return nil }
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(0.8, forKey: "inputIntensity")
        
        if isCancelled {
            return nil
        }
        
        guard let outputImage = filter.outputImage,
              let outImage = context.createCGImage(outputImage, from: outputImage.extent)
        else {
            return nil
        }
        
        return UIImage(cgImage: outImage)
    }//end of func
    
}//End of class
