import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(const MyApp());
}

class DbHelper {
  late Database _database;

  Future<void> initializeDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'food_database.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE foods(
            id INTEGER PRIMARY KEY,
            name TEXT,
            calories INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE meal_plans(
            id INTEGER PRIMARY KEY,
            date TEXT,
            targetCalories INTEGER,
            food_id INTEGER,
            quantity INTEGER,
            FOREIGN KEY(food_id) REFERENCES foods(id)
          )
        ''');
      },
    );
  }

  Future<List<Map<String, dynamic>>> getAllFoods() async {
    return await _database.query('foods');
  }

  Future<bool> checkIfFoodExists(String name) async {
    List<Map<String, dynamic>> existingFoods = await _database.query(
      'foods',
      where: 'name = ?',
      whereArgs: [name],
    );

    return existingFoods.isNotEmpty;
  }

  Future<void> insertFood(String name, int calories) async {
    bool foodExists = await checkIfFoodExists(name);
    if (!foodExists) {
      await _database.insert(
        'foods',
        {'name': name, 'calories': calories},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> deleteFood(int id) async {
    await _database.delete(
      'foods',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateFood(int id, int calories) async {
    await _database.update(
      'foods',
      {'calories': calories},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> saveMealPlan(MealPlan mealPlan) async {
    for (var food in mealPlan.selectedFoods) {
      await _database.insert(
        'meal_plans',
        {
          'date': food['date'],
          'targetCalories': mealPlan.targetCalories,

        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calorie Calculator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Calorie Calculator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late DbHelper _dbHelper;

  @override
  void initState() {
    super.initState();
    _dbHelper = DbHelper();
    _initializeDatabaseAndAddFoods();
  }

  Future<void> _initializeDatabaseAndAddFoods() async {
    await _dbHelper.initializeDatabase();
    await _addAllFoods();
  }

  Future<void> _addAllFoods() async {
    List<Map<String, dynamic>> foods = [
      {'name': 'Apple', 'calories': 52},
      {'name': 'Banana', 'calories': 89},
      {'name': 'Chicken Breast', 'calories': 165},
      {'name': 'Egg', 'calories': 70},
      {'name': 'Salmon', 'calories': 233},
      {'name': 'Brown Rice', 'calories': 218},
      {'name': 'Avocado', 'calories': 234},
      {'name': 'Spinach', 'calories': 41},
      {'name': 'Almonds', 'calories': 164},
      {'name': 'Greek Yogurt', 'calories': 100},
      {'name': 'Oatmeal', 'calories': 166},
      {'name': 'Broccoli', 'calories': 55},
      {'name': 'Sweet Potato', 'calories': 103},
      {'name': 'Quinoa', 'calories': 222},
      {'name': 'Lean Ground Beef', 'calories': 224},
      {'name': 'Strawberries', 'calories': 50},
      {'name': 'Cottage Cheese', 'calories': 222},
      {'name': 'Peanut Butter', 'calories': 190},
      {'name': 'Carrots', 'calories': 52},
      {'name': 'Tuna', 'calories': 120}
    ];

    for (var food in foods) {
      bool foodExists = await _dbHelper.checkIfFoodExists(food['name']);
      if (!foodExists) {
        await _dbHelper.insertFood(food['name'], food['calories']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ScreenOne()),
                );
              },
              child: Text('Go to Screen One'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ScreenTwo()),
                );
              },
              child: Text('Go to Screen Two'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ScreenThree()),
                );
              },
              child: Text('Food Items'),
            ),
          ],
        ),
      ),
    );
  }
}

class MealPlan {
  late int id;
  late String date;
  late int targetCalories;
  late List<Map<String, dynamic>> selectedFoods;
}

class ScreenOne extends StatefulWidget {
  @override
  _ScreenOneState createState() => _ScreenOneState();
}

class _ScreenOneState extends State<ScreenOne> {
  late DbHelper _dbHelper;
  late int targetCalories = 2000;
  late DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> selectedFoods = [];
  List<Map<String, dynamic>> foods = [];
  Map<int, int> quantities = {};


  @override
  void initState() {
    super.initState();
    _dbHelper = DbHelper();
    _initializeDatabaseAndFetchFoods();
  }

  Future<void> _initializeDatabaseAndFetchFoods() async {
    await _dbHelper.initializeDatabase();
    await _fetchFoods();
  }

  Future<void> _fetchFoods() async {
    foods = await _dbHelper.getAllFoods();
    setState(() {});
  }

  void _updateQuantity(int foodId, int quantity) {
    setState(() {
      quantities[foodId] = quantity;
    });
  }

  Future<void> _toggleFoodSelection(Map<String, dynamic> food, bool selected) async {
    if (selected) {
      int totalCalories = calculateTotalCalories() + (food['calories'] as int);
      if (totalCalories <= targetCalories) {
        setState(() {
          selectedFoods.add(food);
        });
      } else {
        print('Adding this item exceeds the target calories!');
      }
    } else {
      setState(() {
        selectedFoods.remove(food);
      });
    }

    int remainingCalories = targetCalories - calculateTotalCalories();
    setState(() {
      foods = filterFoodItems(remainingCalories);
    });
  }

  int calculateTotalCalories() {
    int totalCalories = 0;
    for (var food in selectedFoods) {
      totalCalories += (food['calories'] as int);
    }
    return totalCalories;
  }

  List<Map<String, dynamic>> filterFoodItems(int remainingCalories) {
    return foods.where((food) => food['calories'] <= remainingCalories).toList();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime picked = (await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    ))!;
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
      });
  }

  Future<List<Map<String, dynamic>>> _fetchPlausibleFoods(int remainingCalories) async {
    List<Map<String, dynamic>> plausibleFoods =
    foods.where((food) => food['calories'] <= remainingCalories).toList();
    return plausibleFoods;
  }

  Future<void> _saveMealPlan() async {
    MealPlan mealPlan = MealPlan();
    mealPlan.date = selectedDate.toIso8601String();
    mealPlan.targetCalories = targetCalories;
    mealPlan.selectedFoods = [];

    for (var food in selectedFoods) {
      mealPlan.selectedFoods.add({
        'id': food['id'],
        'quantity': quantities[food['id']] ?? 0,
      });
    }

    await _dbHelper.saveMealPlan(mealPlan);
  }

  @override
  Widget build(BuildContext context) {
    int remainingCalories = targetCalories - calculateTotalCalories();
    List<Map<String, dynamic>> plausibleFoods = foods.where((food) => food['calories'] <= remainingCalories).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('Food Items'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Target Calories:'),
                DropdownButton<int>(
                  value: targetCalories,
                  onChanged: (int? newValue) {
                    setState(() {
                      targetCalories = newValue!;
                    });
                  },
                  items: <int>[1500, 2000, 2500, 3000]
                      .map<DropdownMenuItem<int>>((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(value.toString()),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Selected Date:'),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: Text(
                    selectedDate.toString().substring(0, 10),
                  ),
                ),
              ],
            ),
          ),

          Text('Remaining Calories: $remainingCalories'),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchPlausibleFoods(remainingCalories),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No plausible food items.'));
                } else {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final food = snapshot.data![index];
                      final foodId = food['id'] as int;
                      final foodName = food['name'] as String;
                      final foodCalories = food['calories'] as int;
                      int quantity = quantities[foodId] ?? 0;

                      return ListTile(
                        title: Text(foodName),
                        subtitle: Text('${foodCalories} calories'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$quantity'),
                            SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  quantities[foodId] = quantity + 1;
                                  _toggleFoodSelection(food, true);
                                });
                              },
                              child: Text('Add'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
              },
            )
          ),
          ElevatedButton(
            onPressed: _saveMealPlan,
            child: Text('Save Meal Plan'),
          ),
        ],
      ),
    );
  }
}

class ScreenTwo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Screen Two'),
      ),
      body: Center(
        child: Text('Screen Two Content'),
      ),
    );
  }
}

class ScreenThree extends StatelessWidget {
  final DbHelper _dbHelper = DbHelper();

  Future<List<Map<String, dynamic>>> _getAllFoods() async {
    await _dbHelper.initializeDatabase();
    return await _dbHelper.getAllFoods();
  }

  Future<void> _showUpdateCaloriesDialog(BuildContext context, Map<String, dynamic> food) async {
    TextEditingController caloriesController = TextEditingController();
    caloriesController.text = food['calories'].toString();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Calories'),
          content: TextField(
            controller: caloriesController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'New Calories'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                int newCalories = int.tryParse(caloriesController.text) ?? 0;
                _dbHelper.updateFood(food['id'], newCalories);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Calories updated')),
                );
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _showAddEntryDialog(BuildContext context) async {
    TextEditingController nameController = TextEditingController();
    TextEditingController caloriesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Food Name'),
              ),
              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Calories'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String name = nameController.text;
                int calories = int.tryParse(caloriesController.text) ?? 0;
                _dbHelper.insertFood(name, calories);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Entry added')),
                );
                Scaffold.of(context).setState(() {});
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Food Items'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getAllFoods(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No data available'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final food = snapshot.data![index];
                return ListTile(
                  title: Text(food['name']),
                  subtitle: Text('Calories: ${food['calories']}'),
                  onTap: () {
                    _showUpdateCaloriesDialog(context, food);
                  },
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      _dbHelper.deleteFood(food['id']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Entry deleted')),
                      );
                      Scaffold.of(context).setState(() {});
                    },
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEntryDialog(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }
}





