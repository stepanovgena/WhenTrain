//
//  SelectStationTableTableViewController.swift
//  WhenTrain
//
//  Created by Gennady Stepanov on 12/03/2019.
//  Copyright © 2019 Gennady Stepanov. All rights reserved.
//

import UIKit
import CoreData

class SelectStationTableTableViewController: UITableViewController, UISearchBarDelegate {
 
  @IBOutlet weak var searchBar: UISearchBar!
  @IBOutlet var stationsTableView: UITableView!
  
  var managedContext: NSManagedObjectContext!
  var fetchedResultsController: NSFetchedResultsController<Station>!
  var selectedStation: Station!
  var stationSwitcher = StationSwitcher.none
  
  //MARK: -Lifecycle
    override func viewDidLoad() {
      super.viewDidLoad()
      fetchStationData()
      searchBar.delegate = self
    }
  
  private func fetchStationData() {
    let fetchRequest: NSFetchRequest<Station> = Station.fetchRequest()
    let sort = NSSortDescriptor(key: #keyPath(Station.settlementTitle), ascending: true)
    fetchRequest.sortDescriptors = [sort]
    
    fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedContext, sectionNameKeyPath: "settlementTitle", cacheName: nil)
    
    do {
      try fetchedResultsController.performFetch()
    } catch let error as NSError {
      print("Fetching error: \(error), \(error.userInfo)")
    }
    print("sections in fetched results:")
    print(fetchedResultsController.sections?.count as Any)
  }
  
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    if !searchText.isEmpty {
      var predicate: NSPredicate = NSPredicate()
      predicate = NSPredicate(format: "stationTitle contains[c] '\(searchText)'")
      let fetchRequest: NSFetchRequest<Station> = Station.fetchRequest()
      fetchRequest.predicate = predicate
      let sort = NSSortDescriptor(key: #keyPath(Station.settlementTitle), ascending: true)
      fetchRequest.sortDescriptors = [sort]
      fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedContext, sectionNameKeyPath: "settlementTitle", cacheName: nil)
      do {
        try fetchedResultsController.performFetch()
      } catch let error as NSError {
        print("Could not fetch. \(error)")
      }
    } else { fetchStationData() }
    stationsTableView.reloadData()
  }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
      guard let sections = fetchedResultsController.sections else { return 0 }
      
      return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      guard let sectionInfo = fetchedResultsController.sections?[section] else { return 0 }
      
      return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: "stationCellReuseIdentifier", for: indexPath) as! SelectStationTableViewCell
      
      let station = fetchedResultsController.object(at: indexPath)
      cell.stationTitle.text = station.stationTitle ?? "unknown"
      
        return cell
    }
  
  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 44
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    let sectionInfo = fetchedResultsController.sections?[section]
    return sectionInfo?.name
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    selectedStation = fetchedResultsController.object(at: indexPath)
    print("indexPath: \(indexPath)")
    print(selectedStation.stationTitle as Any)
    performSegue(withIdentifier: "unwindToMain", sender: self)
  }
  
  //MARK: -Navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let mainViewController = segue.destination as? MainViewController {
      switch stationSwitcher {
      case .from: mainViewController.fromStationTextField.text = selectedStation.stationTitle
      case .to: mainViewController.toStationTextField.text = selectedStation.stationTitle
      case .none: return
      }
    }
  }
}
