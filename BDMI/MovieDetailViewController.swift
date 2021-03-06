//
//  MovieDetailViewController.swift
//  BDMI
//
//  Created by Yu Qi Hao on 5/29/16.
//  Copyright © 2016 Yu Qi Hao. All rights reserved.
//

import UIKit
import Kingfisher
import TransitionTreasury
import TransitionAnimation
import CoreData

class MovieDetailViewController: BDMIViewController {
    
    //MARK: Properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var headerView: MovieDetailHeaderSectionView!
    
    let stack = Utilities.appDelegate.stack
    var movieID : Int?
    var moviePosterPath: String?
    var movie : Movie?
    var blurEffectView : UIVisualEffectView?
    
    var isFavorite = false
    var isWatchlist = false
    
    
    //MARK: Life Circle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackgroundView()
        
        if let _ = movie {} else {
            if let id = movieID {
                if case let movie as Movie = stack.objectSavedInCoreData(id, entity: CoreDataEntityNames.Movie) {
                    self.movie = movie
                } else {
                    if !Reachability.isConnectedToNetwork(){
                        return
                    }
                    getMovieDetailsById(id)
                }
            }
        }
        headerView.configView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if Utilities.isLoggedIn() && Reachability.isConnectedToNetwork() {
            checkIfLiked()
            checkIfWatched()
        }

    }
}

//MARK: Networking Methods
extension MovieDetailViewController {
    
    private func checkIfLiked() {
        
        Utilities.appDelegate.setNewworkActivityIndicatorVisible(true)
        TMDBClient.sharedInstance.getFavoriteMovies { (movies, error) in
            
            performUIUpdatesOnMain({ 
                Utilities.appDelegate.setNewworkActivityIndicatorVisible(false)
                if let movies = movies {
                    for movie in movies {
                        if movie.id == self.movieID {
                            self.isFavorite = true
                        }
                    }
                    self.headerView.likeBtn.selected = self.isFavorite
                    
                } else {
                    print(error)
                    showAlertViewWith("Oops", error: (error?.localizedDescription)!, type: .AlertViewWithOneButton, firstButtonTitle: "OK", firstButtonHandler: nil, secondButtonTitle: nil, secondButtonHandler: nil)
                }
            })
        }
    }
    
    private func checkIfWatched() {
        Utilities.appDelegate.setNewworkActivityIndicatorVisible(true)
        TMDBClient.sharedInstance.getWatchlistMovies { (movies, error) in
            performUIUpdatesOnMain({
                Utilities.appDelegate.setNewworkActivityIndicatorVisible(false)
                if let movies = movies {
                    for movie in movies {
                        if movie.id == self.movieID {
                            self.isWatchlist = true
                        }
                    }
                    self.headerView.watchBtn.selected = self.isWatchlist
                } else {
                    print(error)
                    showAlertViewWith("Oops", error: (error?.localizedDescription)!, type: .AlertViewWithOneButton, firstButtonTitle: "OK", firstButtonHandler: nil, secondButtonTitle: nil, secondButtonHandler: nil)
                }
            })
        }
    }
    
    func getMovieDetailsById(id: Int) {
        Utilities.appDelegate.setNewworkActivityIndicatorVisible(true)
        TMDBClient.sharedInstance.getMovieDetailBy(id) { (result, error) in
            performUIUpdatesOnMain({
                Utilities.appDelegate.setNewworkActivityIndicatorVisible(false)
                guard error == nil else {
                    showAlertViewWith("Oops", error: error!.localizedDescription, type: .AlertViewWithOneButton, firstButtonTitle: "OK", firstButtonHandler: nil, secondButtonTitle: nil, secondButtonHandler: nil)
                    return
                }
                self.movie = self.stack.createNewMovie(result!)
                self.tableView.reloadData()
            })
        }
    }
}


