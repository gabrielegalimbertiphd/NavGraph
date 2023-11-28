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

// TODO:
/*preparare spiegazione e protocollo di test, debug suono quando cambia target (no quando c’è rerouting)
Sistemare bottone
Mostrare i dati di log

Preparare 4 task date le condizioni:
- 2 percorsi
- 2 sistemi di navigazione

Basic
Advanced
Advanced
Basic
Advanced
Basic
Basic
Advanced*/

/*struct Link {
    var node_u : String
    var node_v : String
    var widthOfSafeArea : Float = 1.0
}*/

// TODO: JSON vertexes [position_vertexes{x,y,yaw}]  links [{u,v,widthOfSafeAreaBySide}] markers[{marker,x,y,yaw}]
// put destination settable on the links and radius with check
// put possibility to insert

// TODO: split the concepts radius*percentage and width

struct Map: Decodable{
    
    struct Vertex : Decodable{
        let x : String
        let y : String
        let raw : String
    }
    let vertexes: [String : Vertex]
    
    struct LinkEdge : Decodable{
        var node_u : String
        var node_v : String
        var radiusOfSafeArea : Float = 1.0
    }
    let links: [LinkEdge]
    
    struct Marker : Decodable{
        let x : String
        let y : String
        let raw : String
    }
    let position_markers: [String : Marker]
    
    enum FloorKeys: String, CodingKey {
          case vertexes, links, position_markers
       }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: FloorKeys.self)
        vertexes = try values.decode([String : Vertex].self, forKey: .vertexes)
        links = try values.decode([LinkEdge].self, forKey: .links)
        position_markers = try values.decode([String : Marker].self, forKey: .position_markers)
    }
}


// class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, LocationObserver  {
class ViewController: UIViewController, LocationObserver, ARSessionDelegate{
    
    // location provider
    private var locationProvider: LocationProvider!
    
    // JSON reader
    private var customJsonParser: CustomJsonParser!
    private var markers : [Marker] = []

    //@IBOutlet var sceneView: ARSCNView!
    @IBOutlet var arView: ARView!
    private var startBool: Bool = false
    private var startLog: Bool = false
    private var graphbased: Bool = true
    private var bubble_placed: Bool = true
    private var isStarted:Bool = false
    
    // RENDER VIRTUAL OBJECTS
    private var render: Render!
    
    // MAP TEST FLOOR 4
    // MARK: OFFICIAL REFACTORED
    
    public var vertexes : [String] = ["0", "1","2", "3","4","5","6"]
    public var graph: WeightedGraph<String, Int> = WeightedGraph<String, Int>(vertices: ["0", "1","2", "3","4", "5","6"])
    
    private let resolution: Float = 100.0
    
    var destination: String = "A"
    
    var percorso = "Percorso1"
    
    public var position_vertexes : [String : [String: Float]]=[
        "0":["x": 61.05268927500583 ,"y": -87.40503094345331 ],
        "1":["x": 61.10780490835896 ,"y": -93.00988889113069 ],
        "2":["x": 92.2461984824622 ,"y": -93.87077672220767 ],
        "3":["x": 93.33124991157092 ,"y": -100.60946055687964 ],
        "4":["x": 149.334955506376 ,"y": -98.48757871426642 ],
        "5":["x": 149.3386826463975 ,"y": -96.30665448587388 ]
    ]
    
    public var coordinates_position_vertexes : [String : [String: [String: Float]]]=[
        "Percorso1":[
            "0":["x": 61.05268927500583 ,"y": -87.40503094345331 ],
            "1":["x": 61.10780490835896 ,"y": -93.00988889113069 ],
            "2":["x": 92.2461984824622 ,"y": -93.87077672220767 ],
            "3":["x": 93.33124991157092 ,"y": -100.60946055687964 ],
            "4":["x": 149.334955506376 ,"y": -98.48757871426642 ],
            "5":["x": 149.3386826463975 ,"y": -96.30665448587388 ]
        ],
        "Percorso2":[
            "0":["x": 213.04729223815957 ,"y": -155.66430983599275 ],
            "1":["x": 213.49196822976228 ,"y": -154.4162802444771 ],
            "2":["x": 223.46639834909 ,"y": -153.85030070506036 ],
            "3":["x": 222.8217324456782 ,"y": -93.71006935089827 ],
            "4":["x": 203.12929557752796 ,"y": -94.45257009752095 ],
            "5":["x": 200.24905982101336 ,"y": -86.69898427370936 ]
        ],
        "Percorso3":[
            "0":["x": 102.6404510139837 ,"y": -60.14208863116801 ],
          "1":["x": 88.64668009313755 ,"y": -59.07142744772136 ],
          "2":["x": 88.01148574490799 ,"y": -55.62923298496753 ],
          "3":["x": 114.7318031283794 ,"y": -51.997109580785036 ],
          "4":["x": 114.33107357576955 ,"y": -48.554241485893726 ],
          "5":["x": 141.2150449262699 ,"y": -47.47677667718381 ],
          "6":["x": 141.25694681494497 ,"y": -34.92263310588896 ]
        ],
        "Percorso4":[
            "0":["x": 59.439679035916924 ,"y": -94.92887321859598 ],
          "1":["x": 58.94899937073933 ,"y": -87.37565205525607 ],
          "2":["x": 21.433495770033915 ,"y": -87.92778716702014 ],
          "3":["x": 23.428358036850113 ,"y": -74.92365301214159 ],
          "4":["x": 17.48789463250432 ,"y": -74.82959797792137 ],
          "5":["x": 16.8170478772372 ,"y": -58.94457573443651 ],
          "6":["x": 22.83246818050975 ,"y": -57.927440950647 ]
        ],
        "Prova":[
            "0":["x": 100 ,"y": -100 ],
            "1":["x": 100 ,"y": -105 ],
            "2":["x": 105 ,"y": -105 ]
        ]
    ]
    public var destination_position : [String: Float] = [ "x": 105 ,"y": -105 ]
    
    public var radius_destination : Float = 1.0
    /*var links: [Link] = [
        Link( node_u :"0", node_v :"1", radiusOfNavigationArea :1),
        Link( node_u :"1", node_v :"2", radiusOfNavigationArea :1.5),
        Link( node_u :"2", node_v :"3", radiusOfNavigationArea :1.5),
        Link( node_u :"3", node_v :"4", radiusOfNavigationArea :1.5),
        Link( node_u :"4", node_v :"5", radiusOfNavigationArea :1.5),
        Link( node_u :"5", node_v :"6", radiusOfNavigationArea :1)
    ]*/
    
