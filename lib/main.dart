import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(TargetCivilServiceApp());
}

class TargetCivilServiceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'টার্গেট সিভিল সার্ভিস বাংলা',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: QuizScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class QuizScreen extends StatefulWidget {
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final String adminId = "sanat";
  final String adminPass = "1234";

  int currentQuestionIndex = 0;
  int score = 0;
  int? selectedAnswerIndex;
  bool isAnswered = false;

  // প্রাথমিক ডিফল্ট প্রশ্নসমূহ
  List<Map<String, dynamic>> questions = [
    {
      'question': 'ভারতের সংবিধানের কোন ধারা অনুযায়ী আর্থিক জরুরি অবস্থা ঘোষণা করা যায়?',
      'options': ['ধারা ৩৫২', 'ধারা ৩৫৬', 'ধারা ৩৬০', 'ধারা ৩৬৮'],
      'correctIndex': 2,
      'explanation': 'ধারা ৩৬০ অনুযায়ী ভারতের রাষ্ট্রপতি আর্থিক জরুরি অবস্থা জারি করতে পারেন।'
    },
    {
      'question': 'পশ্চিমবঙ্গের সর্বোচ্চ পর্বতশৃঙ্গ কোনটি?',
      'options': ['টাইগার হিল', 'সান্দাকফু', 'ফালাট', 'টংলু'],
      'correctIndex': 1,
      'explanation': 'সান্দাকফু (৩৬৩৬ মিটার) পশ্চিমবঙ্গের সর্বোচ্চ শৃঙ্গ।'
    },
    {
      'question': 'জাতীয় কংগ্রেসের কোন অধিবেশনে প্রথম পূর্ণ স্বরাজের দাবি উত্থাপিত হয়?',
      'options': ['কলকাতা', 'লাহোর', 'সুরাট', 'বোম্বাই'],
      'correctIndex': 1,
      'explanation': '১৯২৯ সালের লাহোর অধিবেশনে পূর্ণ স্বরাজের প্রস্তাব গৃহীত হয়।'
    }
  ];

  @override
  void initState() {
    super.initState();
    loadSavedQuestions();
  }

