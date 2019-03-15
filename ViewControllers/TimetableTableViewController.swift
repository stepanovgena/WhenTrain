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
  var departureTimeFormattedSince1970: Double?
  var arrivalTimeFormattedSince1970: Double?

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
  
  private func getDurationString(beginTimeSeconds: Double, endTimeSeconds: Double) -> String {
    var durationString: String = ""
    
    let durationMinutesInt = Int(endTimeSeconds - beginTimeSeconds)/60
    
    if (durationMinutesInt < 60) {
      durationString = "\(durationMinutesInt) мин."
    } else {
      let hours: Int = durationMinutesInt/60
      let minutes: Int = durationMinutesInt%60
      durationString = "\(hours) ч. \(minutes) мин."
    }
    return durationString
  }
  
  private func convenienceTimeStringFormat(durationMinutesInt: Int) -> String {
     var durationString: String = ""
    if (durationMinutesInt < 60) {
      durationString = "\(durationMinutesInt) мин."
    } else {
      let hours: Int = durationMinutesInt/60
      let minutes: Int = durationMinutesInt%60
      durationString = "\(hours) ч. \(minutes) мин."
    }
    return durationString
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
        
        let trimmedDepartureTimeString = String(departureTimeString.prefix(5))
       
        cell.departureTimeLabel.text = trimmedDepartureTimeString
        let currentTimeDate = Date()
        let currentTimeString = dateFormatter.string(from: currentTimeDate)
        let currentTime = dateFormatter.date(from: currentTimeString)
        departureTimeFormattedSince1970 = departureTime?.timeIntervalSince1970 as! Double
        let currentTimeFormattedSince1970 = currentTime?.timeIntervalSince1970 as! Double
        let waitingTimeMinutesInt = Int(departureTimeFormattedSince1970! - currentTimeFormattedSince1970)/60
        let waitingTimeString = getDurationString(beginTimeSeconds: currentTimeFormattedSince1970, endTimeSeconds: departureTimeFormattedSince1970!)
        
        if (waitingTimeMinutesInt > 0) {
        cell.waitingTimeLabel.text = "через \(waitingTimeString)"
        } else if (waitingTimeMinutesInt == 0) {
          cell.waitingTimeLabel.text = "сейчас"
        } else {
          cell.waitingTimeLabel.text = ""
        }
      }
      
      if let arrivalTimeString = segmentsArray?[indexPath.row]["arrival"] as? String {
        let trimmedArrivalTimeString = String(arrivalTimeString.prefix(5))
        cell.arrivalTimeLabel.text = trimmedArrivalTimeString
        let arrivalTimeDate = dateFormatter.date(from: arrivalTimeString)
        arrivalTimeFormattedSince1970 = arrivalTimeDate?.timeIntervalSince1970 as! Double
      }
      
      if (arrivalTimeFormattedSince1970 != nil && departureTimeFormattedSince1970 != nil) {
       var timeToTravelMin = Int(arrivalTimeFormattedSince1970! - departureTimeFormattedSince1970!)/60
        if timeToTravelMin > 0 {
        cell.durationLabel.text = convenienceTimeStringFormat(durationMinutesInt: timeToTravelMin)
        } else {
          let midnightFormatSince1970PlusSec = dateFormatter.date(from: "00:00:01")?.timeIntervalSince1970
          let midnightFormatSince1970MinusSec = dateFormatter.date(from: "23:59:59")?.timeIntervalSince1970
          
          let timeToTravelBeforeMidnight = Int(midnightFormatSince1970MinusSec! - departureTimeFormattedSince1970!)/60
          let timeToTravelAfterMidnight = Int(arrivalTimeFormattedSince1970! - midnightFormatSince1970PlusSec!)/60
        
          timeToTravelMin = timeToTravelBeforeMidnight + timeToTravelAfterMidnight
          cell.durationLabel.text = convenienceTimeStringFormat(durationMinutesInt: timeToTravelMin)
        }
      }
      if let thread = segmentsArray?[indexPath.row]["thread"] as? [String : Any] {
        cell.threadTitleLabel.text = thread["title"] as? String
      }
        return cell
    }
}
