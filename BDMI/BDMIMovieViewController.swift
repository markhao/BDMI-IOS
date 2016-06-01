//
//  BDMIMovieViewController.swift
//  BDMI
//
//  Created by Yu Qi Hao on 5/29/16.
//  Copyright © 2016 Yu Qi Hao. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import Kingfisher
import CoreData
import TransitionTreasury
import TransitionAnimation

class BDMIMovieViewController: UIViewController {
    
    
    //MARK: Propertites
    @IBOutlet weak var tableView: UITableView!
    let stack = Utilities.appDelegate.stack
    var scrollView: UIScrollView?
    var nowShowingMovies : [TMDBMovie]?
    var upcomingMovies : [TMDBMovie]?
    var popularMovies : [TMDBMovie]?
    var topRatedMovies : [TMDBMovie]?
    var storedOffsets = [Int: CGFloat]()
    var scrollViewsetted = false
    
    var tr_presentTransition: TRViewControllerTransitionDelegate?
    
    
    //MARK: Life Circle
    override func viewDidLoad() {
        super.viewDidLoad()
        loadData()
        scrollView = UIScrollView(frame: CGRectMake(0,0,Utilities.screenSize.width,200))
        scrollView?.pagingEnabled = true
        tableView.tableHeaderView = scrollView!
        addRefreshControl()
    }
}

//MARK: UI related and navigation methods
extension BDMIMovieViewController : UIGestureRecognizerDelegate {
    
    private func addRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), forControlEvents: .ValueChanged)
        tableView.addSubview(refreshControl)
    }
    
    func refresh(refreshControl: UIRefreshControl) {
        loadData()
        refreshControl.endRefreshing()
    }
    
    func setupScrollView() {
        
        let width = scrollView!.frame.width
        let height = scrollView!.frame.height
        var movies = [TMDBMovie]()
        var i : CGFloat = 0
        while i < 4 {
            let movie = popularMovies![getRandomNumber((popularMovies?.count)!)]
            if let backdropPath = movie.backdropPath where !movies.contains(movie) {
                movies.append(movie)
                let imageView = UIImageView(frame: CGRectMake(i * width, 0, width, height))
                imageView.tag = movie.id
                imageView.restorationIdentifier = movie.posterPath
                imageView.contentMode = .ScaleAspectFill
                imageView.userInteractionEnabled = true
                let label = UILabel(frame: CGRectMake(20, height - 50, width - 40, 40))
                configLabel(label)
                changeTextForLabel(label, text: movie.title)
                imageView.addSubview(label)
                scrollView!.addSubview(imageView)
                imageView.kf_setImageWithURL(TMDBClient.sharedInstance.createUrlForImages(TMDBClient.BackdropSizes.DetailBackdrop, filePath: backdropPath), placeholderImage: nil, optionsInfo: nil, progressBlock: nil, completionHandler: nil)
                let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
                tap.delegate = self
                imageView.addGestureRecognizer(tap)
                
                i += 1
            }
        }
        scrollView!.contentSize = CGSize(width: 4 * width, height: height)
        scrollViewsetted = true
        NSTimer.scheduledTimerWithTimeInterval(8, target: self, selector: #selector(moveToNextPage), userInfo: nil, repeats: true)
    }
    
    func imageTapped(sender: UITapGestureRecognizer) {
        let movieDetailVC = self.storyboard?.instantiateViewControllerWithIdentifier("MovieDetailViewController") as! MovieDetailViewController
        let movieId = sender.view?.tag
        let posterPath = sender.view?.restorationIdentifier
        movieDetailVC.movieID = movieId
        movieDetailVC.moviePosterPath = posterPath
        movieDetailVC.modalDelegate = self
        tr_presentViewController(movieDetailVC, method: TRPresentTransitionMethod.Fade)

    }
    
    func moveToNextPage (){
        
        let pageWidth:CGFloat = CGRectGetWidth(self.scrollView!.frame)
        let maxWidth:CGFloat = pageWidth * 4
        let contentOffset:CGFloat = self.scrollView!.contentOffset.x
        
        var slideToX = contentOffset + pageWidth
        
        if  contentOffset + pageWidth == maxWidth{
            slideToX = 0
        }
        self.scrollView!.scrollRectToVisible(CGRectMake(slideToX, 0, pageWidth, CGRectGetHeight(self.scrollView!.frame)), animated: true)
    }
    
    private func configLabel(label: UILabel) {
        label.textAlignment = .Right
        label.font = UIFont.boldSystemFontOfSize(19)
        label.textColor = UIColor.whiteColor()
        label.backgroundColor = Utilities.backgroundColor
    }
}


