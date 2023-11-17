//
//  ViewController.swift
//  STTN
//
//  Created by OS Programming on 29/05/23.
//

import UIKit
import SceneKit
import ARKit
import RealityKit


class InitialViewController: UIViewController, ARSessionDelegate{
    
    //@IBOutlet var sceneView: ARSCNView!
    @IBOutlet var arView: ARView!
    private var startBool: Bool = false
    
    public var level4:Level4 = Level4()
  
    // SET VERSION
    public var version_setup = "basic" // it can change to "advanced"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupARConfiguration()
        
    }
    
    @IBAction func start(_ sender: Any) {
        if self.startBool==false{
            startTest()
        }
    }
    
    func startTest(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.startBool = true
            //let vc = UIStoryboard.init(name: "Main", bundle:nil).instantiateViewController(withIdentifier: "test") as? ViewController
            //self.navigationController?.pushViewController(vc!, animated: true)
            
            guard let storyboard = self.storyboard?.instantiateViewController(withIdentifier: "test") as? ViewController else {
                print("fail")
                return
            }
            
            self.navigationController?.pushViewController(storyboard, animated: true)
            
            //self.performSegue(withIdentifier: "ViewController", sender: self)
            
            //let secondViewController:ViewController = ViewController()
            //self.present(secondViewController, animated: true, completion: nil)
        }
    }
 
    
    func setupARConfiguration(){
        let configuration = ARWorldTrackingConfiguration()
        Toast.show(message:  "World Tracking Config", bgColor: UIColor.blue, textColor: .white,labelFont: .boldSystemFont(ofSize: 14),showIn: .bottom,controller: self)
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.maximumNumberOfTrackedImages = 1
        guard let arReferenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            print("Any Resource file has been detected")
            return}
        configuration.detectionImages=arReferenceImages
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh){
            configuration.sceneReconstruction = .mesh
        }
        self.arView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        self.arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        self.arView.session.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupARConfiguration()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.arView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
    
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        // fixing position mechanism
        guard let imgAnchor = anchors.first as? ARImageAnchor else {return}
       
        if imgAnchor.name=="switch"{
            if version_setup == "basic" {
                version_setup = "advanced"
                let setup_message : String = "advance VERSION"
                Toast.show(message: setup_message, bgColor: UIColor.yellow, textColor: .black,labelFont: .boldSystemFont(ofSize: 14),showIn: .top,controller: self)
                level4.feedback("A")
            } else if version_setup == "advanced"{
                version_setup = "basic"
                let setup_message : String = "basic VERSION"
                Toast.show(message: setup_message, bgColor: UIColor.yellow, textColor: .black,labelFont: .boldSystemFont(ofSize: 14),showIn: .top,controller: self)
                level4.feedback("B")
            }
        } else if imgAnchor.name=="Prova" {
            startTest()
            print("start")
        } else {
            //self.sceneView.session.remove(anchor: imgAnchor)
            self.arView.session.remove(anchor: imgAnchor)
        }
        
        
        if imgAnchor.name == "basic" {
                version_setup = "advanced"
                let setup_message : String = "advance VERSION"
                Toast.show(message: setup_message, bgColor: UIColor.yellow, textColor: .black,labelFont: .boldSystemFont(ofSize: 14),showIn: .top,controller: self)
                level4.feedback("A")
        } else if imgAnchor.name == "advanced"{
                version_setup = "basic"
                let setup_message : String = "basic VERSION"
                Toast.show(message: setup_message, bgColor: UIColor.yellow, textColor: .black,labelFont: .boldSystemFont(ofSize: 14),showIn: .top,controller: self)
                level4.feedback("B")
        }
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // frame
    }
    
    
    
}
