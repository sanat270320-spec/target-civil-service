import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==========================================
// ১. কনফিগারেশন
// ==========================================
class AppConfig {
  static const String appName = "টার্গেট সিভিল সার্ভিস";
  static const String adminPhone = "6295411997";
  static const String adminEmail = "sanatd214@gmail.com";
  static const String defaultMasterPin = "123456789";
}

// ==========================================
// ডাটা মডেল (মেমোরি স্টেট)
// ==========================================
class Question {
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;

  Question({
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
  });
}

class SubjectData {
  final String name;
  final List<Question> questions;
  int testDurationMinutes;
  int totalQuestionsForTest;

  SubjectData({
    required this.name,
    List<Question>? questions,
    this.testDurationMinutes = 30,
    this.totalQuestionsForTest = 25,
  }) : questions = questions ?? [];
}

// গ্লোবাল ডাটাবেস লিস্ট
List<SubjectData> globalSubjects = [
  SubjectData(name: "ইতিহাস", questions: [
    Question(
      questionText: "সিন্ধু সভ্যতার প্রধান বন্দর কোনটি ছিল?",
      options: ["হরপ্পা", "লোথাল", "কালিবঙ্গান", "মহেঞ্জোদাড়ো"],
      correctOptionIndex: 1,
    ),
  ]),
  SubjectData(name: "ভূগোল"),
  SubjectData(name: "সংবিধান"),
];

// ==========================================
// মেইন ফাংশন
// ==========================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TargetCivilServiceApp());
}

class TargetCivilServiceApp extends StatelessWidget {
  const TargetCivilServiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ==========================================
// স্প্ল্যাশ স্ক্রিন
// ==========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    await Future.delayed(const Duration(seconds: 1));
    final prefs = await SharedPreferences.getInstance();
    final isAdmin = prefs.getBool('is_admin') ?? false;

