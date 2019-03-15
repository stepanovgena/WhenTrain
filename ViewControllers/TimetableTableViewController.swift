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
  var backgroundView: UIView?
  var circleProgressIndicator: CircleProgressIndicator?
  let dateFormatter = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
      
      tableView.register(UINib(nibName: "TimetableTableViewCell", bundle: nil),
                         forCellReuseIdentifier: "segmentCell")
      let backgroundColor = UIColor.white
      backgroundView = UIView(frame: view.frame)
      backgroundView?.backgroundColor = backgroundColor
      circleProgressIndicator = CircleProgressIndicator(frame: CGRect(x: view.center.x - 16, y: view.center.y - 32, width: 32, height: 32))
      circleProgressIndicator?.backgroundColor = backgroundColor
      backgroundView?.addSubview(circleProgressIndicator!)
     // tableView.isHidden = true
      tableView.separatorStyle = .none
      view.addSubview(backgroundView!)
      view.bringSubviewToFront(backgroundView!)
      
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
      URLQueryItem(name: "limit", value: "200"),
      
    ]
    
    let task = session.dataTask(with: urlConstructor.url!) { data, response, error in
      
      guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) else { return }
      
      let result = json as! [String : Any]
      
       self.segmentsArray = result["segments"] as? [[String : Any]]
      
      DispatchQueue.main.async {
        self.tableView.reloadData()
        UIView.animate(withDuration: 1, animations: {
          self.backgroundView?.alpha = 0
        }) { _ in
          self.backgroundView?.removeFromSuperview()
        }
        self.tableView.separatorStyle = .singleLine
      }
    }
    task.resume()
  }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      
      guard let numberOfRows = segmentsArray?.count else { return 0 }
      
        return numberOfRows
    }

  
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      dateFormatter.dateFormat = "HH:mm:ss"
      let cell = tableView.dequeueReusableCell(withIdentifier: "segmentCell", for: indexPath) as! TimetableTableViewCell
      
      if let departureTimeString = segmentsArray?[indexPath.row]["departure"] as? String {
        
        let departureTime = dateFormatter.date(from: departureTimeString)
        let departureTimeConvertedToString = dateFormatter.string(from: departureTime!)
        //print(departureTimeConvertedToString)
  
        cell.departureTimeLabel.text = departureTimeString
        let currentTimeDate = Date()
        let currentTimeString = dateFormatter.string(from: currentTimeDate)
        let currentTime = dateFormatter.date(from: currentTimeString)
        let departureTimeFormattedSince1970 = departureTime?.timeIntervalSince1970 as! Double
        let currentTimeFormattedSince1970 = currentTime?.timeIntervalSince1970 as! Double
        let waitingTimeMinutes = Int(departureTimeFormattedSince1970 - currentTimeFormattedSince1970)/60
        
        if (waitingTimeMinutes > 0) {
        cell.waitingTimeLabel.text = "через \(String(waitingTimeMinutes)) мин."
        } else if (waitingTimeMinutes == 0) {
          cell.waitingTimeLabel.text = "сейчас"
        } else {
          cell.waitingTimeLabel.text = ""
        }
       if let arrivalTimeString = segmentsArray?[indexPath.row]["arrival"] as? String {
        cell.arrivalTimeLabel.text = arrivalTimeString
        }
      }
      if let thread = segmentsArray?[indexPath.row]["thread"] as? [String : Any] {
        cell.threadTitleLabel.text = thread["title"] as? String
      }
        return cell
    }
}
