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
  var shouldSegueToStations = true
  
  override func viewDidLoad() {
    super.viewDidLoad()
    fromStationTextField.delegate = self
    fetchStationData()
    circleProgressIndicator.isHidden = true
  }
  
  private func updateStations() {
    
    circleProgressIndicator.isHidden = false
    
    let url = URL(string: "https://api.rasp.yandex.net/v3.0/stations_list/?apikey=b361b0fc-e231-41be-ae59-ea74f6f9bafa&lang=ru_RU&format=json")!
    
    URLSession.shared.dataTask(with: url) { data, response, error in
      
      guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) else { return }
      
      let result = json as! [String : Any]
      let countries = result["countries"] as? [[String : Any]]
      let russia = countries?.filter { country in
        country["title"] as! String == "Россия"
        }.first
      let regions = russia?["regions"] as? [[String : Any]]
      let moscowAndMoscowRegion = regions?.filter { region in
        region["title"] as! String == "Москва и Московская область"
        }.first
      
      let moscowRegionSettlements = moscowAndMoscowRegion?["settlements"] as! [[String : Any]]
      
      for settlement in moscowRegionSettlements {
      
        let settlementCode: String = (settlement["codes"] as! [String : Any])["yandex_code"] as? String ?? ""
        let settlementTitle: String = settlement["title"] as? String ?? ""
        let stations = settlement["stations"] as! [[String : Any]]
        
        for item in stations where (item["transport_type"] as! String == "train") {
          
          let station = Station(context: self.managedContext)
          station.stationTitle = item["title"] as? String
          station.stationCode = (item["codes"] as! [String : Any])["yandex_code"] as? String
          station.direction = item["direction"] as? String
          station.settlementTitle = settlementTitle
          station.settlementCode = settlementCode
        }
      }
      do {
        try self.managedContext.save()
      }
        catch let error as NSError {
          print("Fetching error: \(error), \(error.userInfo)")
        }
      
      DispatchQueue.main.async {
        self.circleProgressIndicator.isHidden = true
      }
     print("station download completed")

      }.resume()
  }
  
  private func batchDeleteStations() {
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Station")
    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
    
    do {
      try managedContext.execute(deleteRequest)
      try managedContext.save()
    } catch let error as NSError {
      print("Fetching error: \(error), \(error.userInfo)")
    }
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
    print(fetchedResultsController.sections?.count)
  }
  
  @IBAction func fillFromStation(segue: UIStoryboardSegue) {
//    if segue.identifier == "stationSelected" {
//      //shouldSegueToStations = false
//      let availableStationsViewController = segue.source as! SelectStationTableTableViewController
//
//        let fromStation = availableStationsViewController.selectedFromStation
//      fromStationTextField.text = fromStation?.stationTitle
    
//    }
  }
  
  
  @IBAction func getStationsPressed(_ sender: Any) {
    updateStations()
  }
  
  @IBAction func fetchPressed(_ sender: Any) {
    fetchStationData()
  }
  
  @IBAction func batchDeletePressed(_ sender: Any) {
    batchDeleteStations()
  }
  
//  override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
//    if (identifier == "segueToSelectStation") {
//    return shouldSegueToStations
//    }
//    return true
//  }
  @IBAction func fromStationTouchDown(_ sender: Any) {
    performSegue(withIdentifier: "selectFromStationSegue", sender: self)
  }
  

  @IBAction func toStationTouchDown(_ sender: Any) {
    performSegue(withIdentifier: "selectToStationSegue", sender: self)
  }
  
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    return false
  }
  
  
  
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let destination = segue.destination as? SelectStationTableTableViewController {
      destination.managedContext = managedContext
    }
  }
  
  @IBAction func unwindToMain(unwindSegue: UIStoryboardSegue) {
  
  }
  
}
