//
//  STTNTests.swift
//  STTNTests
//
//  Created by OS Programming on 29/05/23.
//

import XCTest
@testable import STTN

import SwiftGraph

final class STTNTests: XCTestCase {
    
    public var graph: WeightedGraph<String, Int> = WeightedGraph<String, Int>(vertices: ["0", "1", "2", "3"])
    
    public var position_vertexes : [String : [String: Float]] = ["0":["x":0.0,"y":0.0],"1":["x":3,"y":0.0],"2":["x":4,"y":4],"3":["x":0.0,"y":4]] // vertex, x , y
    
    public var position_markers : [String : [String: Float]] = ["M0":["x":0.0,"y":0.8],"M1":["x":12.3,"y":0.0],"M2":["x":11.4,"y":23.12],"M3":["x":0.0,"y":20.32],"M4":["x":7.2,"y":22.32],"M5":["x":1.32,"y":18.72],"M6":["x":1.32,"y":28.92],"M7":["x":6.9,"y":28.92]] // marcatori, x , y
    
    var links: [Link] = [
        Link( node_u :"0", node_v :"1", widthOfSafeArea :1.0),
        Link( node_u :"1", node_v :"2", widthOfSafeArea :1.0),
        Link( node_u :"2", node_v :"3", widthOfSafeArea :1.0),
        Link( node_u :"3", node_v :"0", widthOfSafeArea :1.0)
    ]
    
    //public var destination_position : [String: Float] = ["x_d": 6.9, "y_d": 27] // posizione della destinazione // vicino vertice 7
    public var destination_position : [String: Float] = ["x_d": 4, "y_d": 3.9] // posizione della destinazione // vicino vertice 2
    public var radius_destination : Float = 1.0// raggio della destinazione

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        XCTAssertEqual(1,1,"not equal")
        
        
    }
    
    

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    

}
