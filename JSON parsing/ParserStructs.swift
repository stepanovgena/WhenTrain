//
//  ParserStructs.swift
//  WhenTrain
//
//  Created by Gennady Stepanov on 04/04/2019.
//  Copyright © 2019 Gennady Stepanov. All rights reserved.
//

import Foundation

//MARK: -Structs for retreiving available station list
struct Response: Codable {
  var countries: [Countries]
}

struct Countries: Codable {
  var title: String
  var regions: [Regions]
}

struct Regions: Codable {
  var title: String
  var settlements: [Settlement]
}

struct Settlement: Codable {
  var codes: [String : String]
  var title: String
  var stations: [StationData]
}

struct StationData: Codable {
  var title: String
  var codes: [String : String]
  var direction: String
  var transportType: String
  
  enum CodingKeys: String, CodingKey {
    case title
    case codes
    case direction
    case transportType = "transport_type"
  }
}

//MARK: -Structs for retreiving timetable data
struct SearchResult: Codable {
  var segments: [Segments]
}

struct Segments: Codable {
  var departure: String
  var arrival: String
  var thread: SegmentThread
}

struct SegmentThread: Codable {
  var title: String
}
