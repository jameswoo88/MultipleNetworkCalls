//
//  OperationTableVC.swift
//  MultipleNetworkCalls
//
//  Created by James Chun on 11/11/21.
//

import UIKit

class OperationTableVC: UITableViewController {
    
    //MARK: - Properties
    var photos: [PhotoRecord] = []
    let pendingOperations = PendingOperations()

    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        getPhotoDetails()
        for photo in photos {
            print(photo.name)
        }
    }
    
    //MARK: - Functions
    func startDownload(for photoRecord: PhotoRecord, at indexPath: IndexPath) {
        //1
        guard pendingOperations.downloadsInProgress[indexPath] == nil else { return }
        
        //2
        let downloader = ImageDownloader(photoRecord)
        
        //3
        downloader.completionBlock = {
            if downloader.isCancelled {
                return
            }
            
            DispatchQueue.main.async {
                self.pendingOperations.downloadsInProgress.removeValue(forKey: indexPath)
                self.tableView.reloadRows(at: [indexPath], with: .fade)
            }
        }
        
        //4
        pendingOperations.downloadsInProgress[indexPath] = downloader
        
        //5
        pendingOperations.downloadQueue.addOperation(downloader)
        
    }//end of func
    
    func startFiltration(for photoRecord: PhotoRecord, at indexPath: IndexPath) {
        guard pendingOperations.filterationsInProgress[indexPath] == nil else { return }
        
        let filterer = ImageFiltration(photoRecord)
        
        filterer.completionBlock = {
            if filterer.isCancelled {
                return
            }
            
            DispatchQueue.main.async {
                self.pendingOperations.filterationsInProgress.removeValue(forKey: indexPath)
                self.tableView.reloadRows(at: [indexPath], with: .fade)
            }
        }
        
        pendingOperations.filterationsInProgress[indexPath] = filterer
        pendingOperations.filterationQueue.addOperation(filterer)
    }
    
    func startOperations(for photoRecord: PhotoRecord, at indexPath: IndexPath) {
        switch (photoRecord.state) {
        case .new:
            startDownload(for: photoRecord, at: indexPath)
        case .downloaded:
            startFiltration(for: photoRecord, at: indexPath)
        default:
            NSLog("do nothing")
        }
    }
    
    func getPhotoDetails() {
        let alertController = UIAlertController(title: "Oops!", message: "There was an error fetching photo details.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)
        
        for (name, value) in URLList.urlDictionary {
            let url = URL(string: value)
            if let url = url {
                let photoRecord = PhotoRecord(name: name, url: url)
                self.photos.append(photoRecord)
            }
        }
        
        //JCHUN: DispatchQueue.main.async?
        //self.tableView.reloadData()
        
    }//end of func

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "OperationCell", for: indexPath) as? CustomTableViewCell else { return UITableViewCell() }
        
        //1
        if cell.accessoryView == nil {
            let indicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
            cell.accessoryView = indicator
        }
        let indicator = cell.accessoryView as! UIActivityIndicatorView
        
        //2
        let photoDetails = photos[indexPath.row]
        
        //3
        cell.titleLabel.text = photoDetails.name
        cell.classicImageView.image = photoDetails.image
        
        //4
        switch (photoDetails.state) {
        case .filtered:
            indicator.stopAnimating()
        case .failed:
            indicator.stopAnimating()
            cell.titleLabel.text = "Failed to load"
        case .new, .downloaded:
            indicator.startAnimating()
            if !tableView.isDragging && !tableView.isDecelerating {
                startOperations(for: photoDetails, at: indexPath)
            }
        }
        
        return cell
    }//end of func
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return view.frame.height / 3
    }

}//End of class

extension OperationTableVC {
    //MARK: - Operation Functions
    func suspendAllOperations() {
        pendingOperations.downloadQueue.isSuspended = true
        pendingOperations.filterationQueue.isSuspended = true
    }
    
    func resumeAllOperations() {
        pendingOperations.downloadQueue.isSuspended = false
        pendingOperations.filterationQueue.isSuspended = false
    }
    
    func loadImagesForOnscreenCells() {
        //1
        if let pathsArray = tableView.indexPathsForVisibleRows {
            //2
            var allPendingOperations = Set(pendingOperations.downloadsInProgress.keys)
            allPendingOperations.formUnion(pendingOperations.filterationsInProgress.keys)
            
            //3
            var toBeCancelled = allPendingOperations
            let visiblePaths = Set(pathsArray)
            toBeCancelled.subtract(visiblePaths)
            
            //4
            var toBeStarted = visiblePaths
            toBeStarted.subtract(allPendingOperations)
            
            //5
            for indexPath in toBeCancelled {
                if let pendingDownload = pendingOperations.downloadsInProgress[indexPath] {
                    pendingDownload.cancel()
                }
                pendingOperations.downloadsInProgress.removeValue(forKey: indexPath)
                if let pendingFiltration = pendingOperations.filterationsInProgress[indexPath] {
                    pendingFiltration.cancel()
                }
                pendingOperations.filterationsInProgress.removeValue(forKey: indexPath)
            }
            
            //6
            for indexPath in toBeStarted {
                let recordToProcess = photos[indexPath.row]
                startOperations(for: recordToProcess, at: indexPath)
            }
        }
    }//end of func
    
    //MARK: - UIScrollView Delegate Methods
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        //1
        suspendAllOperations()
    }
    
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        //2
        if !decelerate {
            loadImagesForOnscreenCells()
            resumeAllOperations()
        }
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        //3
        loadImagesForOnscreenCells()
        resumeAllOperations()
    }
    
}//End of extension