//MARK: UITableView Delegate and DataSource
extension BDMIMovieViewController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MovieTableViewCell") as! MovieTableViewCell
        switch indexPath.row {
            //NOW SHOWING
        case 0:
            changeTextForLabel(cell.sectionLabel, text: "Now Showing")
            break
            
            //COMING SOON
        case 1:
            changeTextForLabel(cell.sectionLabel, text: "Coming Soon")
            break
            
            //POPULAR
        case 2:
            changeTextForLabel(cell.sectionLabel, text: "Popular")
            break
            //TOP RATED
        case 3:
            changeTextForLabel(cell.sectionLabel, text: "Top Rated")
            break
        default:
            break
        }
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let tableViewCell = cell as? MovieTableViewCell else {
            return
        }
        
        tableViewCell.setCollectionViewDataSourceDelegate(self, forRow: indexPath.row)
        tableViewCell.collectionViewOffset = storedOffsets[indexPath.row] ?? 0
    }
    
    func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let tableViewCell = cell as? MovieTableViewCell else {
            return
        }
        storedOffsets[indexPath.row] = tableViewCell.collectionViewOffset
    }
    
}


//MARK: UICollectionView Delegate and DataSource
extension BDMIMovieViewController : UICollectionViewDelegate, UICollectionViewDataSource, ModalTransitionDelegate {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView.tag {
            //NOW SHOWING
        case 0:
            if let movies = nowShowingMovies {
               return movies.count
            }
            break
            
            //COMGING SOON
        case 1:
            if let movies = upcomingMovies {
                return movies.count
            }
            break
            
            //POPULAR
        case 2:
            if let movies = popularMovies {
                return movies.count
            }
            break
            //TOP RATED
        case 3:
            if let movies = topRatedMovies {
                return movies.count
            }
        default:
            break
        }
        return 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("MovieCollectionViewCell", forIndexPath: indexPath) as! MovieCollectionViewCell
        var movie : TMDBMovie?
        switch collectionView.tag {
        case 0: /* NOW SHOWING */
            if let movies = nowShowingMovies {
                movie = movies[indexPath.row]
            }
            break
        case 1: /* COMGING SOON */
            if let movies = upcomingMovies {
                movie = movies[indexPath.row]
            }
            break
        case 2: /* POPULAR */
            if let movies = popularMovies {
                movie = movies[indexPath.row]
            }
            break
        case 3: /* TOP RATED */
            if let movies = topRatedMovies {
                movie = movies[indexPath.row]
            }
            break
        default: break
        }
        
        NVActivityIndicatorView.showHUDAddedTo(cell)
        
        if let imagePath = movie?.posterPath {
            cell.imageView.kf_setImageWithURL(TMDBClient.sharedInstance.createUrlForImages(TMDBClient.PosterSizes.RowPoster, filePath: imagePath),
                                              placeholderImage: nil,
                                              optionsInfo: [.Transition(ImageTransition.Fade(0.5))], progressBlock: nil, completionHandler: { image, error, cacheType, imageURL in
                                                performUIUpdatesOnMain({
                                                    NVActivityIndicatorView.hideHUDForView(cell)
                                                    cell.imageView.alpha = 1.0
                                                })
                                                
            })
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let movieDetailVC = self.storyboard?.instantiateViewControllerWithIdentifier("MovieDetailViewController") as! MovieDetailViewController
        var movie : TMDBMovie?
        switch collectionView.tag {
        case 0: /* NOW SHOWING */
            if let movies = nowShowingMovies {
                movie = movies[indexPath.row]
            }
            break
        case 1: /* COMGING SOON */
            if let movies = upcomingMovies {
                movie = movies[indexPath.row]
            }
            break
        case 2: /* POPULAR */
            if let movies = popularMovies {
                movie = movies[indexPath.row]
            }
            break
        case 3: /* TOP RATED */
            if let movies = topRatedMovies {
                movie = movies[indexPath.row]
            }
            break
        default: break
        }
        movieDetailVC.movieID = movie?.id
        movieDetailVC.moviePosterPath = movie?.posterPath
        movieDetailVC.modalDelegate = self
        tr_presentViewController(movieDetailVC, method: TRPresentTransitionMethod.Fade)

    }
}

//MARK: Networking Methods
extension BDMIMovieViewController {
    private func loadData() {
        getNowShowingMovies()
        getPopularMovies()
        geUpcomingMovies()
        getTopRatedMovies()
    }
    
    private func getNowShowingMovies() {
        TMDBClient.sharedInstance.getMoviesBy(TMDBClient.Methods.NowPlaying) { (result, error) in
            performUIUpdatesOnMain({ 
                guard (error == nil) else {
                    showAlertViewWith("Oops", error: "Failed to Get New Data. Please Try Again Later.", type: .AlertViewWithOneButton, firstButtonTitle: "OK", firstButtonHandler: nil, secondButtonTitle: nil, secondButtonHandler: nil)
                    return
                }
                self.nowShowingMovies = result!
                delay(15, closure: { 
                    self.perfetchMovieDetails(result!)
                })
                self.tableView.reloadData()
                print("Load Now Showing Movies Successfully")
            })
        }
    }
    
