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

// Future<void>InsertRel(Character character1, Character character2) async {
//   // Get a reference to the database.
//   final db = await database;

//   // Insert the Dog into the correct table. You might also specify the
//   // `conflictAlgorithm` to use in case the same dog is inserted twice.
//   //
//   // In this case, replace any previous data.
//   await db.insert(
//     'Rels',
//     character.toMap(),
//     conflictAlgorithm: ConflictAlgorithm.replace,
//   );
// }

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
  await deleteDatabase(dbPath);     //THIS L
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
        home: MyHomePage(),
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
    Graph graph = Graph()..isTree = true;

    // Add your nodes and edges here
    Node node1 = Node(IdButtonWidget(id: "Sophie"));
    Node node2 = Node(IdButtonWidget(id: "Fido"));
    Node node3 = Node(IdButtonWidget(id: "Lucy"));
    Node node4 = Node(IdButtonWidget(id: "Linus"));

    graph.addEdge(node1, node2, paint: Paint()..color = Colors.grey);
    graph.addEdge(node1, node3, paint: Paint()..color = Colors.grey);
    graph.addEdge(node2, node3, paint: Paint()..color = Colors.grey);
    graph.addEdge(node4, node3, paint: Paint()..color = Colors.grey);
    graph.addEdge(node4, node1, paint: Paint()..color = Colors.grey);
    // ... continue adding nodes and edges as needed

    var frAlgo = FruchtermanReingoldAlgorithm();
    
    return Scaffold(
      appBar: AppBar(title: Text('Home Page')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Positioned widget for the Sophie button
          Positioned(
            bottom: 600,
            child: ElevatedButton(
            style: StandardButtonTheme.primaryButtonStyle,
              onPressed: () async{
                   Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdatePage(),
                  ),
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => UpdatePage()),
                );
              },
              child: Text('Sophie'),
            ),
            // ... Existing code for the Sophie button
          ),
          // Positioned widget for the Add Character button
          Positioned(
            bottom: 100,
            child: ElevatedButton(
            style: StandardButtonTheme.primaryButtonStyle,
              onPressed: () async{
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddCharacter()),
                );
  

                  // Fetch all characters from the database to verify
              },
              child: Text('Add Character'),
          ),
            // ... Existing code for the Add Character button
          ),
          // Add a container for the GraphView
          Positioned(
            bottom: 300, // Adjust the position as needed
            child: Container(
              width: 300, // Set the width and height as needed
              height: 200,
              child: InteractiveViewer(
                constrained: false,
                boundaryMargin: EdgeInsets.all(100),
                minScale: 0.01,
                maxScale: 5.0,
                child: GraphView(
                  graph: graph,
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
}

class IdButtonWidget extends StatelessWidget {
  final String id;
  
  IdButtonWidget({required this.id});
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => print('Button $id pressed'),
      child: Text(id),
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

class AddCharacter extends StatefulWidget {
  @override
  _AddCharacterState createState() => _AddCharacterState();
}

class _AddCharacterState extends State<AddCharacter> {
  TextEditingController nameController = TextEditingController();
  TextEditingController relationshipsController = TextEditingController();

  @override
  void dispose() {
    // Dispose the controllers when the widget is removed from the
    // widget tree to avoid memory leaks.
    nameController.dispose();
    relationshipsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>(); 
    var pair = appState.current;
    String nameString = "";
    String relationshipsString = "";
    Map<String, bool> options = {
  };
    
    // _MyFormState form = _MyFormState(); // Remove this if you are not using it elsewhere
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
            SizedBox(height: 50),
            ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (BuildContext context, int index) {
                String key = options.keys.elementAt(index);
                CheckboxListTile(
                  title: Text(key),
                  value: options[key]!,
                  onChanged: (bool? value) {
                    setState(() {
                      options[key] = value!;
                    });
                  },
                );
              },
            ),
            SizedBox(height: 50),
            Center(
              child: ElevatedButton(
                style: StandardButtonTheme.primaryButtonStyle,
                onPressed: () async {
                  // Here we get the values from the text fields
                  nameString = nameController.text;
                  List<String> selectedOptions = [];
                  options.forEach((key, value) {
                    if (value) {
                      selectedOptions.add(key);
                    }
                  });
                  print('Selected Options: $selectedOptions');
                  // var fido = Character(name: nameString);
                  // await insertChar(fido);
                  Navigator.pop(context);
                },
                child: Text('Save Character'),
              ),
            ),
            SizedBox(height: 50),
            Center(
              child: ElevatedButton(
                style: StandardButtonTheme.primaryButtonStyle, 
                onPressed: () async {
                  // Here we get the values from the text fields
                  Navigator.pop(context);
                },
                child: Text('Discard'),
            ),
            ),// ... (other buttons or widgets can go here)
          ],
        ),
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

// https://docs.flutter.dev/cookbook/persistence/sqlite