//MARK: UITableView Delegate && DataSource Method
extension MovieDetailViewController : UITableViewDelegate, UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let _ = movie {
            return 1
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: //Title Cell
            let cell = tableView.dequeueReusableCellWithIdentifier("TitleSectionCell") as! MovieDetailCellForTitleSection
            cell.configCell()
            cell.titleLbl.text = movie?.title
            cell.ratingLbl.text = "Rating: \(movie!.voteAverage!)"
            cell.runtimeLbl.text = "Runtime: \(movie!.runtime!)mins"
            cell.releaseDateLbl.text = "Year: \(movie!.releaseDate!)"
            return cell
        case 1: //Overview Cell
            let cell = tableView.dequeueReusableCellWithIdentifier("OverviewSectionCell") as! MovieDetailCellForOverview
            cell.configCell()
            cell.overviewLbl.text = movie?.overview!
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 130
        case 1:
            if let overview = movie?.overview {
                return overview.heightWithConstrainedWidth(Utilities.screenSize.width - 40, font: UIFont.systemFontOfSize(16)) + 20
            } else {
                return 0
            }
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clearColor()
        return headerView
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return view.frame.height - 130
        }
        return 0
    }
    
    
    
    func  scrollViewDidScroll(scrollView: UIScrollView) {
        performUIUpdatesOnMain { 
            let offsetY = scrollView.contentOffset.y
            let cells = self.tableView.visibleCells
            self.blurEffectView?.alpha = min(0.8,offsetY / 200)
            if offsetY > 40 && !self.headerView.isHiding {
                self.hideHeaderView()
                for cell in cells {
                    cell.backgroundColor = UIColor.clearColor()
                }
            } else if offsetY <= 40 && self.headerView.isHiding {
                self.showHeaderView()
                for cell in cells {
                    cell.backgroundColor = Utilities.backgroundColor
                }
            }
        }
        
    }
    
    @IBAction func backButtonClicked(sender: AnyObject) {
        modalDelegate?.modalViewControllerDismiss(callbackData: nil)
    }
    
    @IBAction func watchButtonClicked(sender: AnyObject) {
        if !Reachability.isConnectedToNetwork(){
            showAlertViewWith("Oops", error: "Internet Disconnected", type: .AlertViewWithOneButton, firstButtonTitle: "OK", firstButtonHandler: nil, secondButtonTitle: nil, secondButtonHandler: nil)
            return
        }
        if Utilities.isLoggedIn() {
            headerView.watchBtn.enabled = false
            let shouldWatchlist = !isWatchlist
            
            Utilities.appDelegate.setNewworkActivityIndicatorVisible(true)
            TMDBClient.sharedInstance.postToWatchlist(movieID!, watchlist: shouldWatchlist) { (statusCode, error) in
                performUIUpdatesOnMain {
                    Utilities.appDelegate.setNewworkActivityIndicatorVisible(false)
                    self.headerView.watchBtn.enabled = true
                    if let error = error {
                        showAlertViewWith("Oops", error: "Could Not Add to Watched List. Error: \(error.localizedDescription)", type: .AlertViewWithOneButton, firstButtonTitle: "OK", firstButtonHandler: nil, secondButtonTitle: nil, secondButtonHandler: nil)
                    } else {
                        if statusCode == 1 || statusCode == 12 || statusCode == 13 {
                            self.isWatchlist = shouldWatchlist
                            self.headerView.watchBtn.selected = self.isWatchlist
                            
                        } else {
                            showAlertViewWith("Oops", error: "Could Not Add to Watched List.", type: .AlertViewWithOneButton, firstButtonTitle: "OK", firstButtonHandler: nil, secondButtonTitle: nil, secondButtonHandler: nil)
                        }
                    }
                }
            }
        } else {
            invokeLoginVCFrom(self, toViewController: nil)
        }
        
    }
    
    @IBAction func likeButtonClicked(sender: AnyObject) {
        if !Reachability.isConnectedToNetwork(){
            showAlertViewWith("Oops", error: "Internet Disconnected", type: .AlertViewWithOneButton, firstButtonTitle: "OK", firstButtonHandler: nil, secondButtonTitle: nil, secondButtonHandler: nil)
            return
        }
        if Utilities.isLoggedIn() {
            headerView.likeBtn.enabled = false
            let shouldFavorite = !isFavorite
            
            Utilities.appDelegate.setNewworkActivityIndicatorVisible(true)
            TMDBClient.sharedInstance.postToFavorites(movieID!, favorite: shouldFavorite) { (statusCode, error) in
                performUIUpdatesOnMain({
                    Utilities.appDelegate.setNewworkActivityIndicatorVisible(false)
                    self.headerView.likeBtn.enabled = true
                    if let error = error {
                        showAlertViewWith("Oops", error: "Could Not Like It. Error: \(error.localizedDescription)", type: .AlertViewWithOneButton, firstButtonTitle: "OK", firstButtonHandler: nil, secondButtonTitle: nil, secondButtonHandler: nil)
                    } else {
                        if statusCode == 1 || statusCode == 12 || statusCode == 13 {
                            self.isFavorite = shouldFavorite
                            self.headerView.likeBtn.selected = self.isFavorite
                        } else {
                            showAlertViewWith("Oops", error: "Could Not Like It.", type: .AlertViewWithOneButton, firstButtonTitle: "OK", firstButtonHandler: nil, secondButtonTitle: nil, secondButtonHandler: nil)
                        }
                    }
                })
            }
        } else {
           invokeLoginVCFrom(self, toViewController: nil)
        }
    }
}

//MARK: UI Related Methods
extension MovieDetailViewController {
    
    private func setupBackgroundView() {
        
        backgroundImageView.kf_setImageWithURL(TMDBClient.sharedInstance.createUrlForImages(TMDBClient.PosterSizes.DetailPoster, filePath: moviePosterPath!), placeholderImage: nil, optionsInfo:[.Transition(ImageTransition.Fade(1.0))], progressBlock: nil) { (image, error, cacheType, imageURL) in
                performUIUpdatesOnMain({
                    self.addBlurViewTo(self.backgroundImageView)
                })
        }
    }
    
    private func addBlurViewTo(view:UIView) {
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Dark)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        if let blurEffectView = blurEffectView {
            blurEffectView.frame = view.bounds
            blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            blurEffectView.alpha = 0
            view.addSubview(blurEffectView)
        }
    }
    
    private func hideHeaderView() {
        headerView.isHiding = true
        var frame = headerView.frame
        frame.origin.y -= frame.size.height
        UIView.animateWithDuration(0.2, animations: { 
            self.headerView.frame = frame
            self.headerView.alpha = 0
            }) { (finished) in
                if finished {
                    
                }
        }
    }
    
    private func showHeaderView() {
        headerView.isHiding = false
        var frame = headerView.frame
        frame.origin.y += frame.size.height
        
        UIView.animateWithDuration(0.2) {
            self.headerView.frame = frame
            self.headerView.alpha = 1
        }
    }
}