    if (!mounted) return;
    if (isAdmin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: Text(
          AppConfig.appName,
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ==========================================
// লগইন ও পিন ভেরিফিকেশন
// ==========================================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _phoneController = TextEditingController();

  void _showPinDialog() {
    final TextEditingController pinController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("সুপার অ্যাডমিন পিন"),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(hintText: "৯ সংখ্যার পিন (123456789)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("বাতিল")),
          ElevatedButton(
            onPressed: () async {
              if (pinController.text.trim() == AppConfig.defaultMasterPin) {
                Navigator.pop(context);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_admin', true);
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("ভুল পিন!")),
                );
              }
            },
            child: const Text("লগইন"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 70, color: Colors.deepPurple),
            const SizedBox(height: 16),
            const Text(
              AppConfig.appName,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "মোবাইল নম্বর",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                onPressed: () {
                  if (_phoneController.text.trim() == AppConfig.adminPhone) {
                    _showPinDialog();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("ছাত্র রেজিস্ট্রেশন পেজ চালু হচ্ছে...")),
                    );
                  }
                },
                child: const Text("প্রবেশ করুন", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// সুপার অ্যাডমিন ড্যাশবোর্ড (সম্পূর্ণ কার্যকর)
// ==========================================
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // নতুন সাবজেক্ট তৈরির পপআপ
  void _createNewSubjectDialog() {
    final TextEditingController subjectNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("নতুন বিষয় তৈরি করুন"),
        content: TextField(
          controller: subjectNameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "বিষয়ের নাম লিখুন (উদাঃ অর্থনীতি)",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("বাতিল")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            onPressed: () {
              final name = subjectNameController.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  globalSubjects.add(SubjectData(name: name));
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("'$name' বিষয় যুক্ত হয়েছে!")),
                );
              }
            },
            child: const Text("সেভ করুন", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("সুপার অ্যাডমিন প্যানেল"),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("নতুন বিষয় তৈরি", style: TextStyle(color: Colors.white)),
        onPressed: _createNewSubjectDialog,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.deepPurple.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.deepPurple),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "যেকোনো বিষয়ে ট্যাপ করে ভেতরে ঢুকুন। সেখানে ১০০টি করে প্রশ্ন এবং মক টেস্টের সময় নিয়ন্ত্রণ করতে পারবেন।",
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "আপনার বিষয়সমূহ (Subject Folders):",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: globalSubjects.length,
                itemBuilder: (context, index) {
                  final subject = globalSubjects[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        child: Icon(Icons.folder, color: Colors.white),
                      ),
                      title: Text(
                        subject.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text("মোট প্রশ্ন: ${subject.questions.length} টি | সময়: ${subject.testDurationMinutes} মিনিট"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubjectDetailScreen(subject: subject),
                          ),
                        );
                        setState(() {}); // ফিরে আসার পর আপডেট হবে
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// বিষয়ের ভেতরের স্ক্রিন (প্রশ্ন যোগ ও মক টেস্ট কন্ট্রোল)
// ==========================================
class SubjectDetailScreen extends StatefulWidget {
  final SubjectData subject;

  const SubjectDetailScreen({super.key, required this.subject});

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  // সময় ও প্রশ্ন সংখ্যা কন্ট্রোল ডায়ালগ
  void _editMockTestSettings() {
    final durationController = TextEditingController(text: widget.subject.testDurationMinutes.toString());
    final countController = TextEditingController(text: widget.subject.totalQuestionsForTest.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${widget.subject.name} - টেস্ট কন্ট্রোল"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "টেস্টের সময় (মিনিটে)"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: countController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "মক টেস্টে কয়টি প্রশ্ন থাকবে"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("বাতিল")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                widget.subject.testDurationMinutes = int.tryParse(durationController.text) ?? 30;
                widget.subject.totalQuestionsForTest = int.tryParse(countController.text) ?? 25;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("টেস্ট সেটিংস আপডেট করা হয়েছে!")),
              );
            },
            child: const Text("সেভ"),
          ),
        ],
      ),
    );
  }

  // প্রশ্ন যোগ করার ডায়ালগ
  void _addNewQuestionDialog() {
    final qController = TextEditingController();
    final opt1 = TextEditingController();
    final opt2 = TextEditingController();
    final opt3 = TextEditingController();
    final opt4 = TextEditingController();
    int correctIndex = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("নতুন প্রশ্ন যোগ করুন"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: qController,
                  decoration: const InputDecoration(labelText: "প্রশ্নটি লিখুন"),
                ),
                TextField(controller: opt1, decoration: const InputDecoration(labelText: "অপশন A")),
                TextField(controller: opt2, decoration: const InputDecoration(labelText: "অপশন B")),
                TextField(controller: opt3, decoration: const InputDecoration(labelText: "অপশন C")),
                TextField(controller: opt4, decoration: const InputDecoration(labelText: "অপশন D")),
                const SizedBox(height: 12),
                const Text("সঠিক উত্তর নির্বাচন করুন:", style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<int>(
                  value: correctIndex,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text("অপশন A")),
                    DropdownMenuItem(value: 1, child: Text("অপশন B")),
                    DropdownMenuItem(value: 2, child: Text("অপশন C")),
                    DropdownMenuItem(value: 3, child: Text("অপশন D")),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => correctIndex = val);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("বাতিল")),
            ElevatedButton(
              onPressed: () {
                if (qController.text.isNotEmpty && opt1.text.isNotEmpty) {
                  setState(() {
                    widget.subject.questions.add(
                      Question(
                        questionText: qController.text,
                        options: [opt1.text, opt2.text, opt3.text, opt4.text],
                        correctOptionIndex: correctIndex,
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("যোগ করুন"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.timer),
            tooltip: "টেস্ট কন্ট্রোল",
            onPressed: _editMockTestSettings,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: _addNewQuestionDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.amber.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "টেস্ট সময়: ${widget.subject.testDurationMinutes} মিনিট | প্রশ্ন সংখ্যা: ${widget.subject.totalQuestionsForTest}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                TextButton(
                  onPressed: _editMockTestSettings,
                  child: const Text("পরিবর্তন"),
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.subject.questions.isEmpty
                ? const Center(child: Text("এখনো কোনো প্রশ্ন যোগ করা হয়নি। নিচে + বাটনে চাপ দিন।"))
                : ListView.builder(
                    itemCount: widget.subject.questions.length,
                    itemBuilder: (context, index) {
                      final q = widget.subject.questions[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "প্রশ্ন ${index + 1}: ${q.questionText}",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text("A) ${q.options[0]}"),
                              Text("B) ${q.options[1]}"),
                              Text("C) ${q.options[2]}"),
                              Text("D) ${q.options[3]}"),
                              const SizedBox(height: 4),
                              Text(
                                "সঠিক উত্তর: অপশন ${String.fromCharCode(65 + q.correctOptionIndex)}",
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
