import 'package:flutter/material.dart';

void main() {
  runApp(TargetCivilServiceApp());
}

class TargetCivilServiceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Target Civil Service Bangla',
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
  int currentQuestionIndex = 0;
  int score = 0;
  int? selectedAnswerIndex;
  bool isAnswered = false;

  final List<Map<String, dynamic>> questions = [
    {
      'question': 'ভারতের সংবিধানের কোন ধারা অনুযায়ী আর্থিক জরুরি অবস্থা ঘোষণা করা যায়?',
      'options': ['ধারা ৩৫২', 'ধারা ৩৫৬', 'ধারা ৩৬০', 'ধারা ৩৬৮'],
      'correctIndex': 2,
      'explanation': 'ধারা ৩৬০ অনুযায়ী ভারতের রাষ্ট্রপতি দেশে আর্থিক জরুরি অবস্থা জারি করতে পারেন।'
    },
    {
      'question': 'পশ্চিমবঙ্গের সর্বোচ্চ পর্বতশৃঙ্গ কোনটি?',
      'options': ['টাইগার হিল', 'সান্দাকফু', 'ফালাট', 'টংলু'],
      'correctIndex': 1,
      'explanation': 'সান্দাকফু (৩৬৩৬ মিটার) পশ্চিমবঙ্গের সর্বোচ্চ শৃঙ্গ, যা সিঙ্গালীলা পর্বতশ্রেণীতে অবস্থিত।'
    }
  ];

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

  @override
  Widget build(BuildContext context) {
    var qData = questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('টার্গেট সিভিল সার্ভিস বাংলা'),
        backgroundColor: Colors.indigo,
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
