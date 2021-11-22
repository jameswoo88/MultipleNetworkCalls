//
//  SlowTableVC.swift
//  MultipleNetworkCalls
//
//  Created by James Chun on 11/11/21.
//

import UIKit
import CoreImage

class SlowTableVC: UITableViewController {

    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return URLList.urlList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SlowCell", for: indexPath) as? CustomTableViewCell else { return UITableViewCell() }
        
        var image: UIImage?
        
        guard let imageURL = URL(string: URLList.urlList[indexPath.row]),
              let imageData = try? Data(contentsOf: imageURL) else { return cell }
        
        let unfilteredImage = UIImage(data: imageData)
        image = self.applySepiaFilter(unfilteredImage!)
        
        let title = URLList.placeList[indexPath.row]
        
        cell.titleLabel.text = title
        if image != nil {
            cell.classicImageView.image = image
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return view.frame.height / 3
    }
    
    // MARK: - image processing
    func applySepiaFilter(_ image:UIImage) -> UIImage? {
        let inputImage = CIImage(data:image.pngData()!)
        let context = CIContext(options:nil)
        let filter = CIFilter(name:"CISepiaTone")
        filter?.setValue(inputImage, forKey: kCIInputImageKey)
        filter!.setValue(0.8, forKey: "inputIntensity")
        
        guard let outputImage = filter!.outputImage,
              let outImage = context.createCGImage(outputImage, from: outputImage.extent) else {
                  return nil
              }
        return UIImage(cgImage: outImage)
    }
    
}//End of class
