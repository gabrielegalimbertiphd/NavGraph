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
import SwiftGraph
import Foundation
import PositioningLibrary
import MapKit
import Drops
import CoreBluetooth

/*struct Link {
    var node_u : String
    var node_v : String
    var widthOfSafeArea : Float = 1.0
}*/

// TODO: JSON vertexes [position_vertexes{x,y,yaw}]  links [{u,v,widthOfSafeAreaBySide}] markers[{marker,x,y,yaw}]
// put destination settable on the links and radius with check
// put possibility to insert

// TODO: split the concepts radius*percentage and width


// class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, LocationObserver  {
class TestViewController: UIViewController, LocationObserver, CBPeripheralDelegate, CBCentralManagerDelegate, ARSessionDelegate{
    
    // location provider
    private var locationProvider: LocationProvider!
    
    // JSON reader
    private var customJsonParser: CustomJsonParser!
    private var markers : [Marker] = []
    
    // Core Bluetooth instances
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!

    //@IBOutlet var sceneView: ARSCNView!
    @IBOutlet var arView: ARView!
    private var startBool: Bool = false
    private var startLog: Bool = false
    private var graphbased: Bool = true
    private var bubble_placed: Bool = true
    private var isStarted:Bool = false
    
    // MAP TEST FLOOR 4
    // MARK: OFFICIAL REFACTORED
    
    public var vertexes : [String] = ["0", "1", "2", "3", "4", "5", "6", "7","8"]
    public var graph: WeightedGraph<String, Int> = WeightedGraph<String, Int>(vertices: ["0", "1", "2", "3", "4", "5", "6", "7","8"])
    
    public var position_vertexes : [String : [String: Float]] =
    [
        "0":["x":0.8,"y":-0.8],
        "1":["x":12.0,"y":-0.8],
        "2":["x":12.0,"y":-22.50],
        "3":["x":0.8,"y":-20.22],
        "4":["x":8.8,"y":-22.50],
        "5":["x":2.62,"y":-20.22],
        "6":["x":2.62,"y":-28.8],
        "7":["x":8.8,"y":-28.8],
        "8":["x":6,"y":-20.22]
    ]
    
    //["0":["x":0.0,"y":-0.0],"1":["x":11.4,"y":-0.0],"2":["x":11.4,"y":-21.70],"3":["x":0.0,"y":-19.52],"4":["x":8,"y":-21.70],"5":["x":2.02,"y":-19.52],"6":["x":2.02,"y":-28.8],"7":["x":7.9,"y":-28.8]] // express in 2D x = x_arkit, y = -z_arkit
    
    //public var position_markers : [String : [String: Float]] = ["M0":["x":0.0,"y":-0.8,"yaw":0],"M5":["x":10.8,"y":-1.6,"yaw":180]] // x = x_arkit, y = -z_arkit
    /* [
     "M0":["x":0.0,"y":0.0],
     "M1":["x":12.3,"y":0.0],
     "M2":["x":-11.4,"y":22.7],
     "M3":["x":-0.0,"y":20.32],
     "M4":["x":-7.2,"y":22.32],
     "M5":["x":10,"y":-1.6],
     "M6":["x":-1.32,"y":29.62],
     "M7":["x":-6.9,"y":29.62]
     ] // marcatori, x , y
     */
    
    
    public var destination_position : [String: Float] = ["x_d": 5.6, "y_d": -28.8] // near node 7 // init at 0,0
    public var radius_destination : Float = 1.0// raggio della destinazione
    
    var links: [Link] = [
        Link( node_u :"0", node_v :"1", radiusOfSafeArea :1.0),
        Link( node_u :"0", node_v :"3", radiusOfSafeArea :1.0),
        Link( node_u :"3", node_v :"5", radiusOfSafeArea :1.0),
        Link( node_u :"1", node_v :"2", radiusOfSafeArea :1.0),
        Link( node_u :"2", node_v :"4", radiusOfSafeArea :1.0),
        Link( node_u :"5", node_v :"6", radiusOfSafeArea :1.0),
        Link( node_u :"4", node_v :"7", radiusOfSafeArea :1.0),
        Link( node_u :"6", node_v :"7", radiusOfSafeArea :1.0),
        Link( node_u :"5", node_v :"8", radiusOfSafeArea :1.0) // Link for DEBUG
    ]
    
    
    private let resolution: Float = 100.0
    public var fixedWidthSafeArea: [Float] = [2.0, 1.0, 2.0, 1.0, 2.0, 1.0, 2.0, 2.0, 1.0]
    private var evaluation_pose_frequency:Double = 20.0
    
    var angtarget:String = ""
    var distTarget:String = ""
    
    var percentage: Float = 0.4
    var distance : Float = 0.0
    var range : Float = 30.0
    
    public var timerRepeatInstruction: Double = 0.0
    
    // check movement of the user while the instruction is given
    var movement : Float = 0.0
    var previous_currentX_map : Float = 0.0
    var previous_currentY_map : Float = 0.0
    var position_X_of_turn_map : Float = 0.0
    var position_Y_of_turn_map : Float = 0.0
    
    var numMarker : Int = 0
    var whichMarkerWereDetected : String = ""
    
    private var state:String = "inside"
    private var message:String = "walk"
    
    public var nextNode : String = "0"
    public var lastNode : String = ""
    public var route : [String] = []
    
    public var E_u : [any Edge] = []
    public var E_d : [any Edge] = []
    
    public var saidArrived : Bool = false
    
    public var repeat_pose_evaluation : Bool = true
    
    public var repeatInstructionFlag : Bool = false // TODO: configure botton!
    
    public var changeNode : Bool = false // if the node change the software must repeat the instruction.
    public var changePath : Bool = false // until the subpath is contained into the path of the route, else the path is change and the variable becomes true
    public var previous_node: String = "0"
    
    /*var E_u : [any Edge] = []
    //print(E_u)
    // GET DESTINATION EDGE
    var E_d : [any Edge] = []
    var num_shared_edges_user_destination: Int = 0*/
    
    // DEBUG LABELS ON VIDEO
    lazy var debug_dx_dy_point_of_return = UILabel()
    lazy var debug_point_of_return = UILabel()
    lazy var targetAngleLabel = UILabel()
    lazy var inside_outside = UILabel()
    lazy var user_edges = UILabel()
    lazy var state_user = UILabel()
    lazy var nextTargetLabel = UILabel()
    lazy var lastNodeLabel = UILabel()
    lazy var routeLabel = UILabel()
    lazy var numMarkersLabel = UILabel()
    lazy var markerNameLabel = UILabel()
    
    lazy var x_user = UILabel()
    lazy var y_user = UILabel()
    lazy var z_user = UILabel()
    
    lazy var level4debug = UILabel()
    
    lazy var roll_user = UILabel()
    lazy var yaw_user = UILabel()
    lazy var pitch_user = UILabel()
    
    lazy var x_fixing_gap_marker = UILabel()
    lazy var y_fixing_gap_marker = UILabel()
    
    lazy var x_fixing_gap_user = UILabel()
    lazy var y_fixing_gap_user = UILabel()
    
    lazy var message_label = UILabel()
    lazy var previous_message_label = UILabel()
    
    lazy var angular_error_label = UILabel()
    lazy var distance_from_next_target_label = UILabel()
    
    lazy var DEBUGANGLE = UILabel()
    lazy var DEBUGX = UILabel()
    lazy var DEBUGY = UILabel()
    lazy var JUMPDEBUG = UILabel()
    lazy var movementLabel = UILabel()
    
