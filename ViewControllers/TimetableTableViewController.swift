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
  var segmentsArray: [Segments]?
  var backgroundView: UIView?
  var circleProgressIndicator: CircleProgressIndicator?
  let dateFormatter = DateFormatter()
  var departureTimeFormattedSince1970: Double?
  var arrivalTimeFormattedSince1970: Double?
  var rowToScrollTo: Int = 0

  //MARK: -Lifecycle
    override func viewDidLoad() {
      super.viewDidLoad()
      dateFormatter.dateFormat = "HH:mm:ss"
      showLoaderWhileFetching()
      tableView.register(UINib(nibName: "TimetableTableViewCell", bundle: nil),
                         forCellReuseIdentifier: "segmentCell")
      if (fromStationCode != nil && toStationCode != nil) {
              requestTimetableBetweenStations(fromStationCode: fromStationCode!, toStationCode: toStationCode!)
      }
    }
  
  //MARK: -Data fetching
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
      URLQueryItem(name: "limit", value: "200")
    ]
    
    let task = session.dataTask(with: urlConstructor.url!) { data, response, error in
      
      guard let data = data else { return }
      
      do {
        let response: SearchResult = try JSONDecoder().decode(SearchResult.self, from: data)
        self.segmentsArray = response.segments
        DispatchQueue.main.async {
          self.tableView.reloadData() //initially tableView loads empty, needs to be reloaded when fetching complete
          self.hideLoaderAfterFetchingComplete()
          
          //set departure times array to define scrolling position
          var departureTimesArray: [String] = []
          for segment in self.segmentsArray! {
            departureTimesArray.append(segment.departure)
          }
          let scrollPosition = self.getRowToScrollTo(departureTimesArray: departureTimesArray, dateFormatter: self.dateFormatter)
          
          if (scrollPosition != 0) {
            self.tableView.scrollToRow(at: IndexPath(row: scrollPosition, section: 0), at: .top, animated: true)
          }
        }
      } catch {
        print(error)
      }
      
    }
    task.resume()
  }
  
    // MARK: -Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      guard let numberOfRows = segmentsArray?.count else { return 0 }
      print("\(numberOfRows) rows")
      return numberOfRows
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      
      let cell = tableView.dequeueReusableCell(withIdentifier: "segmentCell", for: indexPath) as! TimetableTableViewCell
      
     //parse and set departure time label and waiting time
      if let departureTimeString = segmentsArray?[indexPath.row].departure {
        let trimmedDepartureTimeString = String(departureTimeString.prefix(5)) //use only HH:mm from HH:mm:ss
        cell.departureTimeLabel.text = trimmedDepartureTimeString
        cell.waitingTimeLabel.text = getWaitingTimeFromDepartureTime(dateFormatter: dateFormatter, departureTime: departureTimeString)
      }
      
      //grey-out all cells above nearest departure position
      if (indexPath.row < rowToScrollTo){
        cell.blendingView.alpha = 0.5
      } else {
        cell.blendingView.alpha = 0
      }
      
      //parse and set arrival time label
      if let arrivalTimeString = segmentsArray?[indexPath.row].arrival {
        let trimmedArrivalTimeString = String(arrivalTimeString.prefix(5))
        cell.arrivalTimeLabel.text = trimmedArrivalTimeString
        let arrivalTimeDate = dateFormatter.date(from: arrivalTimeString)
        arrivalTimeFormattedSince1970 = arrivalTimeDate?.timeIntervalSince1970
      }
      
      //calculate and set travel duration label
      if (departureTimeFormattedSince1970 != nil && arrivalTimeFormattedSince1970 != nil) {
        cell.durationLabel.text = getTravelTimeBetweenDepartureAndArrival(departureInSeconds: departureTimeFormattedSince1970!, arrivalInSeconds: arrivalTimeFormattedSince1970!)
      }
      
      //parse and set thread(route) title
      if let thread = segmentsArray?[indexPath.row].thread {
        cell.threadTitleLabel.text = thread.title
      }
        return cell
    }
}

//MARK: -Extensions
extension TimetableTableViewController {
  
