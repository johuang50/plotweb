import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart';
import 'package:graphview/GraphView.dart';

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

Future<List<Character>> characters() async {
  // Get a reference to the database.
  final db = await database;

  // Query the table for all the dogs.
  final List<Map<String, Object?>> charMaps = await db.query('Characters');

  // Convert the list of each dog's fields into a list of `Dog` objects.
  return [
    for (final {
          'charid': charid as int,
          'name': name as String,
        } in charMaps)
      Character(charid: charid, name: name),
  ];
}
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final String dbPath = join(await getDatabasesPath(), 'character.db');
  await deleteDatabase(dbPath);
  database = openDatabase(
  join(await getDatabasesPath(), 'character.db'),
   onCreate: (db, version) {
    // Run the CREATE TABLE statement on the database.
    return db.execute(
      'CREATE TABLE Characters(charid INTEGER PRIMARY KEY, name TEXT)',
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
        home: GraphScreen(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //var appState = context.watch<MyAppState>();

    return Scaffold(
      appBar: AppBar(title: Text('Home Page')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 600,
            child: ElevatedButton(
            style: StandardButtonTheme.primaryButtonStyle,
              onPressed: () async{
                   Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CharacterListPage(),
                  ),
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => UpdatePage()),
                );
              },
              child: Text('Sophie'),
            ),
          ),
          Positioned(
          bottom: 100,
          child: ElevatedButton(
            style: StandardButtonTheme.primaryButtonStyle,
              onPressed: () async{
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddCharacter()),
                );
                 var fido = Character(name: 'Fido');
                  await insertChar(fido);

                  // Fetch all characters from the database to verify
                  List<Character> allCharacters = await characters();
                  print('Characters in the database:');
                  for (var character in allCharacters) {
                    print(character); // This will print the character toString().
                  }
              },
              child: Text('Add Character'),
          ),
        )
        ]
      ),
    );
  }
}

class CharacterPage extends StatelessWidget {
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;
    return Scaffold(
      appBar: AppBar(title: Text('Character Page')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
          bottom: 600,
          child: ElevatedButton(
            style: StandardButtonTheme.primaryButtonStyle,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UpdatePage()),
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
                print('delete');
              },
              child: Text('Delete'),
            ),
          ),
          Positioned(
            bottom: 200,
            child: ElevatedButton(
              style: StandardButtonTheme.primaryButtonStyle,
                onPressed: () {
                  print('Close');
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

class UpdatePage extends StatelessWidget {
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    return Scaffold(
      appBar: AppBar(title: Text(' Update Character ')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
          bottom: 100,
          child: ElevatedButton(
            style: StandardButtonTheme.primaryButtonStyle,
              onPressed: () {
                print('update');
                Navigator.pop(context);
              },
              child: Text('Done'),
          ),
        )
        ]
      ),
    );
  }
}

class AddCharacter extends StatelessWidget {
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    return Scaffold(
      appBar: AppBar(title: Text('Add Character')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Positioned(
              bottom: 600,
              child: TextFormField(
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  hintText: "Name:",
                ),
              ),
            ),
          ),
          SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Positioned(
              bottom: 400,
              child: TextFormField(
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  hintText: "Add Relationships",
                ),
              ),
            ),
          ),
          SizedBox(height: 50),
          Positioned(
            bottom: 200,
            child: ElevatedButton(
              style: StandardButtonTheme.primaryButtonStyle,
                onPressed: () async {
                  print('saving');
                  Navigator.pop(context);
                },
                child: Text('Save Character'),
            ),
          ),
          SizedBox(height: 50),
          Positioned(
            bottom: 100,
            child: ElevatedButton(
              style: StandardButtonTheme.primaryButtonStyle,
                onPressed: () {
                  print('discard');
                  Navigator.pop(context);
                },
                child: Text('Discard Changes'),
            ),
          )
        ]
      ),
    );
  }
}

class Character {
  final int? charid;
  final String name;

  const Character({
    this.charid,
    required this.name
  });
    Map<String, Object?> toMap() {
    return {
      if (charid != null) 'charid': charid,
      'name': name
    };
  }

  @override
   String toString() {
    return 'Character{id: $charid, name: $name}';
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
    textStyle: TextStyle(fontSize: 30),
    foregroundColor: Colors.white,
    minimumSize: Size(200, 50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.horizontal())
  );
}

/* Graph stuff :) */

// class Node {
//   final String label;
//   final List<Node> children;

//   Node(this.label, [this.children = const []]);
// }

// Node rootNode = Node(
//   'Root',
//   [
//     Node('Node 1', [Node('Node 1.1'), Node('Node 1.2')]),
//     Node('Node 2', [Node('Node 2.1'), Node('Node 2.2')]),
//   ],
// );

Widget getButtonWidget(int id) {
  return ElevatedButton(
    onPressed: () {
      print('Button $id pressed');
      // Handle button press
    },
    child: Text('Button $id'),
  );
}

class GraphScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Graph graph = Graph()..isTree = true;

    Node node1 = Node(getButtonWidget(1));
    Node node2 = Node(getButtonWidget(2));
    Node node3 = Node(getButtonWidget(3));
    // ... add more nodes as needed

    graph.addEdge(node1, node2);
    graph.addEdge(node1, node3);
    // ... add more edges as needed

    // Define layout algorithm
    BuchheimWalkerConfiguration configuration = BuchheimWalkerConfiguration();
    BuchheimWalkerAlgorithm layoutAlgorithm = BuchheimWalkerAlgorithm(
      configuration,
      TreeEdgeRenderer(configuration),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Graph of Buttons'),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
            child: InteractiveViewer(
              constrained: false,
              boundaryMargin: EdgeInsets.all(100),
              minScale: 0.01,
              maxScale: 5.6,
              child: GraphView(
                graph: graph,
                algorithm: layoutAlgorithm,
                paint: Paint()
                  ..color = Colors.green
                  ..strokeWidth = 1
                  ..style = PaintingStyle.stroke,
                builder: (Node node) {
                  // Return a widget for each node
                  return node.data as Widget;
                }
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// https://docs.flutter.dev/cookbook/persistence/sqlite