    lazy var beta = UILabel()
    lazy var timerLabel = UILabel()
    
    lazy var anglePathLabel = UILabel()
    lazy var directionLabel = UILabel()
    
    // DEBUG BUBBLE
    var targetSpherex:Float = 0.0
    var targetSpherez:Float = 0.0
    //let sphereTarget = SCNNode(geometry: SCNSphere(radius: 0.08))
    var targetEntity = AnchorEntity()
    let model_03: ModelEntity = ModelEntity(mesh: .generateSphere(radius: 0.08))
    var circleEntity = AnchorEntity()
    let model_04: ModelEntity = ModelEntity(mesh: .generateSphere(radius: 0.08))
    
    // TARGET X Y
    public var target_x_map:Float=0.0
    public var target_y_map:Float=0.0
    public var x_return_map:Float=0.0
    public var y_return_map:Float=0.0
    public var target_on_edge_description:String = ""
    
    // FIX POSITION
    public var x_fixing_gap_map:Float = 0.0
    public var y_fixing_gap_map:Float = 0.0
    
    public var finalTransform:simd_float4x4 = simd_float4x4([1,0,0,0],[0,1,0,0],[0,0,1,0],[0,0,0,1])
    
    // rototranslate the origin of axes
    let rotationXMatrix_arkit = simd_float4x4([1,0,0,0],[0,cos(Float.pi/2),-sin(Float.pi/2),0],[0,sin(Float.pi/2),cos(Float.pi/2),0],[0,0,0,1])
    
    public var lastEdge:String? = nil
    
    public var level1:Level1? = nil
    public var level2:Level2 = Level2()
    public var level3:Level3 = Level3()
    public var level4:Level4 = Level4()
    
    // LOG
    private var log : Log = Log()
    
    // SET VERSION
    public var version_setup = "basic" // it can change to "advanced"
    public var closest_edge:Link? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if version_setup=="advanced"{
            for i in 1...links.count{
                print("Before: link \(i-1) = \(links[i-1])")
                if i<fixedWidthSafeArea.count{
                    links[i-1].radiusOfSafeArea = fixedWidthSafeArea[i-1]  // TODO: Thread 1: Fatal error: Index out of range
                }
                print("After:  link \(i-1) = \(links[i-1])")
             }
             
        }
        
        level1 = Level1(listOfVertexesCoordinates: position_vertexes, destination_position: destination_position, radius_destination: radius_destination, links: links, vertexes: vertexes)
        
        print(level1!.graph)
        
        // CREATE THE AR SESSION
        /*
        // Set the view's delegate
        sceneView.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.maximumNumberOfTrackedImages = 1
        guard let arReferenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil)else{
            print("Any Resource file has been detected")
            return}
        configuration.detectionImages=arReferenceImages
        // Run the view's session
        sceneView.session.run(configuration)
         */
        // Set the view's delegate
        //self.arView.session.delegate = self
        // Create a session configuration
        /*let configuration = ARWorldTrackingConfiguration()
        configuration.maximumNumberOfTrackedImages = 1
        guard let arReferenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil)else{
            print("Any Resource file has been detected")
            return}
        configuration.detectionImages=arReferenceImages
        // Run the view's session
        self.arView.session.run(configuration)*/
        
        setupARConfiguration()
        
        // LOCATION PROVIDER
        //self.locationProvider = LocationProvider(arView: arView, jsonName: "test")
        
        // Bluetooth
        //centralManager = CBCentralManager(delegate: self, queue: nil)
        
        // DEBUG STATE AND NEXTNODE
        debug_dx_dy_point_of_return.frame = CGRect(x: 10, y: 0, width: 300, height: 100)
        debug_dx_dy_point_of_return.text = "dx: dy:"
        debug_dx_dy_point_of_return.textColor = UIColor.black
        view.addSubview(debug_dx_dy_point_of_return)
        
        debug_point_of_return.frame = CGRect(x: 10, y: 0, width: 300, height: 150)
        debug_point_of_return.text = "t_x: t_y:"
        debug_point_of_return.textColor = UIColor.black
        view.addSubview(debug_point_of_return)
        
        targetAngleLabel.frame = CGRect(x: 240, y: 0, width: 300, height: 200)
        targetAngleLabel.text = "Target Angle"
        targetAngleLabel.textColor = UIColor.red
        view.addSubview(targetAngleLabel)
        
        inside_outside.frame = CGRect(x: 10, y: 0, width: 300, height: 200)
        inside_outside.text = "I/O: "
        inside_outside.textColor = UIColor.black
        view.addSubview(inside_outside)
        
        user_edges.frame = CGRect(x: 10, y: 0, width: 300, height: 250)
        user_edges.text = "E_u: "
        user_edges.textColor = UIColor.black
        view.addSubview(user_edges)
        
        state_user.frame = CGRect(x: 10, y: 0, width: 300, height: 300)
        state_user.text = "State"
        state_user.textColor = UIColor.black
        view.addSubview(state_user)
        
        nextTargetLabel.frame = CGRect(x: 10, y: 0, width: 300, height: 350)
        nextTargetLabel.text = "NextNode"
        nextTargetLabel.textColor = UIColor.black
        view.addSubview(nextTargetLabel)
        
        lastNodeLabel.frame = CGRect(x: 10, y: 0, width: 300, height: 400)
        lastNodeLabel.text = "LastNode"
        lastNodeLabel.textColor = UIColor.green
        view.addSubview(lastNodeLabel)
        
        routeLabel.frame = CGRect(x: 10, y: 0, width: 300, height: 450)
        routeLabel.text = "Route"
        routeLabel.textColor = UIColor.green
        view.addSubview(routeLabel)
        
        anglePathLabel.frame = CGRect(x: 240, y: 0, width: 300, height: 300)
        anglePathLabel.text = "Angle Path"
        anglePathLabel.textColor = UIColor.red
        view.addSubview(anglePathLabel)
        
        directionLabel.frame = CGRect(x: 240, y: 0, width: 300, height: 350)
        directionLabel.text = "Dir: "
        directionLabel.textColor = UIColor.red
        view.addSubview(directionLabel)
    
        // DEBUG X Y Z MAP
        x_user.frame = CGRect(x: 10, y: 0, width: 300, height: 500)
        x_user.text = "X USER"
        x_user.textColor = UIColor.black
        view.addSubview(x_user)
        
        y_user.frame = CGRect(x: 10, y: 0, width: 300, height: 550)
        y_user.text = "Y USER"
        y_user.textColor = UIColor.black
        view.addSubview(y_user)
        
        z_user.frame = CGRect(x: 10, y: 0, width: 300, height: 600)
        z_user.text = "Z USER"
        z_user.textColor = UIColor.black
        view.addSubview(z_user)
        
        // LEVEL 4 DEBUG
        level4debug.frame = CGRect(x: 240, y: 0, width: 300, height: 450)
        level4debug.text = "LV4 DEBUG"
        level4debug.textColor = UIColor.blue
        view.addSubview(level4debug)
        
        // DEBUG ROLL YAW PITCH ARKIT
        roll_user.frame = CGRect(x: 240, y: 0, width: 300, height: 500)
        roll_user.text = "ROLL USER"
        roll_user.textColor = UIColor.black
        view.addSubview(roll_user)
        
        // MARK: IMPORTANT
        yaw_user.frame = CGRect(x: 240, y: 0, width: 300, height: 550)
        yaw_user.text = "YAW USER"
        yaw_user.textColor = UIColor.red
        view.addSubview(yaw_user)
        
