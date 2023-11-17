//
//  Render.swift
//  STTN
//
//  Created by OS Programming on 18/09/2023.
//

import SceneKit
import ARKit
import RealityKit
import Foundation

class Render {
    
    var targetEntity = AnchorEntity()
    var targetSpherex:Float = 0.0
    var targetSpherez:Float = 0.0
    let model_03: ModelEntity = ModelEntity(mesh: .generateSphere(radius: 0.08))
    
    let virtualSphere_radius : Float = 0.15
    //var circleEntity = AnchorEntity()
    //let model_04: ModelEntity = ModelEntity(mesh: .generateSphere(radius: 0.08))
    
    
    func createVirtualSphere(sphere_radius:CGFloat, x:Float, z:Float, red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)-> SCNNode{
        let sphereNode = SCNNode(geometry: SCNSphere(radius: sphere_radius))
        sphereNode.position = SCNVector3(x,0,z)
        sphereNode.geometry?.firstMaterial?.diffuse.contents  = UIColor(red: red, green: green, blue: blue, alpha: alpha)
        return sphereNode
    }
    
    // AR SESSION DELEGATE METHODS
    func renderText(_ string: String, _ x: Float, _ z: Float, color: UIColor, heightmore: Float? = nil, arView: ARView) {
        let anchor = AnchorEntity()
        let text = MeshResource.generateText(
            string,
            extrusionDepth: 0.08,
            font: .systemFont(ofSize: 0.5, weight: .bold)
        )
        let shader = SimpleMaterial(color: color, roughness: 4, isMetallic: true)
        let textEntity = ModelEntity(mesh: text, materials: [shader])
        textEntity.position.x = x
        textEntity.position.y = 0.2 + (heightmore ?? 0.0)
        textEntity.position.z = z
        textEntity.setOrientation(.init(angle: -3, axis: [0,1,0]), relativeTo: nil)
        textEntity.setParent(anchor)
        arView.scene.addAnchor(anchor)
    }
    
    func renderNodeVirtualSpheres(position_vertexes: [String : [String: Float]], arView: ARView) {
        // NODES VISUALLY
        print("ENTRO")
        print("position_vertexes",position_vertexes)
        for index in 1...position_vertexes.count {
            print(index)
            let sphere_radius: CGFloat = 0.1
            let pathSphere = position_vertexes["\(index-1)"]
            let x = pathSphere!["x"]!
            let z = -pathSphere!["y"]!
            let red: CGFloat = 30.0 / 255.0
            let green: CGFloat = 90.0 / 255.0
            let blue: CGFloat = 240.0 / 255.0
            let alpha: CGFloat = 0.8
            let sphereNode = createVirtualSphere(sphere_radius:sphere_radius, x:x, z:z, red: red, green: green, blue: blue, alpha: alpha)
            var nodeEntity = AnchorEntity()
            let model_02 = ModelEntity(mesh: .generateSphere(radius: virtualSphere_radius))
            let material = SimpleMaterial(color: .blue, isMetallic: false)
            model_02.model?.materials = [material]
            model_02.position = SIMD3<Float>(x, 0, z)
            nodeEntity.addChild(model_02)
            arView.scene.anchors.append(nodeEntity)
            
            renderText("\(index-1)", x, z, color: UIColor.blue, arView: arView)
        }
    }
    
    func renderDestinationVirtualSphere(destination_position: [String: Float], arView: ARView) {
        // DESTINATION
        let destinationSpherex = destination_position["x"]!
        let destinationSpherez = -destination_position["y"]!
        let red: CGFloat = 250.0 / 255.0
        let green: CGFloat = 90.0 / 255.0
        let blue: CGFloat = 40.0 / 255.0
        let alpha: CGFloat = 0.8
        let sphere_radius: CGFloat = 0.1
        let sphereDestination = createVirtualSphere(sphere_radius:sphere_radius, x:destinationSpherex, z:destinationSpherez, red: red, green: green, blue: blue, alpha: alpha)
        var destinationEntity = AnchorEntity()
        let model_01 = ModelEntity(mesh: .generateSphere(radius: virtualSphere_radius))
        let material = SimpleMaterial(color: .red, isMetallic: false)
        model_01.model?.materials = [material]
        model_01.position = SIMD3<Float>(destinationSpherex, 0, destinationSpherez)
        destinationEntity.addChild(model_01)
        arView.scene.anchors.append(destinationEntity)
        
        renderText("Dest", destinationSpherex, destinationSpherez, color: UIColor.red, arView: arView)
    }
    
    func renderVirtualSphere(entity: AnchorEntity, modelN: ModelEntity, position_sphere: [String: Float], distance: Float? = nil, arView: ARView) {
        // DESTINATION
        let spherex = position_sphere["x"]!
        let spherez = -position_sphere["y"]!
        let red: CGFloat = 90.0 / 255.0
        let green: CGFloat = 250.0 / 255.0
        let blue: CGFloat = 40.0 / 255.0
        let alpha: CGFloat = 0.8
        let sphere_radius: CGFloat = 0.1
        let material = SimpleMaterial(color: .green, isMetallic: false)
        modelN.model?.materials = [material]
        modelN.position = SIMD3<Float>(spherex, 0, spherez)
        entity.addChild(modelN)
        arView.scene.anchors.append(entity)
    }
    
    func renderTarget(x: Float, y: Float, arView: ARView) {
        // DEBUG VIRTUAL SPHERE
        
        /*targetSpherex = target_x_map
         targetSpherez = target_y_map*/
        
        targetEntity.removeFromParent()
        targetSpherex = x
        targetSpherez = y
        targetEntity.position = SIMD3<Float>(targetSpherex, 0, -targetSpherez)
        targetEntity.addChild(model_03)
        arView.scene.anchors.append(targetEntity)
        
    }
}
