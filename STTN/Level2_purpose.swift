//
//  Level2.swift
//  STTN
//
//  Created by OS Programming on 29/05/23.
//

import Foundation
import SwiftGraph

class Level2_purpose {
    
    // ALL EXPRESS IN MAP 2D COORDINATES X and Y
    
    var beta: Float = 0.0
    var alpha: Float = 0.0
    
    func getEdgesAtPosition(position: (px:Float,py:Float), input_Graph: any Graph, position_vertexes: [String : [String: Float]], links: [Link]) -> [any Edge] {
        var result : [Edge]  = []
        var link_of_e : Link = Link(node_u: "0", node_v: "1", radiusOfSafeArea: 1.0)
        for e in input_Graph.edgeList() {
            for l in links {
                if l.node_u == "\(e.u)" && l.node_v == "\(e.v)"{
                    link_of_e = l
                    break
                }
            }
            if(isInSafeAreaEdge(edge: e, position_u: position, radius: link_of_e.radiusOfSafeArea, position_vertexes: position_vertexes)){ // CAMBIA IN BASE ALLA RADIUS DELL'EDGE.
                result.append(e)
            }
        }
        return result
    }
    
    func isInSafeAreaEdge(edge: any Edge, position_u: (px:Float,py:Float), radius: Float, position_vertexes: [String : [String: Float]]) -> Bool{
        //d = pointSegmentDistance(p_u, e)
        let vertex_u = position_vertexes["\(edge.u)"]!
        let vertex_v = position_vertexes["\(edge.v)"]!
        let p1X:Float = vertex_u["x"] ?? 0
        let p1Y:Float = vertex_u["y"] ?? 0
        let p2X:Float = vertex_v["x"] ?? 0
        let p2Y:Float = vertex_v["y"] ?? 0
        if( getClosestPointOnEdge(position: position_u, p1X: p1X, p1Y: p1Y, p2X: p2X, p2Y: p2Y)?.distance ?? radius < radius ){
        //if( getClosestPointOnEdge(position: position_u, edge: edge, position_vertexes: position_vertexes)?.distance ?? radius < radius ){ // radius = radius of the SA
            return true
        }
        return false
    }

    func getClosestPointInSafeArea(position_u: (px:Float,py:Float), input_Graph: any Graph, percentage: Float, position_vertexes: [String : [String: Float]], links:[Link]) -> (px:Float,py:Float,edge:Link) {
        var result  : (px:Float,py:Float,edge:Link)? = nil
        //var result_debug : (pdx:Float,pdy:Float,px:Float,py:Float,dist:Float,edge:Link)? = nil
        var distance_result = Float(Int.max)
        var link_of_e : Link = Link(node_u: "0", node_v: "1", radiusOfSafeArea: 1.0)
        for e in input_Graph.edgeList() {
            for l in links {
                if l.node_u == "\(e.u)" && l.node_v == "\(e.v)"{
                    link_of_e = l
                    break
                }
            }
            let vertex_u = position_vertexes["\(e.u)"]!
            let vertex_v = position_vertexes["\(e.v)"]!
            let p1X:Float = vertex_u["x"] ?? 0
            let p1Y:Float = vertex_u["y"] ?? 0
            let p2X:Float = vertex_v["x"] ?? 0
            let p2Y:Float = vertex_v["y"] ?? 0
            let p=getClosestPointOnEdge(position: position_u, p1X: p1X, p1Y: p1Y, p2X: p2X, p2Y: p2Y)
            //let p2=getClosestPointOnSafeArea(position_u: position_u, distance: p!.distance, dx: p!.dx, dy: p!.dy, w_distance_from_safe_area_limit: link_of_e.radiusOfSafeArea*percentage)//p’ is the point on semiline pp_u with distance w from p. // Questo non è spiegato.
            //let d = distanceBetweenTwoPoints2D(p1x: position_u.px, p1y: position_u.py, p2x: p2.p2x, p2y: p2.p2y)
            let d = distanceBetweenTwoPoints2D(p1x: position_u.px, p1y: position_u.py, p2x: p!.x_point, p2y: p!.y_point)
            if( result==nil || d < distance_result){
                result = (p!.x_point,p!.y_point,link_of_e)
                distance_result = d
                
            } // end if
        } // end for
        //print("DEBUG  distance=\(result_debug!.dist) _ dx=\(result_debug!.pdx) _ dy=\(result_debug!.pdy) _ tx= \(result_debug!.px) _ ty=\(result_debug!.py) _ pux=\(position_u.px) _ puy=\(position_u.py)")
        
        return result!
    }
    
    // func getClosestPointOnEdge(position: (px:Float,py:Float), edge: any Edge, position_vertexes: [String : [String: Float]]) -> (distance: Float, x_point: Float, y_point: Float, dx: Float, dy: Float, t: Float)? {
    