  // মেমরি থেকে সেভ করা প্রশ্ন লোড করার ফাংশন
  Future<void> loadSavedQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('custom_questions');
    if (savedData != null) {
      List<dynamic> decodedList = jsonDecode(savedData);
      setState(() {
        for (var item in decodedList) {
          questions.add(Map<String, dynamic>.from(item));
        }
      });
    }
  }

  // নতুন প্রশ্ন ফোনের স্থায়ী মেমরিতে সেভ করার ফাংশন
  Future<void> saveNewQuestion(Map<String, dynamic> newQ) async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('custom_questions');
    List<dynamic> currentCustom = [];
    if (savedData != null) {
      currentCustom = jsonDecode(savedData);
    }
    currentCustom.add(newQ);
    await prefs.setString('custom_questions', jsonEncode(currentCustom));
    setState(() {
      questions.add(newQ);
    });
  }

  void checkAnswer(int index) {
    if (isAnswered) return;
    setState(() {
      selectedAnswerIndex = index;
      isAnswered = true;
      if (index == questions[currentQuestionIndex]['correctIndex']) {
        score++;
      }
    });
  }

  void nextQuestion() {
    setState(() {
      if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
        selectedAnswerIndex = null;
        isAnswered = false;
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: Text("কুইজ সমাপ্ত!"),
            content: Text("আপনার প্রাপ্ত নম্বর: $score / ${questions.length}"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    currentQuestionIndex = 0;
                    selectedAnswerIndex = null;
                    isAnswered = false;
                    score = 0;
                  });
                },
                child: Text("পুনরায় শুরু করুন"),
              )
            ],
          ),
        );
      }
    });
  }

  // অ্যাডমিন লগইন ডায়ালগ
  void promptAdminLogin() {
    final userController = TextEditingController();
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("অ্যাডমিন লগইন", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("প্রশ্ন যোগ করার জন্য লগইন করুন", style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            SizedBox(height: 12),
            TextField(
              controller: userController,
              decoration: InputDecoration(
                labelText: "অ্যাডমিন আইডি",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "পাসওয়ার্ড",
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("বাতিল", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            onPressed: () {
              if (userController.text.trim() == adminId && passController.text.trim() == adminPass) {
                Navigator.pop(context);
                openAddQuestionDialog();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("ভুল আইডি বা পাসওয়ার্ড!"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text("লগইন", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // প্রশ্ন যোগ করার ইনপুট ফর্ম
  void openAddQuestionDialog() {
    final qController = TextEditingController();
    final op1Controller = TextEditingController();
    final op2Controller = TextEditingController();
    final op3Controller = TextEditingController();
    final op4Controller = TextEditingController();
    final expController = TextEditingController();
    int correctIndex = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "নতুন প্রশ্ন যুক্ত করুন",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: qController,
                      decoration: InputDecoration(labelText: "প্রশ্নটি লিখুন", border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: op1Controller,
                      decoration: InputDecoration(labelText: "বিকল্প ১", border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: op2Controller,
                      decoration: InputDecoration(labelText: "বিকল্প ২", border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: op3Controller,
                      decoration: InputDecoration(labelText: "বিকল্প ৩", border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: op4Controller,
                      decoration: InputDecoration(labelText: "বিকল্প ৪", border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: correctIndex,
                      decoration: InputDecoration(labelText: "কোন বিকল্পটি সঠিক উত্তর?", border: OutlineInputBorder()),
                      items: [
                        DropdownMenuItem(value: 0, child: Text("বিকল্প ১")),
                        DropdownMenuItem(value: 1, child: Text("বিকল্প ২")),
                        DropdownMenuItem(value: 2, child: Text("বিকল্প ৩")),
                        DropdownMenuItem(value: 3, child: Text("বিকল্প ৪")),
                      ],
                      onChanged: (val) {
                        if (val != null) setSheetState(() => correctIndex = val);
                      },
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: expController,
                      decoration: InputDecoration(labelText: "উত্তরের ব্যাখ্যা লিখুন", border: OutlineInputBorder()),
                    ),
                    SizedBox(height: 14),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        if (qController.text.isNotEmpty &&
                            op1Controller.text.isNotEmpty &&
                            op2Controller.text.isNotEmpty &&
                            op3Controller.text.isNotEmpty &&
                            op4Controller.text.isNotEmpty) {
                          
                          Map<String, dynamic> newQ = {
                            'question': qController.text,
                            'options': [
                              op1Controller.text,
                              op2Controller.text,
                              op3Controller.text,
                              op4Controller.text
                            ],
                            'correctIndex': correctIndex,
                            'explanation': expController.text.isEmpty
                                ? 'কোনো ব্যাখ্যা দেওয়া হয়নি।'
                                : expController.text,
                          };

                          await saveNewQuestion(newQ);

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("প্রশ্ন সফলভাবে সেভ করা হয়েছে!")),
                          );
                        }
                      },
                      child: Text("প্রশ্ন সেভ করুন", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var qData = questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('টার্গেট সিভিল সার্ভিস বাংলা'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: Icon(Icons.admin_panel_settings, size: 28),
            tooltip: "অ্যাডমিন প্যানেল",
            onPressed: promptAdminLogin,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "প্রশ্ন ${currentQuestionIndex + 1}/${questions.length}",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 10),
            Text(
              qData['question'],
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ...List.generate(qData['options'].length, (index) {
              Color buttonColor = Colors.white;
              if (isAnswered) {
                if (index == qData['correctIndex']) {
                  buttonColor = Colors.green.shade200;
                } else if (index == selectedAnswerIndex) {
                  buttonColor = Colors.red.shade200;
                }
              }

              return Container(
                margin: EdgeInsets.only(bottom: 10),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: buttonColor,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => checkAnswer(index),
                  child: Text(
                    qData['options'][index],
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
              );
            }),
            SizedBox(height: 10),
            if (isAnswered) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: Text(
                  "ব্যাখ্যা: ${qData['explanation']}",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ),
              Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: nextQuestion,
                child: Text(
                  currentQuestionIndex == questions.length - 1 ? "ফলাফল দেখুন" : "পরবর্তী প্রশ্ন",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