    var links: [Link] = [
        Link( node_u :"0", node_v :"1", radiusOfNavigationArea :1.5),
        Link( node_u :"1", node_v :"2", radiusOfNavigationArea :2),
        Link( node_u :"2", node_v :"3", radiusOfNavigationArea :1),
        Link( node_u :"3", node_v :"4", radiusOfNavigationArea :2),
        Link( node_u :"4", node_v :"5", radiusOfNavigationArea :1)
    ]
    
    var linksOfPaths:[String:[Link]] = [
        "Percorso1":[
            Link( node_u :"0", node_v :"1", radiusOfNavigationArea :1.5),
            Link( node_u :"1", node_v :"2", radiusOfNavigationArea :2),
            Link( node_u :"2", node_v :"3", radiusOfNavigationArea :1),
            Link( node_u :"3", node_v :"4", radiusOfNavigationArea :2),
            Link( node_u :"4", node_v :"5", radiusOfNavigationArea :1)
        ],
        "Percorso2":[
            Link( node_u :"0", node_v :"1", radiusOfNavigationArea :1),
            Link( node_u :"1", node_v :"2", radiusOfNavigationArea :1.5),
            Link( node_u :"2", node_v :"3", radiusOfNavigationArea :2),
            Link( node_u :"3", node_v :"4", radiusOfNavigationArea :1.5),
            Link( node_u :"4", node_v :"5", radiusOfNavigationArea :1)
        ],
        "Percorso3":[
            Link( node_u :"0", node_v :"1", radiusOfNavigationArea :1.5),
            Link( node_u :"1", node_v :"2", radiusOfNavigationArea :1.5),
            Link( node_u :"2", node_v :"3", radiusOfNavigationArea :2),
            Link( node_u :"3", node_v :"4", radiusOfNavigationArea :1),
            Link( node_u :"4", node_v :"5", radiusOfNavigationArea :2),
            Link( node_u :"5", node_v :"6", radiusOfNavigationArea :2)
        ],
        "Percorso4":[
            Link( node_u :"0", node_v :"1", radiusOfNavigationArea :1),
            Link( node_u :"1", node_v :"2", radiusOfNavigationArea :2),
            Link( node_u :"2", node_v :"3", radiusOfNavigationArea :2),
            Link( node_u :"3", node_v :"4", radiusOfNavigationArea :1.5),
            Link( node_u :"4", node_v :"5", radiusOfNavigationArea :2),
            Link( node_u :"5", node_v :"6", radiusOfNavigationArea :1)
        ],
        "Prova":[
            Link( node_u :"0", node_v :"1", radiusOfNavigationArea :1),
            Link( node_u :"1", node_v :"2", radiusOfNavigationArea :1),
        ]
    ]
    
    public var fixedWidthSafeArea: [Float] = [1.0,1.5,1.5,1.5,1.5,1.0]
    /*
    // JAMES FLOOR 4 SKERI
     
     public var vertexes : [String] = ["0", "1", "2", "3", "4", "5", "6", "7","8"]
     public var graph: WeightedGraph<String, Int> = WeightedGraph<String, Int>(vertices: ["0", "1", "2", "3", "4", "5", "6", "7","8"])
    
    public var position_vertexes : [String : [String: Float]] =
    [
        "0":["x":0.8,"y":-0.8],
        "1":["x":11.6,"y":-0.8],   // BEFORE x : 12.0
        "2":["x":11.6,"y":-22.50], // BEFORE x : 12.0
        "3":["x":0.8,"y":-20.22],
        "4":["x":8.8,"y":-22.50],
        "5":["x":2.62,"y":-20.22],
        "6":["x":2.62,"y":-28.8],
        "7":["x":8.8,"y":-28.8],
        "8":["x":6,"y":-20.22]
    ]
    
    public var destination_position : [String: Float] = ["x": 5.6, "y": -28.8] // near node 7 // init at 0,0
    public var radius_destination : Float = 1.0 // raggio della destinazione
    
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
    
    public var fixedWidthSafeArea: [Float] = [2.0, 1.0, 2.0, 1.0, 2.0, 1.0, 2.0, 2.0, 1.0]
    */
    
    
    private var evaluation_pose_frequency:Double = 20.0
    
    var angtarget:String = ""
    var distTarget:String = ""
    
    var percentage: Float = 0.5
    var distance : Float = 0.0
    var range : Float = 30.0
    var length_closest_edge : Float = 0.0
    
    public var timerRepeatInstruction: Double = 0.0
    
    // check movement of the user while the instruction is given
    var movement : Float = 0.0
    var previous_currentX_map : Float = 0.0
    var previous_currentY_map : Float = 0.0
    var position_X_of_turn_map : Float = 0.0
    var position_Y_of_turn_map : Float = 0.0
    
    var numMarker : Int = 0
    var whichMarkersWereDetected : String = ""
    var lastMarkerSeen : String = ""
    
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
    //lazy var z_user = UILabel()
    lazy var approx_radius_debug = UILabel()
    
    lazy var level4debug = UILabel()
    
    lazy var yaw_user = UILabel()
    lazy var pitch_user = UILabel()
    //lazy var roll_user = UILabel()
    lazy var approx_angle_debug = UILabel()
    
    lazy var x_fixing_gap_marker = UILabel()
    lazy var y_fixing_gap_marker = UILabel()
    
    lazy var x_fixing_gap_user = UILabel()
    lazy var y_fixing_gap_user = UILabel()
    
    lazy var message_label = UILabel()
    lazy var previous_message_label = UILabel()
    lazy var sonification_rate = UILabel()
    lazy var calcolo_lateral_offset = UILabel()
    
    lazy var angular_error_label = UILabel()
    lazy var distance_from_next_target_label = UILabel()
    
    lazy var DEBUGANGLE = UILabel()
    lazy var X_error_img = UILabel()
    lazy var Y_error_img = UILabel()
    lazy var JUMPDEBUG = UILabel()
    lazy var movementLabel = UILabel()
    
    lazy var range_of_directions_debug = UILabel()
    lazy var timerLabel = UILabel()
    
    lazy var anglePathLabel = UILabel()
    lazy var directionLabel = UILabel()
    
    lazy var lateralDistanceLabel = UILabel()
    
    // DEBUG BUBBLE
    
    //let sphereTarget = SCNNode(geometry: SCNSphere(radius: 0.08))
    
    // TARGET X Y
    public var target_x_map:Float=0.0
    public var target_y_map:Float=0.0
    public var x_return_map:Float=0.0
    public var y_return_map:Float=0.0
    public var target_on_edge_description:String = ""
    
    // FIX POSITION
    public var x_fixing_gap_map:Float = 0.0
    public var y_fixing_gap_map:Float = 0.0
    