    func getClosestPointOnEdge(position: (px:Float,py:Float), p1X: Float, p1Y: Float, p2X: Float, p2Y: Float) -> (distance: Float, x_point: Float, y_point: Float, dx: Float, dy: Float, t: Float)? {
        
        let p_uX:Float=position.px
        let p_uY:Float=position.py
        
        /*let vertex_u = position_vertexes["\(edge.u)"]!
        let vertex_v = position_vertexes["\(edge.v)"]!
        let p1X:Float = vertex_u["x"] ?? 0
        let p1Y:Float = vertex_u["y"] ?? 0
        let p2X:Float = vertex_v["x"] ?? 0
        let p2Y:Float = vertex_v["y"] ?? 0*/
        
        var dx : Float = p2X - p1X
        var dy : Float = p2Y - p1Y
        
        let t : Float = ((p_uX - p1X) * dx + (p_uY - p1Y) * dy)/(dx * dx + dy * dy)
        var closestX : Float = 0.0
        var closestY : Float = 0.0
        
        if (t < 0) { // See if this represents one of the segment's end points or a point in the middle. // DIVIDERE IN getClosestPoint e getClosestPointDistance.
            closestX=p1X
            closestY=p1Y
            dx = p1X - p_uX
            dy = p1Y - p_uY
        } else if (t > 1) {
            closestX=p2X
            closestY=p2Y
            dx = p2X - p_uX
            dy = p2Y - p_uY
        } else {
            closestX = p1X + t * dx
            closestY = p1Y + t * dy      // SISTEMARE PERCHÈ RITORNO UNA DISTANZA E NON UN PUNTO … SISTEMA SLIDE 25
            dx = closestX - p_uX
            dy = closestY - p_uY
        }
        let d = sqrt(dx * dx + dy * dy)
        
        return (d, closestX, closestY, dx, dy, t)
    }
    
    func getClosestPointOnSafeArea(position_u: (px:Float,py:Float), distance:Float, dx:Float, dy:Float, w_distance_from_safe_area_limit: Float)-> (p2x:Float,p2y:Float){
        alpha = acos(dx/distance)
        beta = acos(dy/distance)
        /*let dy2 = (dy+w_distance_from_safe_area_limit)*cos(beta)
        let dx2 = (dx-w_distance_from_safe_area_limit)*sin(beta)*/
        
        var dx2 = dx>0 ? (dx-w_distance_from_safe_area_limit) : (dx+w_distance_from_safe_area_limit)
        dx2 = dx2*sin(beta)
        
        var dy2 = dy>0 ? (dy-w_distance_from_safe_area_limit) : -(dy+w_distance_from_safe_area_limit)
        dy2 = dy2*cos(beta)
        
        return (position_u.px+dx2,position_u.py+dy2)
    }
    
    func distanceBetweenTwoPoints3D(p1x:Float, p1y:Float, p1z:Float, p2x:Float, p2y:Float, p2z:Float)->Float{
        return sqrt(pow(p1x-p2x, 2)+pow(p1y-p2y, 2)+pow(p1z-p2z, 2))
    }
    
    func distanceBetweenTwoPoints2D(p1x:Float, p1y:Float, p2x:Float, p2y:Float)->Float{
        return sqrt(pow(p1x-p2x, 2)+pow(p1y-p2y, 2))
    }
    
    func checkSharedEdgesDestination(E_u: inout [any Edge],E_d: inout [any Edge])->Int{
        var counter : Int = 0
        for e_u in E_u{
            for e_d in E_d{
                if((e_u.v==e_d.v && e_u.u==e_d.u) || (e_u.u==e_d.v && e_u.v==e_d.u)){
                    counter+=1
                    break
                }
            }
        }
        return counter
    }
    
    func getClosestEdge(position_u: (px:Float,py:Float), edges: [any Edge], percentage: Float, position_vertexes: [String : [String: Float]], links:[Link] ) -> Link {
        var result  : Link? = nil
        if edges.count==0 {
            return result!
        }
        var distance_result = Float(Int.max)
        var link_of_e : Link? = nil
        for e in edges {
            for l in links {
                if l.node_u == "\(e.u)" && l.node_v == "\(e.v)"{
                    link_of_e = l
                    break
                }
            }
            let vertex_u = position_vertexes["\(e.u)"]!
            let vertex_v = position_vertexes["\(e.v)"]!
            let p1X:Float = vertex_u["x"] ?? 0
            let p1Y:Float = vertex_u["y"] ?? 0
            let p2X:Float = vertex_v["x"] ?? 0
            let p2Y:Float = vertex_v["y"] ?? 0
            //let p=getClosestPointOnEdge(position: position_u, edge: e, position_vertexes: position_vertexes)
            let p=getClosestPointOnEdge(position: position_u, p1X: p1X, p1Y: p1Y, p2X: p2X, p2Y: p2Y)
            //let p2=getClosestPointOnSafeArea(position_u: position_u, distance: p!.distance, dx: p!.dx, dy: p!.dy, w_distance_from_safe_area_limit: link_of_e!.radiusOfSafeArea*percentage)//p’ is the point on semiline pp_u with distance w from p. // Questo non è spiegato.
            //d = distance(p_u,p2)
            //let d = distanceBetweenTwoPoints2D(p1x: position_u.px, p1y: position_u.py, p2x: p2.p2x, p2y: p2.p2y)
            let d = distanceBetweenTwoPoints2D(p1x: position_u.px, p1y: position_u.py, p2x: p!.x_point, p2y: p!.y_point)
            if( result==nil || d < distance_result){ // take the point at less distance
                result = link_of_e!
                distance_result = d
            } // end if
        } // end for
        return result!
    }

    func checkIfUserIsEnteredAtLeastPercentageOfRadius(distance: Float, radius: Float, percentage: Float) -> Bool {
        return distance > radius*percentage
    }
}
