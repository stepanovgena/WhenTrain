//
//  TimetableTableViewController.swift
//  WhenTrain
//
//  Created by Gennady Stepanov on 14/03/2019.
//  Copyright © 2019 Gennady Stepanov. All rights reserved.
//

import UIKit

class TimetableTableViewController: UITableViewController {
  
  
  
  var fromStationCode: String?
  var toStationCode: String?
  var segmentsArray: [[String : Any]]?

    override func viewDidLoad() {
        super.viewDidLoad()
      
      tableView.register(UINib(nibName: "TimetableTableViewCell", bundle: nil),
                         forCellReuseIdentifier: "segmentCell")
      
      if (fromStationCode != nil && toStationCode != nil) {
              requestTimetableBetweenStations(fromStationCode: fromStationCode!, toStationCode: toStationCode!)
          }

    }
  
  private func requestTimetableBetweenStations(fromStationCode: String, toStationCode: String) {
   
    let configuration = URLSessionConfiguration.default
    let session = URLSession(configuration: configuration)
    var urlConstructor = URLComponents()
    urlConstructor.scheme = "https"
    urlConstructor.host = "api.rasp.yandex.net"
    urlConstructor.path = "/v3.0/search"
    urlConstructor.queryItems = [
      URLQueryItem(name: "apikey", value: "b361b0fc-e231-41be-ae59-ea74f6f9bafa"),
      URLQueryItem(name: "lang", value: "ru_RU"),
      URLQueryItem(name: "format", value: "json"),
      URLQueryItem(name: "from", value: fromStationCode),
      URLQueryItem(name: "to", value: toStationCode),
      URLQueryItem(name: "transport_types", value: "suburban"),
      URLQueryItem(name: "limit", value: "10"),
      
    ]
    
    let task = session.dataTask(with: urlConstructor.url!) { data, response, error in
      
      guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) else { return }
      
      let result = json as! [String : Any]
      print(result)
      print ("**********************")
       self.segmentsArray = result["segments"] as? [[String : Any]]
      
      DispatchQueue.main.async {
        self.tableView.reloadData()
      }
      
       print(self.segmentsArray)
    }
    task.resume()
  }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      
      guard let numberOfRows = segmentsArray?.count else { return 0 }
      
        return numberOfRows
    }

  
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = tableView.dequeueReusableCell(withIdentifier: "segmentCell", for: indexPath) as! TimetableTableViewCell
      
      if let thread = segmentsArray?[indexPath.row]["thread"] as? [String : Any] {
      
        cell.threadTitleLabel.text = thread["title"] as? String
      
      }
        return cell
    }
}