        pitch_user.frame = CGRect(x: 240, y: 0, width: 300, height: 600)
        pitch_user.text = "PITCH USER"
        pitch_user.textColor = UIColor.black
        view.addSubview(pitch_user)
        
        /*x_fixing_gap_user.frame = CGRect(x: 10, y: 0, width: 300, height: 660)
        x_fixing_gap_user.text = "X GAP U"
        x_fixing_gap_user.textColor = UIColor.blue
        view.addSubview(x_fixing_gap_user)
        
        y_fixing_gap_user.frame = CGRect(x: 10, y: 0, width: 300, height: 710)
        y_fixing_gap_user.text = "Y GAP U"
        y_fixing_gap_user.textColor = UIColor.blue
        view.addSubview(y_fixing_gap_user)
        
        x_fixing_gap_marker.frame = CGRect(x: 240, y: 0, width: 300, height: 660)
        x_fixing_gap_marker.text = "X GAP IMG"
        x_fixing_gap_marker.textColor = UIColor.blue
        view.addSubview(x_fixing_gap_marker)
        
        y_fixing_gap_marker.frame = CGRect(x: 240, y: 0, width: 300, height: 710)
        y_fixing_gap_marker.text = "Y GAP IMG"
        y_fixing_gap_marker.textColor = UIColor.blue
        view.addSubview(y_fixing_gap_marker)*/
        
        message_label.frame = CGRect(x: 10, y: 0, width: 300, height: 750)
        message_label.text = "message"
        message_label.textColor = UIColor.black
        view.addSubview(message_label)
        
        previous_message_label.frame = CGRect(x: 10, y: 0, width: 300, height: 800)
        previous_message_label.text = "previous message"
        previous_message_label.textColor = UIColor.black
        view.addSubview(previous_message_label)
        
        angular_error_label.frame = CGRect(x: 240, y: 0, width: 300, height: 750)
        angular_error_label.text = "angular error"
        angular_error_label.textColor = UIColor.red
        view.addSubview(angular_error_label)
        
        distance_from_next_target_label.frame = CGRect(x: 240, y: 0, width: 300, height: 800)
        distance_from_next_target_label.text = "distance next target"
        distance_from_next_target_label.textColor = UIColor.black
        view.addSubview(distance_from_next_target_label)
        
        DEBUGANGLE.frame = CGRect(x: 10, y: 0, width: 300, height: 850)
        DEBUGANGLE.text = "diff yaw"
        DEBUGANGLE.textColor = UIColor.black
        view.addSubview(DEBUGANGLE)
        
        DEBUGX.frame = CGRect(x: 240, y: 0, width: 300, height: 900)
        DEBUGX.text = "deb a"
        DEBUGX.textColor = UIColor.black
        view.addSubview(DEBUGX)
        
        DEBUGY.frame = CGRect(x: 240, y: 0, width: 300, height: 950)
        DEBUGY.text = "deb b"
        DEBUGY.textColor = UIColor.black
        view.addSubview(DEBUGY)
        
        JUMPDEBUG.frame = CGRect(x: 240, y: 0, width: 300, height: 1000)
        JUMPDEBUG.text = "deb c"
        JUMPDEBUG.textColor = UIColor.black
        view.addSubview(JUMPDEBUG)
        
        beta.frame = CGRect(x: 240, y: 0, width: 300, height: 1050)
        beta.text = "beta"
        beta.textColor = UIColor.black
        view.addSubview(beta)
        
        timerLabel.frame = CGRect(x: 240, y: 0, width: 300, height: 1100)
        timerLabel.text = "timer: "
        timerLabel.textColor = UIColor.blue
        view.addSubview(timerLabel)
        
        movementLabel.frame = CGRect(x: 240, y: 0, width: 300, height: 1150)
        movementLabel.text = "Move:"
        movementLabel.textColor = UIColor.black
        view.addSubview(movementLabel)
        
        // MARKERS
        numMarkersLabel.frame = CGRect(x: 240, y: 0, width: 300, height: 1400)
        numMarkersLabel.text = "# Mark: "
        numMarkersLabel.textColor = UIColor.black
        view.addSubview(numMarkersLabel)
        