    public var lastEdge:String? = nil
    
    public var level1:Level1? = nil
    public var level2:Level2 = Level2()
    public var level3:Level3 = Level3()
    public var level4:Level4 = Level4()
    
    // LOG
    private var log : Log = Log()
    
    // SET VERSION
    public var version_setup = "advanced" // it can change to "basic"
    public var closest_edge:Link? = nil
    public var distanceFromCurrentEdge : Float = 0.0
    public var dxFromCurrentEdge : Float = 0.0
    public var dyFromCurrentEdge : Float = 0.0
    
    public var taskTest : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // CREATE THE AR SESSION
        setupARConfiguration()
                
        debugLabels()
        
        
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
        
        guard startBool==false || isStarted==false else{
            Toast.show(message:  "Already started.\n Show stop marker to stop", bgColor: UIColor.red, textColor: .white,labelFont: .boldSystemFont(ofSize: 14),showIn: .top,controller: self)
            return
        }
        
        if level1 != nil {
            Toast.show(message:  "Map already choose", bgColor: UIColor.red, textColor: .white,labelFont: .boldSystemFont(ofSize: 14),showIn: .top,controller: self)
            return
        }
        
        // change width o f each edge in case of advanced version.
        /*if version_setup=="advanced"{
            for i in 1...links.count{
                print("Before: link \(i-1) = \(links[i-1])")
                if i<fixedWidthSafeArea.count{
                    links[i-1].radiusOfNavigationArea = fixedWidthSafeArea[i-1]
                }
                print("After:  link \(i-1) = \(links[i-1])")
             }
        } else {
            for i in 1...links.count{
                print("Before: link \(i-1) = \(links[i-1])")
                if i<fixedWidthSafeArea.count{
                    links[i-1].radiusOfNavigationArea = 1.0
                }
                print("After:  link \(i-1) = \(links[i-1])")
             }
        }*/
        
        position_vertexes = coordinates_position_vertexes[percorso] ?? position_vertexes
        print(position_vertexes)
        destination_position = position_vertexes["6"] ?? [ "x": 102.12050876254216 ,"y": -96.69467583857477 ]
        print(destination_position)
        links = linksOfPaths[percorso] ?? links
        level1 = Level1(listOfVertexesCoordinates: position_vertexes, destination_position: destination_position, radius_destination: radius_destination, links: links, vertexes: vertexes)
        
        print(level1!.graph)
        
        Toast.show(message: "START SESSION", bgColor: UIColor.yellow, textColor: .red,labelFont: .boldSystemFont(ofSize: 10),showIn: .top,controller: self)
        
        setupARConfiguration()
        
        log = Log()
        
        /*self.locationProvider = LocationProvider(arView: arView, jsonName: "test")
        self.locationProvider.addLocationObserver(locationObserver: self)
        self.locationProvider.start()
        self.locationProvider.showFloorMap(CGRect(x: 5, y: 450, width: 230, height: 360)) //223))*/
        
        self.locationProvider = LocationProvider(arView: arView, jsonName: "\(percorso)")
        self.locationProvider.startFollowUser()
        self.locationProvider.addLocationObserver(locationObserver: self)
        self.locationProvider.start()
        self.locationProvider.showFloorMap(CGRect(x: 5, y: 450, width: 230, height: 360))
        
        customJsonParser = CustomJsonParser(forName: "\(percorso)")
        markers = customJsonParser.getMarkers()
        print(markers)
        for k in markers {
            print(k.id,k.location.coordinates.x,k.location.coordinates.y)
        }
        
        closest_edge = links.first
        
        //createDirectory(self.log.sessionName) // TODO: insert and check directory creation.
        render = Render()
        // message: percorso
        level4.speak(message: "inizio percorso",state: "",changeNode: changeNode, changePath: changePath, repeatInstructionFlag: repeatInstructionFlag)
        
