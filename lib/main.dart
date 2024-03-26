import 'dart:async';
import 'package:flutter/cupertino.dart';
// import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:english_words/english_words.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart';
import 'dart:math';
import 'package:graphview/GraphView.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

//import 'pacakge:getwidget/getwidget.dart';
late Future<Database> database;

Future<void> insertChar(Character character) async {
  // Get a reference to the database.
  final db = await database;

  // Insert the Dog into the correct table. You might also specify the
  // `conflictAlgorithm` to use in case the same dog is inserted twice.
  //
  // In this case, replace any previous data.
  await db.insert(
    'Characters',
    character.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<void> insertRel(int? character1, int? character2) async {
  // Get a reference to the database.
  final db = await database;

  // Determine the IDs to insert, ensuring id1 is always less than id2
  int charid1 = min(character1!, character2!);
  int charid2 = max(character1, character2);
  // Create a Relationships object with the determined IDs
  Relationship relationship = Relationship(charid1: charid1, charid2: charid2);

  // Insert the relationship into the database
  await db.insert(
    'Rels',
    relationship.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<void> deleteChar(int? killed) async {
  final db = await database;

  await db.transaction((txn) async {
    await txn.delete(
      'rels',
      where: 'charid1 = ? OR charid2 = ?',
      whereArgs: [killed, killed],
    );
    await txn.delete(
      'Characters',
      where: 'charid = ?',
      whereArgs: [killed],
    );
  });
}

Future<List<Relationship>> relationships() async {
  // Get a reference to the database.
  final db = await database;

  // Query the table for all the characters.
  final List<Map<String, Object?>> charMaps = await db.query('Rels');

  return [
    for (final {
          'charid1': charid1 as int,
          'charid2': charid2 as int,
        } in charMaps)
      Relationship(charid1: charid1, charid2: charid2),
  ];
}

Future<List<Character>> characters() async {
  // Get a reference to the database.
  final db = await database;

  // Query the table for all the characters.
  final List<Map<String, Object?>> charMaps = await db.query('Characters');

  return [
    for (final {
          'charid': charid as int,
          'name': name as String,
        } in charMaps)
      Character(charid: charid, name: name),
  ];
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final String dbPath = join(await getDatabasesPath(), 'character.db');
  // await deleteDatabase(dbPath); //THIS L
  database = openDatabase(
    join(await getDatabasesPath(), 'character.db'),
    onCreate: (db, version) async {
      // Run the CREATE TABLE statement on the database.
      await db.execute(
        'CREATE TABLE Characters(charid INTEGER PRIMARY KEY, name TEXT) ',
      );
      await db.execute(
        'CREATE TABLE Rels(charid1 INTEGER, charid2 INTEGER, ' +
            'PRIMARY KEY (charid1, charid2), FOREIGN KEY (charid1) references Characters(charid) ON DELETE CASCADE, FOREIGN KEY (charid2) references Characters(charid) ON DELETE CASCADE) ',
      );
    },
    // Set the version. This executes the onCreate function and provides a
    // path to perform database upgrades and downgrades.
    version: 1,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'PlotWeb',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        ),
        home: MyHomePage(key: myHomePageKey),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
}

Future<Graph> loadGraph() async {
  Graph graph = Graph()..isTree = true;

  // Load graph with characters already in the database
  Future<List<Character>> prevCharsFuture = characters();
  Future<List<Relationship>> prevRelsFuture = relationships();

  // When user finishes adding character, add nodes to the graph using vector of
  // nodes for relationships between characters
  List<Node> nodes =
      List<Node>.filled(441, Node(IdButtonWidget(name: "SOLOWAY", id: -12)));

  // Await prevCharsFuture to get the list of previous characters
  List<Character> prevChars = await prevCharsFuture;
  List<Relationship> prevRels = await prevRelsFuture;

  // Populate nodes list with previous characters
  for (Character character in prevChars) {
    nodes[character.charid ?? 0] =
        Node(IdButtonWidget(name: character.name, id: character.charid));
    graph.addNode(nodes[character.charid ?? 0]);
  }

  // Create example nodes

  // Check if the table is not empty

  for (Relationship rel in prevRels) {
    graph.addEdge(nodes[rel.charid1], nodes[rel.charid2], 
        paint: Paint()..color = Colors.black..strokeWidth = 3);
  }

  return graph;
}

final GlobalKey<_MyHomePageState> myHomePageKey = GlobalKey<_MyHomePageState>();

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}


class CustomLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Your custom line drawing logic goes here
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    // Sample line
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<Graph> _graphFuture;
  bool _isDragging = false;
  @override
  void initState() {
    super.initState();
    _graphFuture = loadGraph(); // Initialize the graph in initState.
  }

  void reloadData() {
    setState(() {
      // This updates the Future to reload the graph data.
      _graphFuture = loadGraph();
    });
  }

  Widget build(BuildContext context) {
    return FutureBuilder<Graph>(
      future: _graphFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // While waiting for the graph to load, you can show a loading indicator
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          // If an error occurred while loading the graph, show an error message
          return Text('Error loading graph: ${snapshot.error}');
        } else {

          // If the graph has loaded successfully, display the UI
          var graph = snapshot.data!; // Unwrap the graph from the snapshot

          // for(Node node in graph.nodes){
          //   node.position = Offset(120,280);
          //   break;
          // }
          
          var frAlgo = FruchtermanReingoldAlgorithm();
          // frAlgo.graphWidth = 100; // Adjust spacing
          // frAlgo.graphHeight = 100;
          // frAlgo.attractionRate = .2;
          // frAlgo.repulsionRate = 3;

          return Scaffold(
            appBar: AppBar(title: Text('Home Page')),
            body: Stack(
              alignment: Alignment.center,
              children: [
                // Positioned widget for the Sophie button
                // Positioned widget for the Add Character button
                Positioned(
                  bottom: 100,
                  child: ElevatedButton(
                    style: StandardButtonTheme.primaryButtonStyle,
                    onPressed: () async {
                      fetchData();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddCharacter()),
                      );
                    },
                    child: Text('Add Character'),
                  ),
                  // ... Existing code for the Add Character button
                ),
                Positioned(
                  bottom: 200, // Adjust the position as needed
                  child: Container(
                    width: 300, // Set the width and height as needed
                    height: 550,
                    child: InteractiveViewer(
                      constrained: false,
                      boundaryMargin: EdgeInsets.all(100),
                      minScale: 0.01,
                      maxScale: 5.0,
                      child: GraphView(
                        graph: graph, // Use the loaded graph
                        algorithm: frAlgo,
                        builder: (Node node) => node.data as Widget,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

// class _MyHomePageState extends State<MyHomePage> {
//   late Future<Graph> _graphFuture;
//   bool _isDragging = false;
//   @override
//   void initState() {
//     super.initState();
//     _graphFuture = loadGraph(); // Initialize the graph in initState.
//   }

//   void reloadData() {
//     setState(() {
//       // This updates the Future to reload the graph data.
//       _graphFuture = loadGraph();
//     });
//   }

//   Widget build(BuildContext context) {
//     return FutureBuilder<Graph>(
//       future: _graphFuture,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           // While waiting for the graph to load, you can show a loading indicator
//           return CircularProgressIndicator();
//         } else if (snapshot.hasError) {
//           // If an error occurred while loading the graph, show an error message
//           return Text('Error loading graph: ${snapshot.error}');
//         } else {

//           // If the graph has loaded successfully, display the UI
//           var graph = snapshot.data!; // Unwrap the graph from the snapshot

//           // for(Node node in graph.nodes){
//           //   node.position = Offset(120,120);
//           //   break;
//           // }
          
//           var frAlgo = FruchtermanReingoldAlgorithm();
//           //frAlgo.graphWidth = 100; // Adjust spacing
//           //frAlgo.graphHeight = 100;
//           //frAlgo.attractionRate = .2;
//           //frAlgo.repulsionRate = 3;
//           //frAlgo.iterations = 0;

//           // if (!_isDragging) {
//           //   frAlgo.iterations = 0; // Set iterationsPerRender to 0 to disable force calculations
//           // } else {
//           //   frAlgo.iterations = 1; // Set iterationsPerRender to 1 to enable force calculations
//           // }

//           return Scaffold(
//             appBar: AppBar(title: Text('Home Page')),
//             body: Stack(
//               alignment: Alignment.center,
//               children: [
//                 // Positioned widget for the Sophie button
//                 // Positioned widget for the Add Character button
//                 Positioned(
//                   bottom: 100,
//                   child: ElevatedButton(
//                     style: StandardButtonTheme.primaryButtonStyle,
//                     onPressed: () async {
//                       fetchData();
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (context) => AddCharacter()),
//                       );
//                     },
//                     child: Text('Add Character'),
//                   ),
//                   // ... Existing code for the Add Character button
//                 ),
//                 Positioned(
//                   bottom: 200, // Adjust the position as needed
//                   child: Container(
//                     width: 300, // Set the width and height as needed
//                     height: 550,
//                       child: GestureDetector(
//                       onPanStart: (_) {
//                         setState(() {
//                           _isDragging = true;
//                         });
//                       },
//                       onPanEnd: (_) {
//                         setState(() {
//                           _isDragging = false;
//                         });
//                       },
//                       child: GraphView(
//                         graph: graph, // Use the loaded graph
//                         algorithm: frAlgo,
//                         builder: (Node node) => node.data as Widget,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }
//       },
//     );
//   }
// }

int? selectedID;
String? selectedChar;

class IdButtonWidget extends StatelessWidget {
  final String name;
  final int? id;
  IdButtonWidget({required this.name, required this.id});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        selectedID = this.id;
        selectedChar = this.name;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CharacterPage(),
          ),
        );
      },
      style: GraphButton.primaryButtonStyle,
      child: Text(name),
    );
  }
}

class CharacterPage extends StatelessWidget {
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;
    return Scaffold(
      appBar: AppBar(title: Text('$selectedChar')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 600,
            child: ElevatedButton(
              style: StandardButtonTheme.primaryButtonStyle,
              onPressed: () {
                Future<List<String>> relatedCharacters =
                    getRelatedCharacterNames();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => UpdatePage(
                          relatedCharactersFuture: relatedCharacters)),
                );
              },
              child: Text('Update'),
            ),
          ),
          Positioned(
            bottom: 400,
            child: ElevatedButton(
              style: StandardButtonTheme.primaryButtonStyle,
              onPressed: () {
                deleteChar(selectedID);
                myHomePageKey.currentState?.reloadData();
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ),
          Positioned(
            bottom: 200,
            child: ElevatedButton(
              style: StandardButtonTheme.primaryButtonStyle,
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

// Future<List<int>> getRelatedCharacterIds(Database db, int charId) async {
//   final List<Map<String, dynamic>> maps = await db.rawQuery('''
//     SELECT
//       CASE
//         WHEN charid2 = ? THEN charid1
//         ELSE charid2
//       END as related_charid
//     FROM rels
//     WHERE charid1 = ? OR charid2 = ?
//   ''', [charId, charId, charId]);

//   // Extract the list of related character IDs.
//   List<int> relatedCharIds = maps.map((map) => map['related_charid'] as int).toList();
//   return relatedCharIds;
// }

Future<List<String>> getRelatedCharacterNames() async {
  // Fetch related character IDs.
  final db = await database;

  final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT 
      CASE 
        WHEN charid2 = ? THEN charid1 
        ELSE charid2 
      END as related_charid
    FROM rels
    WHERE charid1 = ? OR charid2 = ?
  ''', [selectedID, selectedID, selectedID]);

  // Extract the list of related character IDs.
  List<int> relatedCharIds =
      maps.map((map) => map['related_charid'] as int).toList();

  // Check if the list is empty to prevent an invalid SQL query.
  if (relatedCharIds.isEmpty) {
    // Return an empty list if no related character IDs are found.
    return [];
  }

  // Create the placeholders.
  String placeholders = List.filled(relatedCharIds.length, '?').join(', ');
  // Prepare the arguments.
  List<Object> whereArgs = relatedCharIds.map((id) => id as Object).toList();

  // Fetch the character names using the related character IDs.
  final List<Map<String, dynamic>> namesResult = await db.rawQuery(
    'SELECT name FROM characters WHERE charid IN ($placeholders)',
    whereArgs,
  );

  // Map the result to a list of names.
  List<String> names = namesResult.map((row) => row['name'] as String).toList();

  return names;
}

class UpdatePage extends StatelessWidget {
  final Future<List<String>> relatedCharactersFuture;

  UpdatePage({Key? key, required this.relatedCharactersFuture})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Update $selectedChar')),
      body: FutureBuilder<List<String>>(
        future: relatedCharactersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // While waiting for the future to resolve, show a loading indicator
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // If an error occurred, show an error message
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            // If the Future completes with no data, show a message
            return Center(child: Text('No related characters found.'));
          }

          // Data is fetched successfully, display the names
          String chars = snapshot.data!.join(',\n');
          if (chars == "" || chars == '\n') {
            chars = "None";
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(height: 30),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 50),
                    width: 300,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 106, 14, 7), 
                    ),
                    child: Column(
                      children: [
                        Text(
                          "How will this Affect:",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 30),
                        SingleChildScrollView(
                          child: Text(
                            chars,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AddCharacter extends StatefulWidget {
  @override
  _AddCharacterState createState() => _AddCharacterState();
}

Map<String, int?> char_to_id = {};
List<String> options = char_to_id.keys.toList();

void fetchData() async {
  char_to_id = {};
  options = [];
  Future<List<Character>> charList = characters();
  List<Character> chars = await charList;
  chars.forEach((character) {
    char_to_id[character.name] = character.charid;
  });
}

class _AddCharacterState extends State<AddCharacter> {
  TextEditingController nameController = TextEditingController();
  List<String> _selectedOptions = [];

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  List<MultiSelectItem<String>> get _items => char_to_id.keys
      .map((animal) => MultiSelectItem<String>(animal, animal))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Character')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: nameController, // Attach the controller here
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: "Character Name",
                hintText: "Enter character's name",
              ),
            ),
            SizedBox(height: 20),
            MultiSelectDialogField(
              items: _items,
              title: Text("Relationships"),
              selectedColor: Theme.of(context).primaryColor,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.all(Radius.circular(40)),
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              buttonText: Text(
                "Select Relationships",
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 16,
                ),
              ),
              onConfirm: (values) {
                setState(() {
                  _selectedOptions = values;
                });
              },
              initialValue: _selectedOptions,
            ),
            SizedBox(height: 20),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  String nameString = nameController.text;
                  if (nameString == "") {
                    showDialog(
                      context: context,
                      barrierDismissible:
                          false, // Dialog is not dismissed when user taps outside of it
                      builder: (BuildContext context) => AlertDialog(
                        content: Text("Characters must have a name"),
                      ),
                    );
                  } else {
                    Character character = Character(name: nameString);
                    insertChar(character);
                    for (String charName in _selectedOptions) {
                      int? char_id = char_to_id[charName];
                      final String dbPath =
                          join(await getDatabasesPath(), 'character.db');
                      final Database database = await openDatabase(dbPath);

                      final List<Map> result = await database.rawQuery(
                          'SELECT * FROM characters ORDER BY charid DESC LIMIT 1');
                      int curr_id = result.first['charid'] as int;
                      insertRel(curr_id, char_id);
                    }
                    myHomePageKey.currentState?.reloadData();
                    Navigator.pop(context);
                  }
                },
                child: Text('Save Character'),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                },
                child: Text('Discard'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Character {
  final int? charid;
  final String name;

  const Character({this.charid, required this.name});
  Map<String, Object?> toMap() {
    return {if (charid != null) 'charid': charid, 'name': name};
  }

  @override
  String toString() {
    return 'Character{id: $charid, name: $name}';
  }
}

class Relationship {
  final int charid1;
  final int charid2;

  const Relationship({required this.charid1, required this.charid2});
  Map<String, Object?> toMap() {
    return {
      'charid1': charid1,
      'charid2': charid2,
    };
  }

  @override
  String toString() {
    return 'Relationship{charid1: $int?, charid2: $int?}';
  }
}

class CharacterListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Characters List'),
      ),
      body: FutureBuilder<List<Character>>(
        future: characters(), // your characters() future from your code
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            // If we got data, show it in a ListView
            return ListView.builder(
              itemCount: snapshot.data?.length ?? 0,
              itemBuilder: (context, index) {
                Character character = snapshot.data![index];
                return ListTile(
                  title: Text(character.name),
                  // You can add more detail like an onTap action or a subtitle for Character ID
                );
              },
            );
          } else {
            // While fetching, show a loading spinner.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class StandardButtonTheme {
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Color.fromARGB(255, 106, 14, 7),
      textStyle: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
      foregroundColor: Colors.white,
      minimumSize: Size(200, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.horizontal()));
}

class GraphButton {
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Color.fromARGB(255, 106, 14, 7),
      textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      foregroundColor: Colors.white,
  );
}

// https://docs.flutter.dev/cookbook/persistence/sqlite
