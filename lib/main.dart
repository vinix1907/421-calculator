import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Für Speicherfunktion

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class Player {
  String name;
  int score;

  Player(this.name, this.score);
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: ScoreApp(toggleTheme: toggleTheme),
    );
  }

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }
}

class ScoreApp extends StatefulWidget {
  final VoidCallback toggleTheme;
  ScoreApp({required this.toggleTheme});
  @override
  _ScoreAppState createState() => _ScoreAppState();
}

class _ScoreAppState extends State<ScoreApp> {
  List<Player> players = [];
  TextEditingController controller = TextEditingController();
  int multiplier = 1;
  List<int> scoreButtons = [5, 10, 15];

  @override
  void initState() {
    super.initState();
    loadGame();
  }

  void addPlayer() {
    if (controller.text.isNotEmpty) {
      setState(() {
        players.add(Player(controller.text, 0));
        controller.clear();
      });
      saveGame();
    }
  }

  void updateScore(int index, int value) {
    setState(() {
      players[index].score += value * multiplier;
    });
    saveGame();
  }

  void removePlayer(int index) {
    setState(() {
      players.removeAt(index);
    });
    saveGame();
  }

  void resetScores() {
    setState(() {
      for (var p in players) p.score = 0;
    });
    saveGame();
  }

  int totalScore() => players.fold(0, (sum, p) => sum + p.score);

  Future<void> saveGame() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> names = players.map((p) => p.name).toList();
    List<String> scores = players.map((p) => p.score.toString()).toList();
    await prefs.setStringList('names', names);
    await prefs.setStringList('scores', scores);
  }

  Future<void> loadGame() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? names = prefs.getStringList('names');
    List<String>? scores = prefs.getStringList('scores');
    if (names != null && scores != null && names.length == scores.length) {
      setState(() {
        players = List.generate(
            names.length, (i) => Player(names[i], int.parse(scores[i])));
      });
    }
  }

  void openSettings() {
    showDialog(
        context: context,
        builder: (context) {
          List<TextEditingController> controllers =
              scoreButtons.map((v) => TextEditingController(text: v.toString())).toList();
          return AlertDialog(
            title: Text('Punkte-Buttons anpassen'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(scoreButtons.length, (i) {
                return TextField(
                  controller: controllers[i],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Button ${i + 1}'),
                );
              }),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    setState(() {
                      scoreButtons =
                          controllers.map((c) => int.tryParse(c.text) ?? 0).toList();
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Speichern'))
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    bool balanced = totalScore() == 0;
    return Scaffold(
      appBar: AppBar(
        title: Text('421 Calculator'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: openSettings,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: resetScores,
          ),
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: Column(
        children: [
          // Statusanzeige
          Container(
            padding: EdgeInsets.all(8),
            child: Text(
              balanced ? 'Alles ausgeglichen' : 'Nicht ausgeglichen',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: balanced ? Colors.black : Colors.red,
              ),
            ),
          ),
          // Multiplikator Buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Wrap(
              spacing: 4,
              children: List.generate(10, (i) {
                int val = i + 1;
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size(30, 30),
                    textStyle: TextStyle(fontSize: 12),
                    backgroundColor: multiplier == val ? Colors.blue : null,
                  ),
                  onPressed: () {
                    setState(() {
                      multiplier = val;
                    });
                  },
                  child: Text('${val}x'),
                );
              }),
            ),
          ),
          // Spieler hinzufügen
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Spielername',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    ),
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                SizedBox(width: 4),
                ElevatedButton(
                  onPressed: addPlayer,
                  child: Text('+', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(minimumSize: Size(30, 30)),
                ),
              ],
            ),
          ),
          SizedBox(height: 4),
          // Spielerliste
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(players.length, (index) {
                  Player p = players[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(p.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: Icon(Icons.close, size: 16),
                                onPressed: () => removePlayer(index),
                              )
                            ],
                          ),
                          Text('${p.score >= 0 ? "+" : ""}${p.score}',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: balanced ? Colors.black : Colors.red)),
                          Wrap(
                            spacing: 2,
                            children: [
                              for (var v in scoreButtons)
                                ElevatedButton(
                                  onPressed: () => updateScore(index, v),
                                  child: Text('+$v', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                      minimumSize: Size(30, 30), padding: EdgeInsets.all(2)),
                                ),
                              for (var v in scoreButtons)
                                ElevatedButton(
                                  onPressed: () => updateScore(index, -v),
                                  child: Text('-$v', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                      minimumSize: Size(30, 30), padding: EdgeInsets.all(2)),
                                ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