        markerNameLabel.frame = CGRect(x: 240, y: 0, width: 300, height: 1450)
        markerNameLabel.text = "Mark names: "
        markerNameLabel.textColor = UIColor.black
        view.addSubview(markerNameLabel)
        
        
        //Map floor4SKERI = readJSONFile(forName name: "floor4SKERI")
       /* var name : String = "floor4SKERI"
        guard let sourcesURL = Bundle.main.url(forResource: name, withExtension: "json") else {
            fatalError("file json not founded")
        }
        guard let mapData = try! Data(contentsOf: sourcesURL) else {
            fatalError("could not convert data")
        }
        let decoder = JSONDecoder()
        guard let*/
    }
    
    @IBAction func start(_ sender: Any) {
        startTest()
    }
    
    func startTest(){
        guard level1 != nil else{
            Toast.show(message:  "Choose a map", bgColor: UIColor.red, textColor: .white,labelFont: .boldSystemFont(ofSize: 14),showIn: .top,controller: self)
            return
        }
        
        guard startBool==false || isStarted==false else{
            Toast.show(message:  "Already started.\n Show stop marker to stop", bgColor: UIColor.red, textColor: .white,labelFont: .boldSystemFont(ofSize: 14),showIn: .top,controller: self)
            return
        }
        
        Toast.show(message: "START SESSION", bgColor: UIColor.yellow, textColor: .red,labelFont: .boldSystemFont(ofSize: 10),showIn: .top,controller: self)
        
        setupARConfiguration()
        
        /*self.locationProvider = LocationProvider(arView: arView, jsonName: "test")
        self.locationProvider.addLocationObserver(locationObserver: self)
        self.locationProvider.start()
        self.locationProvider.showFloorMap(CGRect(x: 5, y: 450, width: 230, height: 360)) //223))*/
        
        self.locationProvider = LocationProvider(arView: arView, jsonName: "test")
        self.locationProvider.startFollowUser()
        self.locationProvider.addLocationObserver(locationObserver: self)
        self.locationProvider.start()
        self.locationProvider.showFloorMap(CGRect(x: 5, y: 450, width: 230, height: 360))
        
        customJsonParser = CustomJsonParser(forName: "test")
        markers = customJsonParser.getMarkers()
        print(markers)
        for k in markers {
            print(k.id,k.location.coordinates.x,k.location.coordinates.y)
        }
        
        closest_edge = links.first
        
        //createDirectory(self.log.sessionName) // TODO: insert and check directory creation.
        
        level4.speak(message: "Session Started",state: "",changeNode: changeNode, changePath: changePath, repeatInstructionFlag: repeatInstructionFlag)
        
        bubble_placed = true
        
        isStarted = false
        if bubble_placed {
            renderNodeVirtualSpheres(position_vertexes: position_vertexes)
            renderDestinationVirtualSphere(destination_position: destination_position)
            // renderLinkLines(position_vertexes: position_vertexes, links: links) // TODO: It doesn't work
            bubble_placed = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.startLog = true
            self.startBool = true
        }
    }
    
    func resetTest(){
        
    }
    
    func onLocationUpdate(_ newLocation: ApproxLocation) {

        var currentX_map = Float(newLocation.coordinates.x)
        var currentY_map = Float(newLocation.coordinates.y)
        var currentYAW = Float(newLocation.heading)
        
        debugPose(currentX_map, currentY_map, 0, 0, currentYAW, 0, 100)
        
        evaluatePose(newLocation: newLocation)
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
    
    func createVirtualSphere(sphere_radius:CGFloat, x:Float, z:Float, red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)-> SCNNode{
        let sphereNode = SCNNode(geometry: SCNSphere(radius: sphere_radius))
        sphereNode.position = SCNVector3(x,0,z)
        sphereNode.geometry?.firstMaterial?.diffuse.contents  = UIColor(red: red, green: green, blue: blue, alpha: alpha)
        return sphereNode
    }
    
    // AR SESSION DELEGATE METHODS
    fileprivate func renderText(_ string: String, _ x: Float, _ z: Float, color: UIColor, heightmore: Float? = nil) {
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
        self.arView.scene.addAnchor(anchor)
    }
    
    fileprivate func renderNodeVirtualSpheres(position_vertexes: [String : [String: Float]]) {
        // NODES VISUALLY
        for index in 1...position_vertexes.count {
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
            let model_02 = ModelEntity(mesh: .generateSphere(radius: 0.1))
            let material = SimpleMaterial(color: .blue, isMetallic: false)
            model_02.model?.materials = [material]
            model_02.position = SIMD3<Float>(x, 0, z)
            nodeEntity.addChild(model_02)
            self.arView.scene.anchors.append(nodeEntity)
            
            renderText("\(index-1)", x, z, color: UIColor.blue)
        }
    }
    
    fileprivate func renderDestinationVirtualSphere(destination_position: [String: Float]) {
        // DESTINATION
        let destinationSpherex = destination_position["x_d"]!
        let destinationSpherez = -destination_position["y_d"]!
        let red: CGFloat = 250.0 / 255.0
        let green: CGFloat = 90.0 / 255.0
        let blue: CGFloat = 40.0 / 255.0
        let alpha: CGFloat = 0.8
        let sphere_radius: CGFloat = 0.1
        let sphereDestination = createVirtualSphere(sphere_radius:sphere_radius, x:destinationSpherex, z:destinationSpherez, red: red, green: green, blue: blue, alpha: alpha)
        var destinationEntity = AnchorEntity()
        let model_01 = ModelEntity(mesh: .generateSphere(radius: 0.1))
        let material = SimpleMaterial(color: .red, isMetallic: false)
        model_01.model?.materials = [material]
        model_01.position = SIMD3<Float>(destinationSpherex, 0, destinationSpherez)
        destinationEntity.addChild(model_01)
        self.arView.scene.anchors.append(destinationEntity)
        
        renderText("Dest", destinationSpherex, destinationSpherez, color: UIColor.red)
    }
    
    fileprivate func renderVirtualSphere(entity: AnchorEntity, modelN: ModelEntity, position_sphere: [String: Float], distance: Float? = nil) {
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
        self.arView.scene.anchors.append(entity)
        
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        // fixing position mechanism
        guard let imgAnchor = anchors.first as? ARImageAnchor else {return}
        //numMarker += 1
        whichMarkerWereDetected = "\(imgAnchor.name), \(whichMarkerWereDetected)"
        numMarkersLabel.text = "Prova : \(numMarker)"
        markerNameLabel.text = whichMarkerWereDetected
        if startBool {
            print("didadd")
        
            Toast.show(message:  "UPDATE \(imgAnchor.name)", bgColor: UIColor.blue, textColor: .white,labelFont: .boldSystemFont(ofSize: 10),showIn: .top,controller: self)
        
        } else if imgAnchor.name=="switch"{
            /*if version_setup == "basic" {
                version_setup = "advanced"
                let setup_message : String = "advance VERSION"
                Toast.show(message: setup_message, bgColor: UIColor.yellow, textColor: .black,labelFont: .boldSystemFont(ofSize: 14),showIn: .top,controller: self)
                level4.feedback(setup_message)
            }*/
            resetTest()
        } else if imgAnchor.name=="prova" {
            startTest()
        } else {
            //self.sceneView.session.remove(anchor: imgAnchor)
            self.arView.session.remove(anchor: imgAnchor)
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let imgAnchor = anchors.first as? ARImageAnchor else {return}
        if startBool {
            print("didupdate")
            if imgAnchor.name! != "M0" {
                //poseFixing(imgAnchor)
            }
        } else {
            self.arView.session.remove(anchor: imgAnchor)
        }
        
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // frame
    }
    
    func distanceBetweenTwoPoints2D(p1x:Float, p1y:Float, p2x:Float, p2y:Float)->Float{
        return sqrt(pow(p1x-p2x, 2)+pow(p1y-p2y, 2))
    }
    
    func distanceBetweenTwoPoints2D(p_u:(pux:Float, puy:Float),p_d:( pdx:Float, pdy:Float))->Float{
        return sqrt(pow(p_u.pux-p_d.pdx, 2)+pow(p_u.puy-p_d.pdy, 2))
    }
    
    // MARK: LOG DATA AFTER CLICK
    @IBAction func saveDataLog(_ sender: Any) {
        saveData()
    }
    
    func saveData(){
        log.file = "prova_\(NSDate().timeIntervalSince1970).txt"
        log.destinationReached(exit_from_app: repeat_pose_evaluation)
        Toast.show(message: "Data Saved", bgColor: UIColor.white, textColor: .red, labelFont: .boldSystemFont(ofSize: 14), showIn: .top, controller: self)
    }
    
    
    /*fileprivate func checkIfUserIsEnteredAtLeastPercentageOfRadius(distance: Float, radius: Float, percentage: Float) -> Bool {
        return distance>radius*percentage
    }*/
    
    func outputLevel2(currentX: Float, currentY: Float, previous_state: String, edges_user: inout [any Edge], edges_destination: inout [any Edge] , num_shared_edges_user_destination: Int){
        // GET USER EDGE
        
        if edges_user.count != 0 { // there's the need to find the width of the closest edge everytime to understand if the user is entered enough. This is because the width of the edge can change from a setup version (based and advanced). one code for both cases.
            closest_edge = level2.getClosestEdge(position_u: (px:currentX,py:currentY), edges: edges_user, percentage: percentage, position_vertexes: level1!.position_vertexes, links: links)
        }
        
        // IN TEORIA FUNZIONA!
        
        var flag : Bool = false
        if edges_user.count != 0 || num_shared_edges_user_destination == 1 {
            for edge in edges_user {
                let vertex_u = position_vertexes["\(edge.u)"]!
                let vertex_v = position_vertexes["\(edge.v)"]!
                let p1X:Float = vertex_u["x"] ?? 0
                let p1Y:Float = vertex_u["y"] ?? 0
                let p2X:Float = vertex_v["x"] ?? 0
                let p2Y:Float = vertex_v["y"] ?? 0
                let data = level2.getClosestPointOnEdge(position: (px:currentX,py:currentY), p1X: p1X, p1Y: p1Y, p2X: p2X, p2Y: p2Y)
                var k : Link? = level2.edgeToLink(links: links,edge: edge)
                if (data!.distance < k!.radiusOfSafeArea*percentage && distance > k!.radiusOfSafeArea*percentage && distance < k!.radiusOfSafeArea ) {
                    flag = true
                }
            }
        }
        
        if flag {
            print("ENTER HERE")
            flag=false
            // MARK: TARGET REMAIN THE SAME
            if nextNode != previous_node {
                changeNode = true
            } else {
                changeNode = false
            }
            previous_node = nextNode
            state = "inside"
            state_user.text=state
            nextTargetLabel.text = "T: \(nextNode)"
            inside_outside.text = "I/O: inside DEBUG POINT"
            debug_point_of_return.text = ""
        } else
        // LEVEL 2 EVALUATION OF STATE, ANGULAR ERROR, DISTANCE TO TARGET.
        if(edges_user.count==0 || (previous_state=="outside" && level2.checkIfUserIsEnteredAtLeastPercentageOfRadius(distance: abs(distance), radius: closest_edge!.radiusOfSafeArea, percentage: percentage))){
            print("if outside")
            (target_x_map, target_y_map, x_return_map, y_return_map, closest_edge) = level2.getClosestPointInSafeArea(position_u: (px:currentX,py:currentY), input_Graph: level1!.graph, percentage: percentage, position_vertexes: level1!.position_vertexes, links: links) // MARK: TARGET IS A POINT IN THE SAFE AREA OF THE CLOSEST EDGE THAT LEAD TO THE DESTINATION IN LESS TIME.
            var target_on_edge_description = "u=\(closest_edge!.node_u)-v=\(closest_edge!.node_v)"
            debug_point_of_return.text = "t_x: \(reduceResolution(value:target_x_map,100)) t_y: \(reduceResolution(value:target_y_map,100)) edge: \(target_on_edge_description)"
            state_user.text="OUTSIDE"
            nextTargetLabel.text="T: point on edge"
            state = "outside"
            inside_outside.text = "I/O: outside"
            
            beta.text = "b: \(reduceResolution(value: rad2degree(level2.beta), 1000)), 1000))"
        } else if(num_shared_edges_user_destination > 0){
            if (distanceBetweenTwoPoints2D(p1x: currentX, p1y: currentY, p2x: level1!.destination_position["x_d"]!, p2y: level1!.destination_position["y_d"]!) < level1!.radius_destination) {
                state = "arrived"
                state_user.text=state
                nextTargetLabel.text="T: arrived"
                inside_outside.text = "I/O: inside"
                debug_point_of_return.text = ""
                // MARK: NO TARGET
                nextNode="destination"
                if nextNode != previous_node {
                    changeNode = true
                } else {
                    changeNode = false
                }
                previous_node = nextNode
            }
            else {
                target_x_map = level1!.destination_position["x_d"]!
                target_y_map = level1!.destination_position["y_d"]! // MARK: TARGET IS THE DESTINATION
                state = "inside"
                state_user.text=state
                nextTargetLabel.text="T: destination"
                inside_outside.text = "I/O: inside near destination"
                debug_point_of_return.text = ""
            }
        } else {
            // PROCEDURE: Finding next node and the route
            // finding the next node
            // but this algorithm compute only the next node and not the route. For this reason the code check later which is the most close node in E_d that lead to the destination passing from the nextnode. the code then save the route from next node to last node
            var path_distances: [String: Float] = [:]
            var last_nodes: [String: String] = [:]
            for e_u in edges_user {
                var node1_user = level1!.position_vertexes["\(e_u.u)"]
                var distance_user_node1 = distanceBetweenTwoPoints2D(p1x:currentX, p1y:currentY, p2x:node1_user!["x"]!, p2y:node1_user!["y"]!)*100.0
                //print(distance_user_node1)
                var node2_user = level1!.position_vertexes["\(e_u.v)"]
                var distance_user_node2 = distanceBetweenTwoPoints2D(p1x:currentX, p1y:currentY, p2x:node2_user!["x"]!, p2y:node2_user!["y"]!)*100.0
                //print(distance_user_node2)
                
                for e_d in edges_destination {
                    
                    let node1_destination = level1!.position_vertexes["\(e_d.u)"]
                    let distance_destination_node1 = distanceBetweenTwoPoints2D(p1x:currentX, p1y:currentY, p2x:node1_destination!["x"]!, p2y:node1_destination!["y"]!)*100.0
                    //print(distance_destination_node1)
                    
                    let node2_destination = level1!.position_vertexes["\(e_d.v)"]
                    let distance_destination_node2 = distanceBetweenTwoPoints2D(p1x:currentX, p1y:currentY, p2x:node2_destination!["x"]!, p2y:node2_destination!["y"]!)*100.0
                    //print(distance_destination_node2)
                    
                    let (distances1, pathDict1) = level1!.graph.dijkstra(root: e_u.u, startDistance: 0) // I know that pathDict2 is unused
                    let nameDistance1: [String: Int?] = distanceArrayToVertexDict(distances: distances1, graph: level1!.graph)
                    let nd1e_d_u = Float(nameDistance1["\(e_d.u)"]!!)
                    ////path_distances["\(e_u.u)"]=min(path_distances["\(e_u.u)"] ?? Float(Int.max),distance_user_node1 + nd1e_d_u + distance_destination_node1)
                    if path_distances["\(e_u.u)"] ?? Float(Int.max) > distance_user_node1 + nd1e_d_u + distance_destination_node1 {
                        path_distances["\(e_u.u)"] = distance_user_node1 + nd1e_d_u + distance_destination_node1 // nodo u edge destinazione
                        last_nodes["\(e_u.u)"] = "\(e_d.u)"
                    }
                    let nd1e_d_v = Float(nameDistance1["\(e_d.v)"]!!)
                    ////path_distances["\(e_u.u)"]=min(path_distances["\(e_u.u)"] ?? Float(Int.max),distance_user_node1 + nd1e_d_v + distance_destination_node2)
                    if path_distances["\(e_u.u)"] ?? Float(Int.max) > distance_user_node1 + nd1e_d_v + distance_destination_node2 {
                        path_distances["\(e_u.u)"] = distance_user_node1 + nd1e_d_v + distance_destination_node2 // nodo v edge destinazione
                        last_nodes["\(e_u.u)"] = "\(e_d.v)"
                    }
                    
                    let (distances2, pathDict2) = level1!.graph.dijkstra(root: e_u.v, startDistance: 0) // I know that pathDict2 is unused
                    let nameDistance2: [String: Int?] = distanceArrayToVertexDict(distances: distances2, graph: level1!.graph)
                    let nd2e_d_u = Float(nameDistance2["\(e_d.u)"]!!)
                    ////path_distances["\(e_u.v)"]=min(path_distances["\(e_u.v)"] ?? Float(Int.max),distance_user_node2 + nd2e_d_u + distance_destination_node1)
                    if path_distances["\(e_u.v)"] ?? Float(Int.max) > distance_user_node2 + nd2e_d_u + distance_destination_node1 {
                        path_distances["\(e_u.v)"] = distance_user_node2 + nd2e_d_u + distance_destination_node1 // nodo v edge destinazione
                        last_nodes["\(e_u.v)"] = "\(e_d.u)"
                    }
                    let nd2e_d_v = Float(nameDistance2["\(e_d.v)"]!!)
                    ////path_distances["\(e_u.v)"]=min(path_distances["\(e_u.v)"] ?? Float(Int.max),distance_user_node2 + nd2e_d_v + distance_destination_node2)
                    if path_distances["\(e_u.v)"] ?? Float(Int.max) > distance_user_node2 + nd2e_d_v + distance_destination_node2 {
                        path_distances["\(e_u.v)"] = distance_user_node2 + nd2e_d_v + distance_destination_node2 // nodo v edge destinazione
                        last_nodes["\(e_u.v)"] = "\(e_d.v)"
                    }
                }
            }
            var min:Float=Float(Int.max)
            for ptdist in path_distances {
                if ptdist.value<min {
                    nextNode = ptdist.key
                    min = ptdist.value
                }
            }
            
            if nextNode == "" {
                nextNode="0"
            }
            
            lastNode = last_nodes["\(nextNode)"] ?? "0"
            lastNodeLabel.text = "L: \(lastNode)"
            //print("nextNode \(nextNode) , lastNode \(lastNode)")
            
            // check if the node change
            if nextNode != previous_node {
                changeNode = true
            } else {
                changeNode = false
            }
            previous_node = nextNode
            
            // COMPUTE RUOTE AND SEE IF THE ROUTE IS CONTAINED INTO THE PATH THAT I'M FOLLOWING
            if nextNode != lastNode{
                let (distances, pathDict) = level1!.graph.dijkstra(root: Int(nextNode) ?? 0, startDistance: 0)
                //print("pathDict",pathDict)
                //let nameDistance: [String: Int?] =  distanceArrayToVertexDict(distances: distances, graph: level1!.graph)
                let stops: [String] = level1!.graph.edgesToVertices(edges: pathDictToPath(from: level1!.graph.indexOfVertex("\(nextNode)")!, to: level1!.graph.indexOfVertex("\(lastNode)")!, pathDict: pathDict))
                //print("stops",stops)
                // check if the subroute is changed
                if route.count==0{
                    route = stops
                } else{
                    if route.contains(subarray: stops){
                        changePath = false
                    } else {
                        changePath = true
                        route = stops
                    }
                }
            }
            routeLabel.text = "\(route)"
            

            let v = level1!.position_vertexes["\(nextNode)"]!
            target_x_map = v["x"]!
            target_y_map = v["y"]! // MARK: TARGET IS A NODE
            state = "inside"
            state_user.text=state
            nextTargetLabel.text = "T: \(nextNode)"
            inside_outside.text = "I/O: inside"
            debug_point_of_return.text = ""
            
            //beta.text = "beta: "
        }
    }
    
 
    /*
     
     // INITIAL AXES OF ARKIT
     
     z_arkit
     ^
     |
     |                ß= -90°
     |         <______.
     |
     |        µ=90°
     |        .----->z
     |
     |
     |-------------------------------------> x_arkit
      \
       \
        \
         \
          \
           \
            \
             y_arkit
     
     the local reference system of ARKIT is rotated on x axes by 90°. This is to align the X and Z of the devide with the map.
     
     -y_arkit
     ^
     |
     |                ß= -90°
     |         <______.
     |
     |        µ=90°
     |        .----->z
     |
     |
     |-------------------------------------> x_arkit
      \
       \
        \
         \
          \
           \
            \
             z_arkit --> pointing into screen.
     
     // now, since the camera is directed in the opposite direction of z, the z becomes -z
     
     // ARKIT AXES
     
     -y_arkit
     ^
     |
     |                ß= -90°
     |         <______.
     |
     |        µ=90°
     |        .----->z
     |
     |
     |-------------------------------------> x_arkit
      \
       \
        \
         \
          \
           \
            \
             -z_arkit
     
     
     // THE MAP IS EXPRESSED LIKE with x_map = x_arkit AND y_map = -z_arkit
                     ß= -90°
              <______.
     
             µ=90°
             .----->z
     
     -------------------------------------> x_map = x_arkit
      \
       \
        \
         \
          \
           \
            \
             y_map = -z_arkit
     
     
     */
    
    
    //@objc func evaluatePose(){
    func evaluatePose(newLocation: ApproxLocation){
        if startLog{
            
            if startBool && state != "arrived"{ 
                isStarted = true
                
                var currentX_map = Float(newLocation.coordinates.x)
                var currentY_map = -Float(newLocation.coordinates.y)
                var currentYAW = Float(newLocation.heading)
                //print(currentX_map, currentY_map, currentYAW)
                
                var currentZ_map = 0.0
                var currentROLL = 0.0
                var currentPITCH = 0.0
                
                var t = CFAbsoluteTimeGetCurrent() - timerRepeatInstruction
                
                // TODO: CHECK JUMP
                if (abs(previous_currentX_map - currentX_map)>0.8 || abs(previous_currentY_map - currentY_map)>0.8) && previous_currentX_map != 0 && previous_currentY_map != 0 {
                    //level4.speak(message: "update", state: state, changeNode: false, changePath: false, repeatInstructionFlag: false)
                    //level4.playUpdateSound()
                    // BIG JUMP
                    JUMPDEBUG.text = "JUMP X:\(reduceResolution(value: currentX_map, 100)),Y:\(reduceResolution(value: currentY_map, 100))"
                    // TODO: inserire earcon? forse troppo
                    level4.jumpSound()
                    
                }
                previous_currentX_map = currentX_map
                previous_currentY_map = currentY_map
                
                // DEBUG markers: number of markers, which markers were detected and error pose.
                //print(arView.session.currentFrame?.anchors)
                whichMarkerWereDetected = ""
                numMarker = 0
                var x_marker : Float = 0.0
                var y_marker : Float = 0.0
                var last_img_anchor : ARAnchor? = nil
                for anchor in arView.session.currentFrame?.anchors ?? [] {
                    if ((anchor as? ARImageAnchor) != nil) {
                        whichMarkerWereDetected = "\(anchor.name!),  \(whichMarkerWereDetected)"
                        last_img_anchor = anchor
                        numMarker += 1
                        for k in markers {
                            if k.id == anchor.name!{
                                x_marker = Float(k.location.coordinates.x)
                                y_marker = Float(k.location.coordinates.y)
                            }
                        }
                    }
                }
                if last_img_anchor != nil{
                    DEBUGX.text="err x img = \(reduceResolution(value: last_img_anchor!.transform.columns.3.x-x_marker, 1000))" // TODO: check if is correct
                    DEBUGY.text="err y img = \(-reduceResolution(value: last_img_anchor!.transform.columns.3.z-y_marker, 1000))"
                    //JUMPDEBUG.text="z img = \(reduceResolution(value: last_img_anchor!.transform.columns.3.y, 1000))"
                }
                numMarkersLabel.text = "# Mark: \(numMarker)"
                markerNameLabel.text = whichMarkerWereDetected
                
                var previous_state = state
                
                E_u = level2.getEdgesAtPosition(position: (px:currentX_map,py:currentY_map), input_Graph: level1!.graph, position_vertexes: level1!.position_vertexes, links: links)
                //print(E_u)
                // GET DESTINATION EDGE
                E_d = level2.getEdgesAtPosition(position: (px:destination_position["x_d"]!,py:destination_position["y_d"]!), input_Graph: level1!.graph, position_vertexes: level1!.position_vertexes, links: links)
                //print(E_d)
                var user_edges_description="E_u: "
                for e in E_u {
                    user_edges_description="\(user_edges_description) \(e.u)-\(e.v)"
                }
                user_edges.text = user_edges_description
                
                // MARK: LEVEL 2
                print("level2")
                var num_shared_edges_user_destination : Int = level2.checkSharedEdgesDestination(E_u: &E_u,E_d: &E_d)
                
                
                outputLevel2(currentX: currentX_map, currentY: currentY_map, previous_state: state, edges_user: &E_u,edges_destination: &E_d, num_shared_edges_user_destination: num_shared_edges_user_destination)
                
                if state != "arrived" {
                    
                    let dx = (target_x_map-currentX_map)
                    let dy = (target_y_map-currentY_map) // TODO: GIUSTO? oppure aggiungere il - davanti?
                    
                    debug_dx_dy_point_of_return.text = "dx: \(reduceResolution(value: dx, 100)) dy: \(reduceResolution(value: dy, 100))"
                    
                    // TODO: ... SUCCEDE CHE angle path
                    var anglePath = atan2(dy,dx)-(Float.pi/2)
                    
                    //anglePath = ((anglePath+900).truncatingRemainder(dividingBy: 360))-180 // ? TODO: SI O NO
                    
                    let debugAngle = reduceResolution(value: rad2degree(anglePath), resolution)
                    anglePathLabel.text = "ang path: \(debugAngle)"
                    
                    // ANGLE DEBUG
                    //var angular_difference = rad2degree(currentYAW_arkit-anglePath)
                    var angular_difference = rad2degree(currentYAW-anglePath)
                    
                    angular_difference = ((angular_difference+900).truncatingRemainder(dividingBy: 360))-180 // TODO: FUNZIONA MA NON È EFFICIENTE
                    
                    //angular_difference = doit(a:angular_difference) // DOESN'T WORK
                    
                    
                    // TODO: CHECK
                    /*if abs(angular_difference) > 180{
                        angular_difference = -min(360-abs(angular_difference), abs(angular_difference))
                    }*/
                    
                    angular_error_label.text = "ang err: \(reduceResolution(value: angular_difference,100))"
                    
                    let direction = angular_difference>0 && angular_difference < 180 ? "Right":"Left" // TODO: quando sono fuori dalla safe area la prima volta mi dice la direzione sbagliata.... le volte successive è corretta. devi capire perchè.
                    distance = distanceBetweenTwoPoints2D(p1x: target_x_map, p1y: target_y_map, p2x: currentX_map, p2y: currentY_map)
                    let distanceFromPath = direction == "Left" ? -distance:distance
                    
                    distance_from_next_target_label.text = "dist target: \(reduceResolution(value: distance,100))"
                    
                    // DEBUG VIRTUAL SPHERE
                    
                    /*targetSpherex = target_x_map
                     targetSpherez = target_y_map*/
                    
                    targetEntity.removeFromParent()
                    if state=="outside"{
                        targetSpherex = x_return_map
                        targetSpherez = y_return_map
                    } else {
                        targetSpherex = target_x_map
                        targetSpherez = target_y_map
                    }
                    self.targetEntity.position = SIMD3<Float>(targetSpherex, 0, -targetSpherez)
                    self.targetEntity.addChild(self.model_03)
                    self.arView.scene.anchors.append(targetEntity)
                    
                    // MARK: compute range of directions
                    if version_setup == "advanced" {
                        var cateto1 = num_shared_edges_user_destination>=1 ? radius_destination : closest_edge!.radiusOfSafeArea
                        var alpha = rad2degree(asin(cateto1/abs(distance)))
                        if alpha.isNaN {
                            alpha = 90.0
                        }
                        print("alpha",alpha)
                        beta.text="range: \(reduceResolution(value: alpha, 1000))"
                        range = max(alpha,level3.alpha3)
                    } else {
                        range=level3.alpha3
                    }
                    
                    timerLabel.text = "timer: \(Int(CFAbsoluteTimeGetCurrent()-level4.timerRepeatInstruction))"

                    // MARK: LEVEL 3
                    print("level3")
                    // GENERATE MESSAGE
                    let new_message = level3.generateMessage(angular_error: abs(angular_difference), current_state: state, changeNode: changeNode, version_setup: version_setup, range: range, timerRepeatInstruction: level4.timerRepeatInstruction)
                    
                    previous_message_label.text = message
                    
                    // TODO: CHECK MOVEMENT TO AVOID TURN DURING INSTRUCTION OF TURN. YOU NEED ALSO A TIMER.
                    if message != new_message || changeNode || changePath || previous_state != state {
                        position_X_of_turn_map = currentX_map
                        position_Y_of_turn_map = currentY_map
                        level4.timerRepeatInstruction = CFAbsoluteTimeGetCurrent()
                    }
                    
                    movement = distanceBetweenTwoPoints2D(p1x: position_X_of_turn_map, p1y: position_Y_of_turn_map, p2x: currentX_map, p2y: currentY_map)
                    movementLabel.text = "Move: \(reduceResolution(value: movement, 100))"
                    
                    // Se sono outside, sto camminando e devo rientrare, allora ti do la nuova istruzione solo quando ho passato la percentuale di safe area necessaria a rimanere nella safe area.
                    if state == "outside" && message.contains("walk") {  // return to radius*percentage from boundaries of the safe area.
                        if abs(distance)>closest_edge!.radiusOfSafeArea*percentage {
                            message = new_message
                        }
                    } else{
                        message = new_message
                    }
                    
                    message_label.text = message
                    
                    
                    // MARK: LEVEL 4
                    print("level4")
                    //print(direction)
                    
                    directionLabel.text = "Dir: \(direction)"
                    
                    level4.speak(message: message, angular_difference: angular_difference, range: range, distanceFromTarget: distance, safeAreaRadius: closest_edge!.radiusOfSafeArea*percentage, direction: direction, movement: movement, state: state, changeNode: changeNode, changePath: changePath, repeatInstructionFlag: repeatInstructionFlag) // BEFORE TEST INSIDE AND OUTSIDE
                    // TODO: DARE IN INPUT L'ANGOLO DI ISTRUZIONE PER CONTROLLO ANGOLO.
                    
                    level4debug.text="LV4: \(level4.debugConditions)"
                    
                    if level4.startSonification{ //message != new_message || message=="" {
                        angtarget = "\(angular_difference)"
                        distTarget = "\(distance)"
                    } else {
                        angtarget = ""
                        distTarget = ""
                    }
                    
                    guard level4.angleLength==nil else {
                        targetAngleLabel.text = "t ang: \(reduceResolution(value: level4.angleLength!, 1000)),  \(level4.startSonification)"
                        return
                    }
                
                    // LOG DATA
                    // which data: x, y, z, roll, pitch, yaw, ang error, ang target, dist next target, dist target, x_gap_correction, y_gap_correction, next node, direction, state, message, start log, start sonification
                    var timestamp:String = "\(NSDate().timeIntervalSince1970 * 1000)"
                    let text = "\(timestamp),\(currentX_map),\(currentY_map),\(currentZ_map),\(currentROLL),\(currentPITCH),\(currentYAW),\(angular_difference),\(angtarget),\(distance),\(distTarget),\(direction),\(x_fixing_gap_map), \(y_fixing_gap_map),\(nextNode),\(state),\(message),\(startLog),\(level4.startSonification)"
                    log.logAsync(logDescription: text)
                }
                else {
                    if !saidArrived {
                        message = "Destination Reached"
                        level4.speak(message: message, state: state,changeNode: changeNode, changePath: changePath, repeatInstructionFlag: repeatInstructionFlag)
                    }
                    Synth.shared.volume = 0
                    Synth.shared.frequency = 0
                    saidArrived = true
                }
            } else {
                repeat_pose_evaluation = false
                Synth.shared.volume = 0
                Synth.shared.frequency = 0
                if message != "Destination Reached"{
                    message = "Destination Reached"
                    level4.speak(message: message, state: state,changeNode: changeNode, changePath: changePath, repeatInstructionFlag: repeatInstructionFlag)
                }
            }
        }
    }
    
    func debugPose(_ currentX_map:Float, _ currentY_map:Float, _ currentZ_map:Float, _ currentROLL: Float, _ currentYAW: Float, _ currentPITCH: Float, _ resolution: Float){
        x_user.text="user x=\(reduceResolution(value: currentX_map, resolution))"
        y_user.text="user y=\(reduceResolution(value: currentY_map, resolution))"
        z_user.text="user z=\(reduceResolution(value: currentZ_map, resolution))"
        roll_user.text="user roll=\(reduceResolution(value: rad2degree(currentROLL), resolution))"
        yaw_user.text="user yaw=\(reduceResolution(value: rad2degree(currentYAW), resolution))"
        pitch_user.text="user pitch=\(reduceResolution(value: rad2degree(currentPITCH), resolution))"
    }
    
    func reduceResolution(value: Float , _ resolution: Float) -> Float {
        return round(resolution * value)/resolution
    }
    
    func rad2degree(_ value: Float)->Float{
        return value * 180 / Float.pi
    }
    
    func rad2degree(_ value: Double)->Double{
        return value * 180 / Double.pi
    }
    
    func getNodePosition(vertexes: [String : [String: Float]], node: String)->(x:Float, y:Float){
        return (x:vertexes[node]!["x"] ?? 0,y:vertexes[node]!["y"] ?? 0)
    }
    
    func doit(a:Float)->Float{
        var b = a.truncatingRemainder(dividingBy: 360.0) // Make angle between 0 and 360
        if b>180{
            b -= 360 // Make angle between -179 and 180
        }
        return b
    }
    
    
    // TODO: RETURN LIST OF JSON FILE IN THE FILE SYSTEM AND CHOOSE YOURS
    
    // READ JSON FILE
    /*func readJSONFile(forName name: String) -> Map {
        let decoder = JSONDecoder()
       do {
          if let bundlePath = Bundle.main.path(forResource: name, ofType: "json"),
          let jsonData = try String(contentsOfFile: bundlePath).data(using: .utf8) {
             /*if let json = try JSONSerialization.jsonObject(with: jsonData, options: .mutableLeaves) as? [String: Any] {
                print("JSON: \(json)")
                 return json
             } else {
                print("Given JSON is not a valid dictionary object.")
             }*/
            let map = try! decoder.decode(Map.self, from: jsonData)
              return map
          }
       } catch {
          print(error)
       }
        return nil
    }*/
    
    func onBuildingChanged(_ newBuilding: Building) {
        print("Building changed: \(newBuilding.name)")
        let drop = Drop(
            title: newBuilding.name,
            subtitle: "Building changed",
            icon: UIImage(systemName: "building"),
            accessibility: "Alert: Title, Subtitle"
        )
        Drops.show(drop)
    }
    
    func onFloorChanged(_ newFloor: Floor) {
        print("Floor changed: \(newFloor.number)")
        let drop = Drop(
            title: newFloor.name,
            subtitle: "Floor changed: \(newFloor.number)°",
            icon: UIImage(systemName: "chevron.up.chevron.down"),
            accessibility: "Alert: Title, Subtitle"
        )
        Drops.show(drop)
    }
    

    @IBAction func btnCenterTouched(_ sender: Any) {
        self.locationProvider.centerToUserPosition()
    }
    
    @IBAction func changeMode(_ sender: Any) {
        if version_setup == "basic" {
            version_setup = "advanced"
            let setup_message : String = "advance VERSION"
            Toast.show(message: setup_message, bgColor: UIColor.yellow, textColor: .black,labelFont: .boldSystemFont(ofSize: 14),showIn: .top,controller: self)
            level4.feedback(setup_message)
        } else if version_setup == "advanced" {
            version_setup = "basic"
            let setup_message : String = "basic VERSION"
            Toast.show(message: setup_message, bgColor: UIColor.yellow, textColor: .black,labelFont: .boldSystemFont(ofSize: 14),showIn: .top,controller: self)
            level4.feedback(setup_message)
        }
    }
    
    //let serviceUUID = CBUUID(string: "2A50")
    //let kitchenScaleCharacteristicUUID = CBUUID(string: "8AA2")
    
    // BLUETOOTH METHODS
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central state update")
        var services : [CBUUID] = []
        let cbuuid = CBUUID(string: "4945C78A-8DE3-58E2-86E7-543427837FFB");
        services.append(cbuuid)
        switch central.state {
            case .poweredOn:
                print("scan")
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            case .poweredOff:
                // Alert user to turn on Bluetooth
                print("central off")
            case .resetting:
                // Wait for next state update and consider logging interruption of Bluetooth service
                print("central resetting")
            case .unauthorized:
                // Alert user to enable Bluetooth permission in app Settings
                print("enable Bluetooth permission")
            case .unsupported:
                // Alert user their device does not support Bluetooth and app will not work as expected
                print("device does not support Bluetooth")
            case .unknown:
               // Wait for next state update
                print("unknown")
        }
        
        /*if central.state != .poweredOn {
            print("Central is not powered on")
        } else {
            print("Central scanning for", ParticlePeripheral.particleXENVOBlueToothButton);
            centralManager.scanForPeripherals(withServices: [],
                                              options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        }*/
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // We've found it so stop scan
        print("peripheral",peripheral.identifier)
        print("advertisementData",advertisementData)
        if peripheral.name == "Xenvo Shutterbug" {
            self.centralManager.stopScan()
            // Copy the peripheral instance
            self.peripheral = peripheral
            self.peripheral.delegate = self
            // Connect!
            self.centralManager.connect(self.peripheral, options: nil)
            print("connect")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            print("Connected to your Particle Board")
            //peripheral.discoverServices([ParticlePeripheral.particleXENVOBlueToothButton])
            //let service = peripheral.services!.first(where: { $0.uuid == CBUUID(string:"2A50")})
            //peripheral.discoverServices([(service?.uuid)!])
            
            print("services",peripheral.services)
            print("name",peripheral.name)
            print("state",peripheral.state)
            print("identifier",peripheral.identifier)
            print("description",peripheral.description)
            print("ancsAuthorized",peripheral.ancsAuthorized)
            print("canSendWriteWithoutResponse",peripheral.canSendWriteWithoutResponse)
            
            peripheral.discoverServices([])
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                print("service.uuid", service.uuid)
                peripheral.discoverCharacteristics([ParticlePeripheral.particleXENVOBlueToothButton], for: service)
                /*if service.uuid == ParticlePeripheral.particleXENVOBlueToothButton{
                    print("BUTTON service found")
                    //Now kick off discovery of characteristics
                    peripheral.discoverCharacteristics([ParticlePeripheral.particleXENVOBlueToothButton], for: service)
                    return
                }*/
                //peripheral.discoverCharacteristics([ParticlePeripheral.particleXENVOBlueToothButton], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            print("test",characteristics.description)
            for characteristic in characteristics {
                print("characteristic",characteristic)
                peripheral.setNotifyValue(true, for: characteristic)
                /*if characteristic.uuid == ParticlePeripheral.particleXENVOBlueToothButton {
                    print("SOLO QUESTO")
                }*/ /*else if characteristic.uuid == ParticlePeripheral.greenLEDCharacteristicUUID {
                    print("Green LED characteristic found")
                } else if characteristic.uuid == ParticlePeripheral.blueLEDCharacteristicUUID {
                    print("Blue LED characteristic found");
                }*/
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print(characteristic.value)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
        print("didWriteValueFor",characteristic.value)
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            let weight: Int = data.withUnsafeBytes{$0.pointee}
            print("didupdate",characteristic,weight)
        }
    }
    
    
    
}