    private func geUpcomingMovies() {
        TMDBClient.sharedInstance.getMoviesBy(TMDBClient.Methods.UpComing) { (result, error) in
            performUIUpdatesOnMain({
                guard (error == nil) else {
                    showAlertViewWith("Oops", error: "Failed to Get New Data. Please Try Again Later.", type: .AlertViewWithOneButton, firstButtonTitle: "OK", firstButtonHandler: nil, secondButtonTitle: nil, secondButtonHandler: nil)
                    return
                }
                self.upcomingMovies = result
                self.tableView.reloadData()
                delay(30, closure: {
                    self.perfetchMovieDetails(result!)
                })
                print("Load Upcoming Movies Successfully")
            })
        }
    }
    
    private func getPopularMovies() {
        TMDBClient.sharedInstance.getMoviesBy(TMDBClient.Methods.Popular) { (result, error) in
            performUIUpdatesOnMain({
                guard (error == nil) else {
                    showAlertViewWith("Oops", error: "Failed to Get New Data. Please Try Again Later.", type: .AlertViewWithOneButton, firstButtonTitle: "OK", firstButtonHandler: nil, secondButtonTitle: nil, secondButtonHandler: nil)
                    return
                }
                self.popularMovies = result
                if !self.scrollViewsetted {self.setupScrollView()}
                delay(45, closure: {
                    self.perfetchMovieDetails(result!)
                })
                self.tableView.reloadData()
                print("Load Popular Movies Successfully")
            })
        }
    }
    
    private func getTopRatedMovies() {
        TMDBClient.sharedInstance.getMoviesBy(TMDBClient.Methods.TopRated) { (result, error) in
            performUIUpdatesOnMain({
                guard (error == nil) else {
                    showAlertViewWith("Oops", error: "Failed to Get New Data. Please Try Again Later.", type: .AlertViewWithOneButton, firstButtonTitle: "OK", firstButtonHandler: nil, secondButtonTitle: nil, secondButtonHandler: nil)
                    return
                }
                self.topRatedMovies = result
                delay(60, closure: {
                    self.perfetchMovieDetails(result!)
                })
                self.tableView.reloadData()
                print("Load Top Rated Movies Successfully")
            })
        }
    }
    
    private func perfetchMovieDetails(movies: [TMDBMovie]) {
        var collectionIDs = [Int]()
        for movie in movies {
            
            //Check if the movie is already saved.
            if let _ = stack.objectSavedInCoreData(movie.id, entity: CoreDataEntityNames.Movie) as? Movie {} else {
                
                //Movie's not saved. Get movie details from API
                TMDBClient.sharedInstance.getMovieDetailBy(movie.id, completionHandlerForGetDetail: { (movieResult, error) in
                    performUIUpdatesOnMain({ 
                        if let error = error {
                            print("Prefetch Failed. \(error.domain)")
                        } else {
                            
                            //Create new movie and save to coredata
                            let newMovie = self.stack.createNewMovie(movieResult!)
                            
                            //Check if the movie belongs to any collection
                            if let collectionData = movieResult!.belongsToCollection {
                                let collectionID = collectionData["id"] as! Int
                                
                                //Check if the collection is saved
                                if let savedCollection = self.stack.objectSavedInCoreData(collectionID, entity: CoreDataEntityNames.Collection) as? Collection {
                                    
                                    //Add the movie to its collection
                                    savedCollection.addMoviesObject(newMovie)
                                } else {
                                    if !collectionIDs.contains(collectionID) {
                                        collectionIDs.append(collectionID)
                                        //Collection not saved. Get collection data from API
                                        TMDBClient.sharedInstance.getCollectionlBy(collectionID, completionHandlerForGetCollection: { (collectionResult, error) in
                                            performUIUpdatesOnMain({
                                                guard (error == nil) else {
                                                    print("Error while getting collection. Error: \(error?.localizedDescription)")
                                                    return
                                                }
                                                
                                                //Create new collection and add the movie to it.
                                                let newCollection = self.stack.createNewCollection(collectionResult!)
                                                newCollection.addMoviesObject(newMovie)
                                                
                                                //Get the collection's movie data, loop back to perfetch.
                                                if let parts = collectionResult!.parts {
                                                    let collectionMovies = TMDBMovie.moviesFromResults(parts)
                                                    self.perfetchMovieDetails(collectionMovies)
                                                }
                                            })
                                        })
                                    }
                                }
                            }
                        }
                    })
                })
            }
        }
        //Save context
        do {
            try Utilities.appDelegate.stack.context.save()
        } catch {
            let error = error as NSError
            print("Save failed. Error: \(error.localizedDescription)")
        }
    }
}


//MARK: Helper Methods
extension BDMIMovieViewController {
    private func changeTextForLabel(label: UILabel, text: String) {
        label.text = text
        label.sizeToFit()
    }
    
    private func getRandomNumber(max: Int) -> Int {
        return Int(arc4random_uniform(UInt32(max)))
    }
}