        bubble_placed = true
        isStarted = false
        if bubble_placed {
            print(position_vertexes)
            render.renderNodeVirtualSpheres(position_vertexes: position_vertexes, arView: arView)
            render.renderDestinationVirtualSphere(destination_position: destination_position, arView: arView)
            // renderLinkLines(position_vertexes: position_vertexes, links: links) // TODO: It doesn't work
            bubble_placed = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.startLog = true
            self.startBool = true
            self.taskTest = true
        }
    }
    
    func startProva(){
        print("PROvA")
        position_vertexes = coordinates_position_vertexes["Prova"] ?? position_vertexes
        print(position_vertexes)
        destination_position = position_vertexes["2"] ?? [ "x": 105 ,"y": -105 ]
        links = linksOfPaths["Prova"] ?? links
        level1 = Level1(listOfVertexesCoordinates: position_vertexes, destination_position: destination_position, radius_destination: radius_destination, links: links, vertexes: vertexes)
        
        print(level1!.graph)
        
        Toast.show(message: "START PROVA", bgColor: UIColor.yellow, textColor: .red,labelFont: .boldSystemFont(ofSize: 10),showIn: .top,controller: self)
        
        setupARConfiguration()
        
        /*self.locationProvider = LocationProvider(arView: arView, jsonName: "test")
        self.locationProvider.addLocationObserver(locationObserver: self)
        self.locationProvider.start()
        self.locationProvider.showFloorMap(CGRect(x: 5, y: 450, width: 230, height: 360)) //223))*/
        
        self.locationProvider = LocationProvider(arView: arView, jsonName: "Prova")
        self.locationProvider.startFollowUser()
        self.locationProvider.addLocationObserver(locationObserver: self)
        self.locationProvider.start()
        self.locationProvider.showFloorMap(CGRect(x: 5, y: 450, width: 230, height: 360))
        
        // TODO: customJsonParser = CustomJsonParser(forName: "\(percorso)")
        /*markers = customJsonParser.getMarkers()
        print(markers)
        for k in markers {
            print(k.id,k.location.coordinates.x,k.location.coordinates.y)
        }*/
        
        closest_edge = links.first
        
        //createDirectory(self.log.sessionName) // TODO: insert and check directory creation.
        render = Render()
        // message: percorso
        level4.speak(message: "inizio prova",state: "",changeNode: changeNode, changePath: changePath, repeatInstructionFlag: repeatInstructionFlag)
        
        bubble_placed = true
        isStarted = false
        if bubble_placed {
            print(position_vertexes)
            render.renderNodeVirtualSpheres(position_vertexes: position_vertexes, arView: arView)
            render.renderDestinationVirtualSphere(destination_position: destination_position, arView: arView)
            // renderLinkLines(position_vertexes: position_vertexes, links: links) // TODO: It doesn't work
            bubble_placed = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.startLog = true
            self.startBool = true
            self.taskTest = false
        }
    }
    
    func resetTest(){
        
        Toast.show(message: "RESET SESSION", bgColor: UIColor.yellow, textColor: .red,labelFont: .boldSystemFont(ofSize: 10),showIn: .top,controller: self)
        
        setupARConfiguration()
        
        /*self.locationProvider = LocationProvider(arView: arView, jsonName: "test")
        self.locationProvider.addLocationObserver(locationObserver: self)
        self.locationProvider.start()
        self.locationProvider.showFloorMap(CGRect(x: 5, y: 450, width: 230, height: 360)) //223))*/
        
        self.locationProvider = nil
        bubble_placed = false
        isStarted = false
        self.startLog = false
        self.startBool = false
        self.taskTest = false
        
    }
    
    func onLocationUpdate(_ newLocation: ApproxLocation) {

        var currentX_map = Float(newLocation.coordinates.x)
        var currentY_map = Float(newLocation.coordinates.y)
        var currentYAW = Float(newLocation.heading)
        
        var currentPITCH = Float(arView.session.currentFrame?.camera.eulerAngles.z ?? 0.0)
        
        var approxRadius = Float(newLocation.approxRadius)
        var approxAngle = Float(newLocation.approxAngle)
        
        //debugPose(currentX_map, currentY_map, 0, 0, currentYAW, currentPITCH, 100)
        
        debugPose2(currentX_map, currentY_map, currentYAW, currentPITCH, approxRadius, approxAngle, 100)
        
        evaluatePose(newLocation: newLocation)
    }
    
    func setupARConfiguration(){
        let configuration = ARWorldTrackingConfiguration()
        Toast.show(message:  "World Tracking Config", bgColor: UIColor.blue, textColor: .white,labelFont: .boldSystemFont(ofSize: 14),showIn: .bottom,controller: self)
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.maximumNumberOfTrackedImages = 1
        /*guard let arReferenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            print("Any Resource file has been detected")
            return}*/
        guard let arReferenceImages = ARReferenceImage.referenceImages(inGroupNamed: "Percorso", bundle: nil) else {
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
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        // fixing position mechanism
        guard let imgAnchor = anchors.first as? ARImageAnchor else {return}
        //numMarker += 1
        print(imgAnchor)
        var imgname:String = imgAnchor.name ?? ""
        whichMarkersWereDetected = "\(imgname), \(whichMarkersWereDetected)"
        numMarkersLabel.text = "Prova : \(numMarker)"
        markerNameLabel.text = whichMarkersWereDetected
        if startBool {
            print("didadd")
        
            Toast.show(message:  "UPDATE \(imgname)", bgColor: UIColor.blue, textColor: .white,labelFont: .boldSystemFont(ofSize: 10),showIn: .top,controller: self)
        
        } else if imgname=="switch"{
            /*if version_setup == "basic" {
                version_setup = "advanced"
                let setup_message : String = "advance VERSION"
                Toast.show(message: setup_message, bgColor: UIColor.yellow, textColor: .black,labelFont: .boldSystemFont(ofSize: 14),showIn: .top,controller: self)
                level4.feedback(setup_message)
            }*/
            resetTest()
        } else if imgname=="Prova" {
            startProva()
            print("PRoVA")
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
    
    fileprivate func checkDistanceFromSnap(_ edges_user: [Edge], _ currentX: Float, _ currentY: Float, _ closestEdge: Link, _ distanceFromCurrentEdge: Float, _ flag: inout Bool) {
        print("IN FUNCTION CHECKDISTANCEFROMSNAP")
        print("distance > closestEdge.radiusOfNavigationArea","\(distance) > \(closestEdge.radiusOfNavigationArea)")
        if distance > closestEdge.radiusOfNavigationArea {
            flag = true
        } else {
            for edge in edges_user {
                let vertex_u = position_vertexes["\(edge.u)"]!
                let vertex_v = position_vertexes["\(edge.v)"]!
                let p1X:Float = vertex_u["x"] ?? 0
                let p1Y:Float = vertex_u["y"] ?? 0
                let p2X:Float = vertex_v["x"] ?? 0
                let p2Y:Float = vertex_v["y"] ?? 0
                let data = level2.getClosestPointOnEdge(position: (px:currentX,py:currentY), p1X: p1X, p1Y: p1Y, p2X: p2X, p2Y: p2Y)
                var k : Link? = level2.edgeToLink(links: links,edge: edge)
                
                print(closestEdge, k!)
                var checkuseredge : Bool = closestEdge.node_u==k!.node_u && closestEdge.node_v==k!.node_v
                
                print("checkuseredge", checkuseredge, "distanceFromCurrentEdge<closestEdge.radiusOfNavigationArea = \(distanceFromCurrentEdge)<\(closestEdge.radiusOfNavigationArea)", "distanceFromCurrentEdge>closestEdge.radiusOfNavigationArea*percentage","\(distanceFromCurrentEdge)>\(closestEdge.radiusOfNavigationArea*percentage)", "distance<closestEdge.radiusOfNavigationArea","\(distance)<\(closestEdge.radiusOfNavigationArea)")
                
                if checkuseredge==true && distanceFromCurrentEdge<closestEdge.radiusOfNavigationArea && distanceFromCurrentEdge>closestEdge.radiusOfNavigationArea*percentage && distance < closestEdge.radiusOfNavigationArea {
                    flag = false
                    print("false")
                    break
                } else if checkuseredge==false && data!.distance < k!.radiusOfNavigationArea*percentage {
                    flag = false
                    break
                } else {
                    flag = true
                    print("false")
                }
            }
        }
        
        /*for edge in edges_user {
            let vertex_u = position_vertexes["\(edge.u)"]!
            let vertex_v = position_vertexes["\(edge.v)"]!
            let p1X:Float = vertex_u["x"] ?? 0
            let p1Y:Float = vertex_u["y"] ?? 0
            let p2X:Float = vertex_v["x"] ?? 0
            let p2Y:Float = vertex_v["y"] ?? 0
            let data = level2.getClosestPointOnEdge(position: (px:currentX,py:currentY), p1X: p1X, p1Y: p1Y, p2X: p2X, p2Y: p2Y)
            var k : Link? = level2.edgeToLink(links: links,edge: edge)
            // IN THIS CASE I CHECK IF THE TARGET CAN CHANGE
            // if there is only one edge, the target will not change. Indeed,
            // CONDITIONS:
            // k = for recovering the link related to the "edge" and know how much is the radius of the "edge"
            // data!.distance = perpendicular distance from the edge k.
            // distance = distance to the actual target.
            // k!.radiusOfSafeArea*percentage = D1 limit of edge k.
            // data!.distance < k!.radiusOfSafeArea*percentage = here I check if the user is D2 with respect to the edge k (not in D1).
            // k!.radiusOfSafeArea*percentage < distance < k!.radiusOfSafeArea = check if the user is actually arrived near the current target point at least in D2 of the edge k.
            if (data!.distance < k!.radiusOfNavigationArea*percentage && distance > k!.radiusOfNavigationArea*percentage && distance < k!.radiusOfNavigationArea ) {
                flag = true
            }
        }*/
    }
    
    func outputLevel2(currentX: Float, currentY: Float, previous_state: String, edges_user: inout [any Edge], edges_destination: inout [any Edge] , num_shared_edges_user_destination: Int){
        // GET USER EDGE
        
        // there's the need to find the width of the closest edge everytime to understand if the user is entered enough. This is because the width of the edge can change from a setup version (based and advanced). one code for both cases.
        print(edges_user.count, edges_user)
         if edges_user.count != 0{
             (closest_edge,distanceFromCurrentEdge, _, _) = level2.getClosestEdge(position_u: (px:currentX,py:currentY), edges: edges_user, percentage: percentage, position_vertexes: level1!.position_vertexes, links: links)
        }
        print(closest_edge,distanceFromCurrentEdge)
        
        let vertex_u = position_vertexes["\(closest_edge!.node_u)"]!
        let vertex_v = position_vertexes["\(closest_edge!.node_v)"]!
        let p1X:Float = vertex_u["x"] ?? 0
        let p1Y:Float = vertex_u["y"] ?? 0
        let p2X:Float = vertex_v["x"] ?? 0
        let p2Y:Float = vertex_v["y"] ?? 0
        length_closest_edge = level2.distanceBetweenTwoPoints2D(p1x: p1X, p1y: p1Y, p2x: p2X, p2y: p2Y)
        var x_point_on_closest_edge : Float = 0.0
        var y_point_on_closest_edge : Float = 0.0
        var dx_point_on_closest_edge : Float = 0.0
        var dy_point_on_closest_edge : Float = 0.0
        // distanceFromCurrentEdge = level2.getDistanceOnPointOnEdge(position: (px: currentX, py: currentY), p1X: p1X, p1Y: p1Y, p2X: p2X, p2Y: p2Y) cambio con il solito perchè questo metodo ritorna solo la distanza
        // (distance: Float, x_point: Float, y_point: Float, dx: Float, dy: Float, t: Float)
        var pointOnEdge = level2.getClosestPointOnEdge(position: (px: currentX, py: currentY), p1X: p1X, p1Y: p1Y, p2X: p2X, p2Y: p2Y)
        distanceFromCurrentEdge = pointOnEdge!.distance
        dxFromCurrentEdge = pointOnEdge!.dx
        dyFromCurrentEdge = pointOnEdge!.dy
        
        print(pointOnEdge)
        
        // IN TEORIA FUNZIONA!
        
        var flag : Bool = false
        if edges_user.count != 0 {
            checkDistanceFromSnap(edges_user, currentX, currentY, closest_edge ?? links[0], distanceFromCurrentEdge, &flag)
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
        // OUTSIDE NAVIGATION AREA
        if(edges_user.count==0 || (previous_state=="outside" && level2.checkIfUserIsEnteredAtLeastPercentageOfRadius(distance: abs(distanceFromCurrentEdge), radius: closest_edge!.radiusOfNavigationArea, percentage: percentage))){ // level2.checkIfUserIsEnteredAtLeastPercentageOfRadius(distance: abs(distance), radius: closest_edge!.radiusOfSafeArea, percentage: percentage))){
            print("if outside")
            
            //(target_x_map, target_y_map, x_return_map, y_return_map, closest_edge) = level2.getClosestPointInSafeArea(position_u: (px:currentX,py:currentY), input_Graph: level1!.graph, percentage: percentage, position_vertexes: level1!.position_vertexes, links: links) // MARK: TARGET IS A POINT IN THE SAFE AREA OF THE CLOSEST EDGE THAT LEAD TO THE DESTINATION IN LESS TIME.
        
            //TODO DEFINIRE UN EDGE OUTSIDE CHE DEVE ESSERE COSTANTE A QUELLO PRECEDENTE
            
            var target_on_edge_description = "u=\(closest_edge!.node_u)-v=\(closest_edge!.node_v)"
            debug_point_of_return.text = "t_x: \(reduceResolution(value:target_x_map,100)) t_y: \(reduceResolution(value:target_y_map,100)) edge: \(target_on_edge_description)"
            state_user.text="OUTSIDE"
            nextTargetLabel.text="T: point on edge"
            state = "outside"
            inside_outside.text = "I/O: outside"
            
        } else if(num_shared_edges_user_destination > 0){ // DESTINATION ON THE SAME EDGE OF THE USER POSITION
            if (distanceBetweenTwoPoints2D(p1x: currentX, p1y: currentY, p2x: level1!.destination_position["x"]!, p2y: level1!.destination_position["y"]!) < level1!.radius_destination) {
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
                target_x_map = level1!.destination_position["x"]!
                target_y_map = level1!.destination_position["y"]! // MARK: TARGET IS THE DESTINATION
                state = "inside"
                state_user.text=state
                nextTargetLabel.text="T: destination"
                inside_outside.text = "I/O: inside near destination"
                debug_point_of_return.text = ""
                nextNode="destination"
                if nextNode != previous_node {
                    changeNode = true
                } else {
                    changeNode = false
                }
                previous_node = nextNode
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
            
            print("DEBUG1","previous_node",previous_node,"actual_node",nextNode)
            // check if the node change
            if nextNode != previous_node {
                changeNode = true
            } else {
                changeNode = false
            }
            previous_node = nextNode
            print("DEBUG2","previous_node",previous_node,"actual_node",nextNode)
            
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
    
    /*
     TODO LIST:
     - togliere la questione degli stati. per arrived metti un valore booleano.
     
     */
    
    
    //@objc func evaluatePose(){
    func evaluatePose(newLocation: ApproxLocation){
        if startLog{
            print(startLog)
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
                if (abs(previous_currentX_map - currentX_map)>1 || abs(previous_currentY_map - currentY_map)>1) && previous_currentX_map != 0 && previous_currentY_map != 0 {
                    //level4.speak(message: "update", state: state, changeNode: false, changePath: false, repeatInstructionFlag: false)
                    //level4.playUpdateSound()
                    // BIG JUMP
                    JUMPDEBUG.text = "JUMP X:\(reduceResolution(value: currentX_map, 100)),Y:\(reduceResolution(value: currentY_map, 100)), J: \(reduceResolution(value: distanceBetweenTwoPoints2D(p1x: currentX_map, p1y: previous_currentX_map, p2x: currentY_map, p2y: previous_currentY_map), 100))"
                    // TODO: inserire earcon? forse troppo
                    level4.jumpSound()
                    level4.emergencySound()
                    
                } else if (abs(previous_currentX_map - currentX_map)>0.3 || abs(previous_currentY_map - currentY_map)>0.3) && previous_currentX_map != 0 && previous_currentY_map != 0 {
                    //level4.speak(message: "update", state: state, changeNode: false, changePath: false, repeatInstructionFlag: false)
                    //level4.playUpdateSound()
                    // BIG JUMP
                    JUMPDEBUG.text = "JUMP X:\(reduceResolution(value: currentX_map, 100)),Y:\(reduceResolution(value: currentY_map, 100)), J: \(reduceResolution(value: distanceBetweenTwoPoints2D(p1x: currentX_map, p1y: previous_currentX_map, p2x: currentY_map, p2y: previous_currentY_map), 100))"
                    // TODO: inserire earcon? forse troppo
                    level4.jumpSound()
                }
                previous_currentX_map = currentX_map
                previous_currentY_map = currentY_map
                
                // DEBUG markers: number of markers, which markers were detected and error pose.
                //print(arView.session.currentFrame?.anchors)
                whichMarkersWereDetected = ""
                numMarker = 0
                var x_marker : Float = 0.0
                var y_marker : Float = 0.0
                var last_img_anchor : ARAnchor? = nil
                for anchor in arView.session.currentFrame?.anchors ?? [] {
                //for anchor in self.locationProvider.arView.session.currentFrame?.anchors ?? [] {
                    if ((anchor as? ARImageAnchor) != nil) {
                        whichMarkersWereDetected = "\(anchor.name!),  \(whichMarkersWereDetected)"
                        last_img_anchor = anchor
                        lastMarkerSeen = anchor.name!
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
                    X_error_img.text="err x img = \(reduceResolution(value: last_img_anchor!.transform.columns.3.x-x_marker, 1000))" // TODO: check if is correct
                    Y_error_img.text="err y img = \(-reduceResolution(value: last_img_anchor!.transform.columns.3.z-y_marker, 1000))"
                    //JUMPDEBUG.text="z img = \(reduceResolution(value: last_img_anchor!.transform.columns.3.y, 1000))"
                }
                numMarkersLabel.text = "# Mark: \(numMarker)"
                markerNameLabel.text = whichMarkersWereDetected
                
                var previous_state = state
                
                E_u = level2.getEdgesAtPosition(position: (px:currentX_map,py:currentY_map), input_Graph: level1!.graph, position_vertexes: level1!.position_vertexes, links: links)
                //print(E_u)
                // GET DESTINATION EDGE
                E_d = level2.getEdgesAtPosition(position: (px:destination_position["x"]!,py:destination_position["y"]!), input_Graph: level1!.graph, position_vertexes: level1!.position_vertexes, links: links)
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
                    /*var anglePath = atan2(dy,dx)-(Float.pi/2)
                    
                    //anglePath = ((anglePath+900).truncatingRemainder(dividingBy: 360))-180 // ? TODO: SI O NO
                    
                    let debugAngle = reduceResolution(value: rad2degree(anglePath), resolution)
                    anglePathLabel.text = "ang path: \(debugAngle)"
                    
                    // ANGLE DEBUG
                    //var angular_difference = rad2degree(currentYAW_arkit-anglePath)
                    var angular_difference = rad2degree(currentYAW-anglePath)
                    
                    angular_difference = ((angular_difference+900).truncatingRemainder(dividingBy: 360))-180 // TODO: FUNZIONA MA NON È EFFICIENTE*/
                    
                    var anglePath = atan2(dy,dx)-(Float.pi/2)
                    
                    anglePath = ((rad2degree(anglePath)+900).truncatingRemainder(dividingBy: 360))-180 // ? TODO: SI O NO
                    
                    let debugAngle = reduceResolution(value: anglePath, resolution)
                    anglePathLabel.text = "ang path: \(debugAngle)"
                    
                    // ANGLE DEBUG
                    //var angular_difference = rad2degree(currentYAW_arkit-anglePath)
                    var angular_difference = rad2degree(currentYAW)-anglePath
                    
                    angular_difference = ((angular_difference+900).truncatingRemainder(dividingBy: 360))-180
                    
                    //angular_difference = doit(a:angular_difference) // DOESN'T WORK
                    
                    
                    // TODO: CHECK
                    /*if abs(angular_difference) > 180{
                        angular_difference = -min(360-abs(angular_difference), abs(angular_difference))
                    }*/
                    
                    angular_error_label.text = "ang err: \(reduceResolution(value: angular_difference,100))"
                    lateralDistanceLabel.text = "lateral dist: \(reduceResolution(value: distanceFromCurrentEdge, 100))"
                    
                    let direction = angular_difference>0 && angular_difference < 180 ? "Right":"Left" // TODO: quando sono fuori dalla safe area la prima volta mi dice la direzione sbagliata.... le volte successive è corretta. devi capire perchè.
                    distance = distanceBetweenTwoPoints2D(p1x: target_x_map, p1y: target_y_map, p2x: currentX_map, p2y: currentY_map)
                    let distanceFromPath = direction == "Left" ? -distance:distance
                    
                    distance_from_next_target_label.text = "dist target: \(reduceResolution(value: distance,100))"
                    
                    if state=="outside"{
                        render.renderTarget(x:x_return_map, y:y_return_map, arView: arView)
                    } else {
                        render.renderTarget(x:target_x_map, y:target_y_map, arView: arView)
                    }
                    
                    if version_setup == "advanced" {
                        var cateto1 = num_shared_edges_user_destination>=1 ? radius_destination : closest_edge!.radiusOfNavigationArea
                        var alpha = rad2degree(asin(cateto1/abs(distance)))
                        if alpha.isNaN {
                            alpha = 90.0
                        }
                        print("alpha",alpha)
                        range = max(alpha,level3.alpha3)
                    } else {
                        range=level3.alpha3
                    }
                    range_of_directions_debug.text="range: \(reduceResolution(value: range, 1000))"
                    
                    timerLabel.text = "timer: \(Int(CFAbsoluteTimeGetCurrent()-level4.timerRepeatInstruction))"

                    // MARK: LEVEL 3
                    print("level3")
                    // GENERATE MESSAGE
                    let new_message = level3.generateMessage(angular_error: abs(angular_difference), current_state: state, changeNode: changeNode, version_setup: version_setup, range: range, lateralDistance: distanceFromCurrentEdge, timerRepeatInstruction: level4.timerRepeatInstruction)
                    
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
                        if abs(distance)>closest_edge!.radiusOfNavigationArea*percentage {
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
                    
                    level4.speak(message: message, angular_difference: angular_difference, range: range, distanceFromTarget: distance, safeAreaRadius: closest_edge!.radiusOfNavigationArea*percentage, lateralDistance: max(distanceFromCurrentEdge-closest_edge!.radiusOfNavigationArea*percentage,0), direction: direction, movement: movement, state: state, changeNode: changeNode, changePath: changePath, repeatInstructionFlag: repeatInstructionFlag) // max(abs(distanceFromCurrentEdge)-closest_edge!.radiusOfNavigationArea*percentage,0) cambio distanceFromCurrentEdge
                    // TODO: DARE IN INPUT L'ANGOLO DI ISTRUZIONE PER CONTROLLO ANGOLO.
                    
                    level4debug.text="LV4: \(level4.debugConditions)"
                    
                    if taskTest {
                        if level4.startSonification{ //message != new_message || message=="" {
                            angtarget = "\(angular_difference)"
                            distTarget = "\(distance)"
                        } else {
                            angtarget = ""
                            distTarget = ""
                        }
                        
                        /*guard level4.angleLength==nil else {
                            targetAngleLabel.text = "t ang: \(reduceResolution(value: level4.angleLength!, 1000)),  \(level4.startSonification)"
                            return // TODO: PERCHÈ
                        }*/
                        targetAngleLabel.text = "t ang: \(reduceResolution(value: level4.angleLength ?? 0 , 1000)),  \(level4.startSonification)"
                        var yaw_fixing_gap_map = 0.0
                        var rototraslFix : simd_float4x4 = matrix_identity_float4x4
                        if locationProvider.fixPosition {
                            var yaw_fixing_gap_map = locationProvider.alpha
                            var rototraslFix = locationProvider.newWorldTransform
                            x_fixing_gap_map = locationProvider.x_t
                            y_fixing_gap_map = locationProvider.y_t
                        } else {
                            x_fixing_gap_map = 0.0
                            y_fixing_gap_map = 0.0
                        }
                        
                        sonification_rate.text="sonif rate: \(reduceResolution(value: level4.sonif_rate, 100))"
                        let dato = distanceFromCurrentEdge-closest_edge!.radiusOfNavigationArea*percentage
                        calcolo_lateral_offset.text = "lat off: \(reduceResolution(value: dato, 100))  \(reduceResolution(value: level4.stretchLength ?? 0, 100))"
                    
                        // LOG DATA
                        // which data: x, y, z, roll, pitch, yaw, ang error, ang target, dist next target, dist target, x_gap_correction, y_gap_correction, next node, direction, state, message, start log, start sonification
                        
                        var timestamp:String = "\(NSDate().timeIntervalSince1970 * 1000)"
                        let text="\(timestamp);\(currentX_map);\(currentY_map);\(currentZ_map);\(currentROLL);\(currentPITCH);\(currentYAW);\(lastMarkerSeen);\(locationProvider.fixPosition);\(x_fixing_gap_map);\(y_fixing_gap_map);\(yaw_fixing_gap_map);\(rototraslFix);\(anglePath);\(rad2degree(currentYAW));\(angular_difference);\(direction);\(range);\(nextNode);\(target_x_map);\(target_y_map);\(distance);\(closest_edge!.node_v);\(closest_edge!.node_u);\(closest_edge!.radiusOfNavigationArea);\(length_closest_edge);\(distanceFromCurrentEdge);\(dxFromCurrentEdge);\(dyFromCurrentEdge);\(state);\(message);\(previous_message_label.text);\(startLog);\(level4.startSonification);\(level4.readInstruction);\(version_setup);\(percorso);\(level4.num_turn);\(level4.num_walk);\(level4.num_lateral)"
                        // TODO lastMarkerSeen--> Check se puoi migliorare questo dato
                        log.logAsync(logDescription: text)
                    }
                    
                }
                else {
                    if !saidArrived {
                        message = "destinazione raggiunta"//"Destination Reached"
                        level4.speak(message: message, state: state,changeNode: changeNode, changePath: changePath, repeatInstructionFlag: repeatInstructionFlag)
                    }
                    Synth.shared.volume = 0
                    Synth.shared.frequency = 0
                    saidArrived = true
                    if taskTest{
                        saveData()
                    } else {
                        resetTest()
                    }
                }
            } else {
                repeat_pose_evaluation = false
                Synth.shared.volume = 0
                Synth.shared.frequency = 0
                if message != "destinazione raggiunta" { //}"Destination Reached"{
                    message = "destinazione raggiunta"//"Destination Reached"
                    level4.speak(message: message, state: state,changeNode: changeNode, changePath: changePath, repeatInstructionFlag: repeatInstructionFlag)
                    if taskTest{
                        saveData()
                    } else {
                        resetTest()
                    }
                }
            }
        }
    }
    
    func debugPose(_ currentX_map:Float, _ currentY_map:Float, _ currentZ_map:Float, _ currentROLL: Float, _ currentYAW: Float, _ currentPITCH: Float, _ resolution: Float){
        x_user.text="user x=\(reduceResolution(value: currentX_map, resolution))"
        y_user.text="user y=\(reduceResolution(value: currentY_map, resolution))"
        //z_user.text="user z=\(reduceResolution(value: currentZ_map, resolution))"
        //roll_user.text="user roll=\(reduceResolution(value: rad2degree(currentROLL), resolution))"
        yaw_user.text="user yaw=\(reduceResolution(value: rad2degree(currentYAW), resolution))"
        pitch_user.text="user pitch=\(reduceResolution(value: rad2degree(currentPITCH), resolution))"
    }
    
    func debugPose2(_ currentX_map:Float, _ currentY_map:Float, _ currentYAW: Float, _ currentPITCH: Float, _ approxRadius: Float, _ approxAngle: Float, _ resolution: Float){
        x_user.text="user x=\(reduceResolution(value: currentX_map, resolution))"
        y_user.text="user y=\(reduceResolution(value: currentY_map, resolution))"
        yaw_user.text="user yaw=\(reduceResolution(value: rad2degree(currentYAW), resolution))"
        pitch_user.text="user pitch=\(reduceResolution(value: rad2degree(currentPITCH), resolution))"
        approx_radius_debug.text="approx radius=\(reduceResolution(value: approxRadius, resolution))"
        approx_angle_debug.text="approx angle=\(reduceResolution(value: rad2degree(approxAngle), resolution))"
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
    
    @IBAction func newDestination(_ sender: Any) {
        /*if destination == "D" {
            destination = "A"
            destination_position = ["x": 5.6, "y": -28.8]
            level4.feedback("DES \(destination)")
        } else if destination == "A" {
            destination = "B"
            destination_position = ["x": 0.4, "y": -0.4]
            level4.feedback("DES \(destination)")
        } else if destination == "B" {
            destination = "C"
            destination_position = ["x":11.4,"y":-22.10]
            level4.feedback("DES \(destination)")
        } else if destination == "C" {
            destination = "D"
            destination_position = ["x": 8.4,"y":-22.00]
            level4.feedback("DES \(destination)")
        }*/
        if percorso == "Percorso1"{
            percorso = "Percorso2"
        }
        else if percorso == "Percorso2"{
            percorso = "Percorso3"
        }
        else if percorso == "Percorso3"{
            percorso = "Percorso4"
        } else if percorso == "Percorso4"{
            percorso = "Percorso1"
        }
        /*if percorso == "Percorso1"{
            percorso = "Percorso2"
        }
        else if percorso == "Percorso2"{
            percorso = "Percorso1"
        }*/
        level4.feedback("\(percorso)")
        setupARConfiguration()
    }
    
    
    @IBAction func changeMode(_ sender: Any) {
        if version_setup == "basic" {
            version_setup = "advanced"
            let setup_message : String = "advance VERSION"
            Toast.show(message: setup_message, bgColor: UIColor.yellow, textColor: .black,labelFont: .boldSystemFont(ofSize: 14),showIn: .top,controller: self)
            level4.feedback("A")
        } else if version_setup == "advanced" {
            version_setup = "basic"
            let setup_message : String = "basic VERSION"
            Toast.show(message: setup_message, bgColor: UIColor.yellow, textColor: .black,labelFont: .boldSystemFont(ofSize: 14),showIn: .top,controller: self)
            level4.feedback("B")
        }
    }
    
    // DEBUG
    fileprivate func debugLabels() {
        // DEBUG STATE AND NEXTNODE
        debug_dx_dy_point_of_return.frame = CGRect(x: 10, y: 0, width: 300, height: 100)
        debug_dx_dy_point_of_return.text = "dx: dy:"
        debug_dx_dy_point_of_return.textColor = UIColor.black
        view.addSubview(debug_dx_dy_point_of_return)
        
        debug_point_of_return.frame = CGRect(x: 10, y: 0, width: 300, height: 150)
        debug_point_of_return.text = "t_x: t_y:"
        debug_point_of_return.textColor = UIColor.black
        view.addSubview(debug_point_of_return)
        
        lateralDistanceLabel.frame = CGRect(x: 240, y: 0, width: 300, height: 100)
        lateralDistanceLabel.text = "lateral distance:"
        lateralDistanceLabel.textColor = UIColor.black
        view.addSubview(lateralDistanceLabel)
        
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
        
        /*z_user.frame = CGRect(x: 10, y: 0, width: 300, height: 600)
         z_user.text = "Z USER"
         z_user.textColor = UIColor.black
         view.addSubview(z_user)*/
        approx_radius_debug.frame = CGRect(x: 10, y: 0, width: 300, height: 600)
        approx_radius_debug.text = "APPROX RADIUS"
        approx_radius_debug.textColor = UIColor.green
        view.addSubview(approx_radius_debug)
        
        // LEVEL 4 DEBUG
        level4debug.frame = CGRect(x: 240, y: 0, width: 300, height: 450)
        level4debug.text = "LV4 DEBUG"
        level4debug.textColor = UIColor.blue
        view.addSubview(level4debug)
        
        // DEBUG ROLL YAW PITCH ARKIT
        
        // MARK: IMPORTANT
        yaw_user.frame = CGRect(x: 240, y: 0, width: 300, height: 500)
        yaw_user.text = "YAW USER"
        yaw_user.textColor = UIColor.red
        view.addSubview(yaw_user)
        
        pitch_user.frame = CGRect(x: 240, y: 0, width: 300, height: 550)
        pitch_user.text = "PITCH USER"
        pitch_user.textColor = UIColor.black
        view.addSubview(pitch_user)
        
        /*roll_user.frame = CGRect(x: 240, y: 0, width: 300, height: 600)
         roll_user.text = "ROLL USER"
         roll_user.textColor = UIColor.black
         view.addSubview(roll_user)*/
        approx_angle_debug.frame = CGRect(x: 240, y: 0, width: 300, height: 600)
        approx_angle_debug.text = "APPROX ANGLE"
        approx_angle_debug.textColor = UIColor.green
        view.addSubview(approx_angle_debug)
        
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
        
        calcolo_lateral_offset.frame = CGRect(x: 0, y: 0, width: 250, height: 700)
        calcolo_lateral_offset.text = "lat sonif:"
        calcolo_lateral_offset.textColor = UIColor.red
        view.addSubview(calcolo_lateral_offset)
        
        sonification_rate.frame = CGRect(x: 240, y: 0, width: 250, height: 700)
        sonification_rate.text = "sonif rate:"
        sonification_rate.textColor = UIColor.red
        view.addSubview(sonification_rate)
        
        
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
        
        X_error_img.frame = CGRect(x: 240, y: 0, width: 300, height: 900)
        X_error_img.text = "x error img"
        X_error_img.textColor = UIColor.black
        view.addSubview(X_error_img)
        
        Y_error_img.frame = CGRect(x: 240, y: 0, width: 300, height: 950)
        Y_error_img.text = "y error img"
        Y_error_img.textColor = UIColor.black
        view.addSubview(Y_error_img)
        
        JUMPDEBUG.frame = CGRect(x: 240, y: 0, width: 300, height: 1000)
        JUMPDEBUG.text = "jump"
        JUMPDEBUG.textColor = UIColor.black
        view.addSubview(JUMPDEBUG)
        
        range_of_directions_debug.frame = CGRect(x: 240, y: 0, width: 300, height: 1050)
        range_of_directions_debug.text = "range"
        range_of_directions_debug.textColor = UIColor.black
        view.addSubview(range_of_directions_debug)
        
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
    }
    
}

extension Array where Element: Equatable {
    func contains(subarray: [Element]) -> Bool {
        guard subarray.count <= count else { return false }
    
        for idx in 0 ... count - subarray.count {
            let start = index(startIndex, offsetBy: idx)
            let end = index(start, offsetBy: subarray.count)
            if Array(self[start ..< end]) == subarray { return true }
        }
        return false
    }
}



