//
//  Station+CoreDataProperties.swift
//  WhenTrain
//
//  Created by Gennady Stepanov on 11/03/2019.
//  Copyright © 2019 Gennady Stepanov. All rights reserved.
//
//

import Foundation
import CoreData


extension Station {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Station> {
        return NSFetchRequest<Station>(entityName: "Station")
    }

    @NSManaged public var stationTitle: String?
    @NSManaged public var stationCode: String?
    @NSManaged public var direction: String?
    @NSManaged public var settlementTitle: String?
    @NSManaged public var settlementCode: String?

}
