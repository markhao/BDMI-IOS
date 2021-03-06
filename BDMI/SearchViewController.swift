//
//  SearchViewController.swift
//  BDMI
//
//  Created by Yu Qi Hao on 6/1/16.
//  Copyright © 2016 Yu Qi Hao. All rights reserved.
//

import UIKit
import TransitionTreasury
import TransitionAnimation

class SearchViewController: BDMIViewController {
    
    //MARK: Properties
    @IBOutlet weak var movieSearchBar: UISearchBar!
    @IBOutlet weak var movieTableView: UITableView!
    
    var movies = [TMDBMovie]()
    var searchTask: NSURLSessionDataTask?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        placeHolderLabel = createPlaceHolderLabel("No Results")
        if movieSearchBar.text == "" {
            movieTableView.hidden = true
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        movieSearchBar.userInteractionEnabled = Reachability.isConnectedToNetwork()
        if !Reachability.isConnectedToNetwork() {
            changeTextForLabel(placeHolderLabel!, text: "Interest Disconnected")
        } else {
            changeTextForLabel(placeHolderLabel!, text: "No Results")
        }
    }
    
    
    
    //MARK: IBActions
    @IBAction func handleTap(sender: AnyObject) {
        movieSearchBar.resignFirstResponder()
    }
}


// MARK: UIGestureRecognizerDelegate

extension SearchViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return movieSearchBar.isFirstResponder()
    }
}

extension SearchViewController: UISearchBarDelegate {
    
    // each time the search text changes we want to cancel any current download and start a new one
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        
        // cancel the last task
        if let task = searchTask {
            task.cancel()
        }
        
        if searchText == "" {
            movies = [TMDBMovie]()
            movieTableView?.reloadData()
            movieTableView.hidden = true
            return
        }
        
        // new search
        
        if Reachability.isConnectedToNetwork() {
            Utilities.appDelegate.setNewworkActivityIndicatorVisible(true)
            searchTask = TMDBClient.sharedInstance.getMoviesForSearchString(searchText) { (movies, error) in
                performUIUpdatesOnMain({
                    Utilities.appDelegate.setNewworkActivityIndicatorVisible(false)
                    self.searchTask = nil
                    if let movies = movies {
                        self.movies = movies
                        self.movieTableView!.reloadData()
                        self.movieTableView.hidden = false
                    } else {
                       self.changeTextForLabel(self.placeHolderLabel!, text: "No Results")
                    }
                })
            }
        } else {
            changeTextForLabel(placeHolderLabel!, text: "Internet Disconnected")
            showAlertViewWith("Oops", error: "Internet Disconnected", type: .AlertViewWithOneButton, firstButtonTitle: "OK", firstButtonHandler: nil, secondButtonTitle: nil, secondButtonHandler: nil)
        }
        
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}


// MARK: UITableViewDelegate, UITableViewDataSource

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let CellReuseId = "MovieSearchCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(CellReuseId) as! SearchTableViewCell!
        let movie = movies[indexPath.row]
        cell.titleLabel.text = movie.title
        cell.posterImageView.image = UIImage(named: "missing_poster")
        if let posterPath = movie.posterPath {
            cell.posterImageView.kf_setImageWithURL(TMDBClient.sharedInstance.createUrlForImages(TMDBClient.PosterSizes.RowPoster, filePath: posterPath), placeholderImage: nil, optionsInfo: nil, progressBlock: nil, completionHandler: { image, error, cacheType, imageURL in
                    performUIUpdatesOnMain({ 
                        self.movieTableView.reloadData()
                    })
            })
        }
        if let releaseYear = movie.releaseYear {
            cell.releaseYearLabel.text = "Year: \(releaseYear)"
        }
        
        if let voting = movie.voteAverage {
            cell.ratingLabel.text = "Average: \(voting)"
        }
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let movie = movies[indexPath.row]
        let controller = storyboard!.instantiateViewControllerWithIdentifier("MovieDetailViewController") as! MovieDetailViewController
        controller.movieID = movie.id
        controller.moviePosterPath = movie.posterPath
        controller.modalDelegate = self
        tr_presentViewController(controller, method: TRPresentTransitionMethod.Fade)
    }
}