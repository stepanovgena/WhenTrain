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
  var selectedFromStation: Station!
//  {
//    didSet(value)  {
//      print ("selectedFromStation did set to \(String(describing: value.stationTitle))")
//    }
//  }
  
    override func viewDidLoad() {
        super.viewDidLoad()
      
      fetchStationData()
      
      selectedFromStation = fetchedResultsController.object(at: IndexPath(row: 0, section: 0))
      
      searchBar.delegate = self

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
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
    selectedFromStation = fetchedResultsController.object(at: indexPath)
    print("indexPath: \(indexPath)")
    print(selectedFromStation.stationTitle)
    performSegue(withIdentifier: "unwindToMain", sender: self)
  }
  

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

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
    print(fetchedResultsController.sections?.count)
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
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let mainViewController = segue.destination as? MainViewController {
      mainViewController.fromStationTextField.text = selectedFromStation.stationTitle
    }
  }

}
