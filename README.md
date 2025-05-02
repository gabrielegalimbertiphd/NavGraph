# NavGraph
NavGraph: enhancing blind travelers’ navigation experience and
safety

## Running the code:
1. Download the code
2. Open the file "STTN.xcodeproj" with XCode
3. Change the spatial representation in the file "data.json" and insert all the positions of the markers in each path "PercorsoX.json"
4. The code uses the library "PositioningLibrary" available at the link https://github.com/tirannosario/PositioningLibrary. Import the library as external dependency if it is not in the main folder of the project. In this project, the library "PositioningLibrary" is already in the main folder.
5. Import the Package Dependencies "Drops" (version 1.6.1) and "SwiftGraph" (version 3.1.0).
6. Run the code
7. Frame the first marker in the path "PercorsoX" (name of the image "initX") and start the navigation towards the destination. The code is set to work from the first turning point.

## Specification of the spatial representation:
The four routes used for the experiments as well as the images of the visual markers used in these routes are contained in the folder "STTN".

The file "data.json" contains all the information of the navigation graph.
- The "vertexes" field contains all the vertexes names (eg. "1","2",...).
- The "coordinates_position_vertexes" field contains the coordinate of each node ("x" and "y") of all of yours navigation graphs.
- The "position_vertexes" field contains the coordinate of each node ("x" and "y") of one of yours navigation graph (it is usefull for initialization).
- The "destination_position" field contains the coordinate of the destination of one of yours navigation graph.
The "linksOfPaths" field contains all the edges (connections) of your navigation graphs. Each path is defined by a set of links between two nodes, labeled "node_u" and "node_v", along with the size of the corresponding navigation area.
- The "links" field contains the edges of one of your navigation graph (it is usefull for initialization). For the single graph, there are the edges between one node and another ("node_u" and "node:_v" with the related navigation area size).
- The "fixedWidthSafeArea" field contains the navigation area sizes just in case the designer forgot to set them.
- The restricted navigation area are half of the navigation area size. It is not necessary define the restricted navigation areas in this code.

## Markers
The file "PercorsoX.json" (X as the name of the path) define the position of each marker in the environment. The markers are used to correct the drift of the navigation system.
- The "buildings" field defines the name of the building with ID, latitude, longitude and name.
- The "floors" field defines the name of the building floor with ID, number, id of the building, maxwidth and maxheight in the map, name of the floormap and comments.
- For each marker there is an id, name of the image, physical width of the image, and location of the image ("x" and "y" in meters, "heading" in radiant, "floor" is the name of the floor").


All the images of the markers are contained in the folder "Assets.xcassets/Percorso.arresourcegroup".
The image of the floor is contained in the folder "Assets.xcassets/cortile.imageset".

  


