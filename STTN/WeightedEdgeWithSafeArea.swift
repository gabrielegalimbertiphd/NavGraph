//
//  WeightedEdgeWithSafeArea.swift
//  STTN
//
//  Created by OS Programming on 01/06/23.
//

import SwiftGraph
import Foundation

public protocol WeightedEdgeWithSafeAreaProtocol {
    init(u: Int, v: Int, p1x: Float, p1y: Float, p2x: Float, p2y: Float, width: Float)
}

extension WeightedEdgeWithSafeArea: WeightedEdgeWithSafeAreaProtocol {
    public typealias Weight = W
}

func distanceBetweenTwoPoints2D(p1x:Float, p1y:Float, p2x:Float, p2y:Float)->Float{
    return sqrt(pow(p1x-p2x, 2)+pow(p1y-p2y, 2))
}

/// A weighted edge, who's weight subscribes to Comparable.
public struct WeightedEdgeWithSafeArea<W: Equatable & Codable>: Edge, CustomStringConvertible, Equatable {
    
    public var directed: Bool = false
    public var u: Int
    public var v: Int
    public var p1x: Float
    public var p1y: Float
    public var p2x: Float
    public var p2y: Float
    public var weight: Float
    public var width: Float
    
    public init(u: Int, v: Int, p1x: Float, p1y: Float, p2x: Float, p2y: Float, width: Float) {
        self.u = u
        self.v = v
        self.p1x = p1x
        self.p1y = p1y
        self.p2x = p2x
        self.p2y = p2y
        self.weight = distanceBetweenTwoPoints2D(p1x: p1x, p1y: p1y, p2x: p2x, p2y: p2y)//distanceBetweenTwoPoints(p1:p1,p2:p2)
        self.width = width
    }
    
    /*
     func distanceBetweenTwoPoints(p1:Array<Float>, p2:Array<Float>)->Float{
        var values = 1...min(p1.count,p2.count)
        var sum:Float = 0.0
        for i in values {
            sum+=pow(p1[i]-p2[i],2)
        }
        return sqrt(sum)
    }
     */
    
    
    public func reversed() -> WeightedEdgeWithSafeArea<W> {
        return WeightedEdgeWithSafeArea(u: v, v: u, p1x: p1x, p1y: p1y, p2x: p2x, p2y: p2y, width: width)
    }

    //Implement Printable protocol
    public var description: String {
        return "\(u) \(weight)> \(v)"
    }
    
    //MARK: Operator Overloads
    static public func == (lhs: WeightedEdgeWithSafeArea, rhs: WeightedEdgeWithSafeArea) -> Bool {
        return lhs.u == rhs.u && lhs.v == rhs.v && lhs.weight == rhs.weight
    }

}

extension WeightedEdgeWithSafeArea: Comparable where W: Comparable {
    static public func < (lhs: WeightedEdgeWithSafeArea<W>, rhs: WeightedEdgeWithSafeArea<W>) -> Bool {
        return lhs.weight < rhs.weight
    }
}
