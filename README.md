# NavGraph
NavGraph: enhancing blind travelers’ navigation experience and
safety

Running the code:
1. Download the code
2. Open the file "STTN.xcodeproj" with XCode
3. Change the spatial representation in the file "data.json" and insert all the position of the markers in each path "PercorsoX.json"
4. The code uses the library "PositioningLibrary" available at the link https://github.com/tirannosario/PositioningLibrary. Import the library as external dependency if it is not in the main folder of the project.
5. Import the Package Dependencies "Drops" (version 1.6.1) and "SwiftGraph" (version 3.1.0).
6. Run the code
7. Frame one marker in the path and start the navigation towards the destination.

Specification of the spatial representation:
The four routes used for the experiments as well as the images of the visual markers used in these routes are contained in the folder "STTN".

The file "data.json" contains all the information of the navigation graph.
- The "vertexes" field contain all the vertexes names (eg. "1","2",...).
- The field "coordinates_position_vertexes" contains the coordinate of each node ("x" and "y") of all of yours navigation graphs.
- The field "position_vertexes" contains the coordinate of each node ("x" and "y") of one of yours navigation graph (it is usefull for initialization).
- The field "destination_position" contains the coordinate of the destination of one of yours navigation graph.
- The field "linksOfPaths" contains the edges of all of your navigation graphs. For each path, there are the edges between one node and another ("node_u" and "node:_v" with the related navigation area size).
- The field "links" contains the edges of one of your navigation graph (it is usefull for initialization). For the single graph, there are the edges between one node and another ("node_u" and "node:_v" with the related navigation area size).
- The field "fixedWidthSafeArea" contains the navigation area sizes just in case the designer forgot to set them.
- The restricted navigation area are half of the navigation area size. It is not necessary define the restricted navigation areas in this code.

The file "PercorsoX.json" (X as the name of the path) define the position of each marker in the environment. The markers are used to correct the drift of the navigation system.
- the field "buildings" defines the name of the building with ID, latitude, longitude and name.
- the field "floors" defines the name of the building floor with ID, number, id of the building, maxwidth and maxheight in the map, name of the floormap and comments.
- For each marker there is an id, name of the image, physical width of the image, and location of the image ("x" and "y" in meters, "heading" in radiant, "floor" is the name of the floor").


All the images of the markers are contained in the folder "Assets.xcassets/Percorso.arresourcegroup".
The image of the floor is contained in the folder "Assets.xcassets/cortile.imageset".

  


