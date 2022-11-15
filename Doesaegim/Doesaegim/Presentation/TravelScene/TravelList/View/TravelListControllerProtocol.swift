//
//  TravelPlanControllerProtocol.swift
//  Doesaegim
//
//  Created by Jaehoon So on 2022/11/14.
//

import Foundation

protocol TravelListControllerProtocol {
    var delegate: TravelListControllerDelegate? { get set }
    
    var travelInfos: [TravelInfoViewModel] { get set }
    
    func fetchTravelInfo()
    
}

protocol TravelListControllerDelegate {
    func applyTravelSnapshot()
    func applyPlaceholdLabel()
}