  /** Shows progress indicator while data is fetching, removal must be implemented at completion block of fetching method (using UI thread), use in conjunction with hideLoaderAfterFetchingComplete */
  private func showLoaderWhileFetching() {
    let backgroundColor = UIColor.white
    backgroundView = UIView(frame: view.frame)
    backgroundView?.backgroundColor = backgroundColor
    circleProgressIndicator = CircleProgressIndicator(frame: CGRect(x: view.center.x - 16, y: view.center.y - 32, width: 32, height: 32))
    circleProgressIndicator?.backgroundColor = backgroundColor
    backgroundView?.addSubview(circleProgressIndicator!)
    tableView.separatorStyle = .none
    view.addSubview(backgroundView!)
    view.bringSubviewToFront(backgroundView!)
  }
  
  /** Hides the loader added with showLoaderWhileFetching() method */
  private func hideLoaderAfterFetchingComplete() {
    UIView.animate(withDuration: 1, animations: {
      self.backgroundView?.alpha = 0
    }) { _ in
      self.backgroundView?.removeFromSuperview()
    }
    tableView.separatorStyle = .singleLine
  }
  
  private func getRowToScrollTo(departureTimesArray: [String], dateFormatter: DateFormatter) -> Int {
   
    var rowToScrollfound = false
    for departureTime in departureTimesArray {
      if !rowToScrollfound {
      let departureTimeSince1970 = dateFormatter.date(from: departureTime)?.timeIntervalSince1970
      let currentTimeString = dateFormatter.string(from: Date())
      let currentTimeSince1970 = dateFormatter.date(from: currentTimeString)?.timeIntervalSince1970
        if (departureTimeSince1970! > currentTimeSince1970!) {
          rowToScrollTo = departureTimesArray.firstIndex(of: departureTime) ?? 0
          rowToScrollfound = true
        }
      }
    }
    return rowToScrollTo
  }
  
  /** For a given departure time calculates waiting time from now */
  private func getWaitingTimeFromDepartureTime(dateFormatter: DateFormatter, departureTime: String) -> String {
    
    var waitingTime: String = ""
    
    let departureTime = dateFormatter.date(from: departureTime)
    let currentTimeString = dateFormatter.string(from: Date())
    let currentTime = dateFormatter.date(from: currentTimeString)
    
    if let currentTimeFormattedSince1970 = currentTime?.timeIntervalSince1970, let departureTimeFormattedSince1970 = departureTime?.timeIntervalSince1970 {
      self.departureTimeFormattedSince1970 = departureTimeFormattedSince1970
      let waitingTimeMinutesInt = Int(departureTimeFormattedSince1970 - currentTimeFormattedSince1970)/60
      let waitingTimeToString = getDurationStringFromTimestamps(beginTimeSeconds: currentTimeFormattedSince1970, endTimeSeconds: departureTimeFormattedSince1970)
      
      if (waitingTimeMinutesInt > 0) {
         waitingTime = "через \(waitingTimeToString)"
      } else if (waitingTimeMinutesInt == 0) {
         waitingTime = "сейчас"
      } else {
         waitingTime = ""
      }
    }
    return waitingTime
  }
  
  /** For any two timeintervals in seconds provides a String describing difference duration in human language format - minutes or hours and minutes depending on duration */
  private func getDurationStringFromTimestamps(beginTimeSeconds: Double, endTimeSeconds: Double) -> String {
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
  /** For any duration in minutes provides uration in human language format - minutes or hours and minutes depending on duration*/
  private func getDurationStringFromDurationInMinutes(durationMinutesInt: Int) -> String {
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
  
  private func getTravelTimeBetweenDepartureAndArrival(departureInSeconds: Double, arrivalInSeconds: Double) -> String {
    
      var timeToTravelMin = Int(arrivalInSeconds - departureInSeconds)/60
      if timeToTravelMin > 0 {
        return getDurationStringFromDurationInMinutes(durationMinutesInt: timeToTravelMin)
      } else {
        let midnightFormatSince1970PlusSec = dateFormatter.date(from: "00:00:01")?.timeIntervalSince1970
        let midnightFormatSince1970MinusSec = dateFormatter.date(from: "23:59:59")?.timeIntervalSince1970
        
        let timeToTravelBeforeMidnight = Int(midnightFormatSince1970MinusSec! - departureInSeconds)/60 + 1 //+1 needed to correct for 59 sec initially lost
        let timeToTravelAfterMidnight = Int(arrivalInSeconds - midnightFormatSince1970PlusSec!)/60
        
        timeToTravelMin = timeToTravelBeforeMidnight + timeToTravelAfterMidnight
        return getDurationStringFromDurationInMinutes(durationMinutesInt: timeToTravelMin)
      }
  }
}
