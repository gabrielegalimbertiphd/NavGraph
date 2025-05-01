//
//  Level1.swift
//  STTN
//
//  Created by OS Programming on 28/06/23.
//

import Foundation
import SwiftGraph

struct Link : Equatable, Codable {
    var node_u : String
    var node_v : String
    var radiusOfNavigationArea : Float
    
    mutating func changeRadius(_ new_radius: Float){
        radiusOfNavigationArea = new_radius
    }
    
    mutating func compare(_ link1: Link, _ link2: Link) -> Bool{
        if link1.node_u==link2.node_u && link1.node_v==link2.node_v{
            return false
        } else {
            return true
        }
        return false
    }
    
}

class Level1 {
    
    public var graph: WeightedGraph<String, Int>
    public var position_vertexes : [String : [String: Float]] = [:]
    public var destination_position : [String: Float] = [:]
    public var vertexes : [String] = []
    public var radius_destination : Float = 0.0
    public var links: [Link] = []
    
    init(listOfVertexesCoordinates: [String : [String: Float]], destination_position: [String : Float], radius_destination: Float, links: [Link], vertexes: [String]) {
        self.destination_position = destination_position
        self.radius_destination = radius_destination
        self.links = links
        self.vertexes = vertexes
        self.position_vertexes = listOfVertexesCoordinates
        self.graph = WeightedGraph<String, Int>(vertices: vertexes)
        loadGraph(listOfVertexesCoordinates: listOfVertexesCoordinates, links: links)
    }
    
    func loadGraph(listOfVertexesCoordinates: [String : [String: Float]], links: [Link]){ //links:Array<(String,String)>){
        // grafo così e con pesi + array chiave valore con chiave il numero del vertice e valore la posizione del vertice. usato anche per calcolare i pesi.
        for link in links{
            let v1 = listOfVertexesCoordinates[link.node_u]
            let v2 = listOfVertexesCoordinates[link.node_v]
            //graph.addEdge(from: link.0, to:link.1, weight: Int(distanceBetweenTwoPoints2D(p1x:v1!["x"] ?? Float(Int.max), p1y:v1!["y"] ?? Float(Int.max), p2x:v2!["x"] ?? Float(Int.max), p2y:v2!["y"] ?? Float(Int.max))*100))
            self.graph.addEdge(
                from: link.node_u, to:link.node_v, weight: Int(distanceBetweenTwoPoints2D(p1x:v1!["x"] ?? Float(Int.max), p1y:v1!["y"] ?? Float(Int.max), p2x:v2!["x"] ?? Float(Int.max), p2y:v2!["y"] ?? Float(Int.max))*100), directed: false)
        }
        
    }
    
    func distanceBetweenTwoPoints2D(p1x:Float, p1y:Float, p2x:Float, p2y:Float)->Float{
        return sqrt(pow(p1x-p2x, 2)+pow(p1y-p2y, 2))
    }
    
    func distanceBetweenTwoPoints2D(p_u:(pux:Float, puy:Float),p_d:( pdx:Float, pdy:Float))->Float{
        return sqrt(pow(p_u.pux-p_d.pdx, 2)+pow(p_u.puy-p_d.pdy, 2))
    }
    
}
