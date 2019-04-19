//
//  MainViewController.swift
//  WhenTrain
//
//  Created by Gennady Stepanov on 11/03/2019.
//  Copyright © 2019 Gennady Stepanov. All rights reserved.
//

import UIKit
import CoreData

class MainViewController: UIViewController, UITextFieldDelegate {

  @IBOutlet weak var circleProgressIndicator: CircleProgressIndicator!
  @IBOutlet weak var fromStationTextField: UITextField!
  @IBOutlet weak var toStationTextField: UITextField!
  
  var managedContext: NSManagedObjectContext!
  var fetchedResultsController: NSFetchedResultsController<Station>!
  var stationsListLastUpdate: Int32 = 0
  var stationSwitcher = StationSwitcher.none
  var fromStationCode: String?
  var toStationCode: String?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    fromStationTextField.delegate = self
    //fetchStationData()
    circleProgressIndicator.isHidden = true
  }
  
  /** Fetches, parses and saves Station info to CoreData */
  private func getStations() {
    circleProgressIndicator.isHidden = false
    
    let configuration = URLSessionConfiguration.default
    let session = URLSession(configuration: configuration)
    var urlConstructor = URLComponents()
    urlConstructor.scheme = "https"
    urlConstructor.host = "api.rasp.yandex.net"
    urlConstructor.path = "/v3.0/stations_list"
    urlConstructor.queryItems = [
      URLQueryItem(name: "apikey", value: "b361b0fc-e231-41be-ae59-ea74f6f9bafa"),
      URLQueryItem(name: "lang", value: "ru_RU"),
      URLQueryItem(name: "format", value: "json")
    ]
    
    let task = session.dataTask(with: urlConstructor.url!) { data, response, error in
      
      guard let data = data else { return }
      
      do {
        let response: Response = try JSONDecoder().decode(Response.self, from: data)
        let countries = response.countries
        let russia = countries.filter { country in
          country.title == "Россия"
          }.first
        let regions = russia?.regions
        let moscowAndMoscowRegion = regions?.filter { region in
          region.title == "Москва и Московская область"
          }.first
        if let moscowRegionSettlements = moscowAndMoscowRegion?.settlements {
    
          for settlement in moscowRegionSettlements {
            let settlementTitle = settlement.title
            let settlementCode = settlement.codes["yandex_code"]
            let stations = settlement.stations
            for station in stations where station.transportType == "train" {
              let stationCoreData = Station(context: self.managedContext)
              stationCoreData.settlementTitle = settlementTitle
              stationCoreData.settlementCode = settlementCode
              stationCoreData.direction = station.direction
              stationCoreData.stationCode = station.codes["yandex_code"]
              stationCoreData.stationTitle = station.title
            }
          }
          do {
            try self.managedContext.save()
          }
          catch let error as NSError {
            print("Fetching error: \(error), \(error.userInfo)")
          }
        }
        
    } catch let error {
      print(error)
      }
      
      DispatchQueue.main.async {
        self.circleProgressIndicator.isHidden = true
      }
      print("station download completed")
      
    }
    task.resume()
  }
  
  /** Deletes all Station data from Core Data */
  private func batchDeleteStations() {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Station")
    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
    
    do {
      try managedContext.execute(deleteRequest)
      try managedContext.save()
    } catch let error as NSError {
      print("Fetching error: \(error), \(error.userInfo)")
    }
    print("All stations removed from CoreData")
  }
  
  /** Used for debugging only */
  private func fetchStationData() {
    let fetchRequest: NSFetchRequest<Station> = Station.fetchRequest()
    let sort = NSSortDescriptor(key: #keyPath(Station.settlementTitle), ascending: true)
    fetchRequest.sortDescriptors = [sort]
    
    fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedContext, sectionNameKeyPath: "settlementTitle", cacheName: "stationsCache")
    
    do {
      try fetchedResultsController.performFetch()
    } catch let error as NSError {
      print("Fetching error: \(error), \(error.userInfo)")
    }
  }
  
  @IBAction func getStationsPressed(_ sender: Any) {
    getStations()
  }
  
  @IBAction func batchDeletePressed(_ sender: Any) {
    batchDeleteStations()
  }
  
  @IBAction func getTimetablePressed(_ sender: Any) {
    guard (fromStationCode != nil && toStationCode != nil) else { return }
    performSegue(withIdentifier: "toTimetable", sender: self)
  }
  
  
  @IBAction func fromStationTouchDown(_ sender: Any) {
    stationSwitcher = .from
    performSegue(withIdentifier: "selectFromStationSegue", sender: self)
  }
  
  @IBAction func toStationTouchDown(_ sender: Any) {
    stationSwitcher = .to
    performSegue(withIdentifier: "selectToStationSegue", sender: self)
  }
  
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    return false
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if (segue.identifier == "selectFromStationSegue" || segue.identifier == "selectToStationSegue") {
    if let destination = segue.destination as? SelectStationTableViewController {
      destination.managedContext = managedContext
      
      switch stationSwitcher {
      case .from: destination.stationSwitcher = .from
      case .to: destination.stationSwitcher = .to
      case .none: return
      }
    }
    } else if (segue.identifier == "toTimetable" && fromStationCode != nil && toStationCode != nil) {
      if let destination = segue.destination as? TimetableTableViewController {
        destination.fromStationCode = fromStationCode
        destination.toStationCode = toStationCode
      }
    }
      
  }
  
  @IBAction func unwindToMain(unwindSegue: UIStoryboardSegue) {
  
  }
}
