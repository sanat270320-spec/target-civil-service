import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(TargetCivilServiceApp());
}

class TargetCivilServiceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'টার্গেট সিভিল সার্ভিস',
      theme: ThemeData(
        primaryColor: const Color(0xFFE53935),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE53935)),
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE53935),
          elevation: 0,
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // আপনার তৈরি ক্লাউড ডাটাবেস URL
  final String firebaseUrl = "https://target-civil-service-default-rtdb.firebaseio.com";

  final String adminId = "sanat";
  final String adminPass = "1234";

  List<Map<String, dynamic>> questions = [];
  List<Map<String, dynamic>> currentAffairs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCloudData();
  }

  Future<void> fetchCloudData() async {
    try {
      final qRes = await http.get(Uri.parse('$firebaseUrl/questions.json'));
      final caRes = await http.get(Uri.parse('$firebaseUrl/current_affairs.json'));

      List<Map<String, dynamic>> loadedQ = [];
      if (qRes.statusCode == 200 && qRes.body != 'null') {
        Map<String, dynamic> data = jsonDecode(qRes.body);
        data.forEach((key, val) {
          var item = Map<String, dynamic>.from(val);
          item['id'] = key;
          loadedQ.add(item);
        });
      }

      List<Map<String, dynamic>> loadedCA = [];
      if (caRes.statusCode == 200 && caRes.body != 'null') {
        Map<String, dynamic> data = jsonDecode(caRes.body);
        data.forEach((key, val) {
          var item = Map<String, dynamic>.from(val);
          item['id'] = key;
          loadedCA.add(item);
        });
      }

      setState(() {
        questions = loadedQ;
        currentAffairs = loadedCA;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> addQuestionToCloud(Map<String, dynamic> q) async {
    await http.post(Uri.parse('$firebaseUrl/questions.json'), body: jsonEncode(q));
    fetchCloudData();
  }

  Future<void> deleteQuestionFromCloud(String id) async {
    await http.delete(Uri.parse('$firebaseUrl/questions/$id.json'));
    fetchCloudData();
  }

  Future<void> addCAToCloud(Map<String, dynamic> ca) async {
    await http.post(Uri.parse('$firebaseUrl/current_affairs.json'), body: jsonEncode(ca));
    fetchCloudData();
  }

  Future<void> deleteCAFromCloud(String id) async {
    await http.delete(Uri.parse('$firebaseUrl/current_affairs/$id.json'));
    fetchCloudData();
  }

  void showAdminLogin() {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("অ্যাডমিন ক্লাউড প্যানেল", style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: userCtrl, decoration: const InputDecoration(labelText: "আইডি", prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 10),
            TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: "পাসওয়ার্ড", prefixIcon: Icon(Icons.lock))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
            onPressed: () {
              if (userCtrl.text.trim() == adminId && passCtrl.text.trim() == adminPass) {
                Navigator.pop(ctx);
                openAdminHub();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ভুল আইডি বা পাসওয়ার্ড!")));
              }
            },
            child: const Text("লগইন", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void openAdminHub() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DefaultTabController(
        length: 2,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const TabBar(
                labelColor: Color(0xFFE53935),
                indicatorColor: Color(0xFFE53935),
                tabs: [Tab(text: "ক্লাউড কুইজ"), Tab(text: "কারেন্ট অ্যাফেয়ার্স")],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: questions.isEmpty
                              ? const Center(child: Text("কোনো কুইজ প্রশ্ন নেই!"))
                              : ListView.builder(
                                  itemCount: questions.length,
                                  itemBuilder: (ctx, i) => Card(
                                    child: ListTile(
                                      title: Text(questions[i]['question'] ?? ''),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => deleteQuestionFromCloud(questions[i]['id']),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), minimumSize: const Size(double.infinity, 45)),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text("অনলাইনে প্রশ্ন যোগ করুন", style: TextStyle(color: Colors.white)),
                          onPressed: showAddQuestionDialog,
                        )
                      ],
                    ),
                    Column(
                      children: [
                        Expanded(
                          child: currentAffairs.isEmpty
                              ? const Center(child: Text("কোনো পোস্ট নেই!"))
                              : ListView.builder(
                                  itemCount: currentAffairs.length,
                                  itemBuilder: (ctx, i) => Card(
                                    child: ListTile(
                                      title: Text(currentAffairs[i]['title'] ?? ''),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => deleteCAFromCloud(currentAffairs[i]['id']),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), minimumSize: const Size(double.infinity, 45)),
                          icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
                          label: const Text("নতুন অনলাইন পোস্ট করুন", style: TextStyle(color: Colors.white)),
                          onPressed: showAddCADialog,
                        )
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void showAddQuestionDialog() {
    final q = TextEditingController(), o1 = TextEditingController(), o2 = TextEditingController(), o3 = TextEditingController(), o4 = TextEditingController(), exp = TextEditingController();
    int cIdx = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setF) => AlertDialog(
          title: const Text("নতুন ক্লাউড কুইজ"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: q, decoration: const InputDecoration(labelText: "প্রশ্ন")),
                TextField(controller: o1, decoration: const InputDecoration(labelText: "বিকল্প ১")),
                TextField(controller: o2, decoration: const InputDecoration(labelText: "বিকল্প ২")),
                TextField(controller: o3, decoration: const InputDecoration(labelText: "বিকল্প ৩")),
                TextField(controller: o4, decoration: const InputDecoration(labelText: "বিকল্প ৪")),
                DropdownButtonFormField<int>(
                  value: cIdx,
                  items: [0, 1, 2, 3].map((i) => DropdownMenuItem(value: i, child: Text("বিকল্প ${i + 1}"))).toList(),
                  onChanged: (v) => setF(() => cIdx = v!),
                  decoration: const InputDecoration(labelText: "সঠিক বিকল্প"),
                ),
                TextField(controller: exp, decoration: const InputDecoration(labelText: "ব্যাখ্যা")),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (q.text.isNotEmpty && o1.text.isNotEmpty) {
                  addQuestionToCloud({
                    'question': q.text,
                    'options': [o1.text, o2.text, o3.text, o4.text],
                    'correctIndex': cIdx,
                    'explanation': exp.text
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text("ক্লাউডে সেভ করুন"),
            )
          ],
        ),
      ),
    );
  }

  void showAddCADialog() {
    final t = TextEditingController(), d = TextEditingController(), img = TextEditingController(), desc = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("অনলাইন কারেন্ট অ্যাফেয়ার্স"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: t, decoration: const InputDecoration(labelText: "শিরোনাম")),
              TextField(controller: d, decoration: const InputDecoration(labelText: "তারিখ")),
              TextField(controller: img, decoration: const InputDecoration(labelText: "ছবি URL")),
              TextField(controller: desc, decoration: const InputDecoration(labelText: "বিবরণ"), maxLines: 3),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (t.text.isNotEmpty) {
                addCAToCloud({
                  'title': t.text,
                  'date': d.text.isEmpty ? 'আজকের আপডেট' : d.text,
                  'imageUrl': img.text.trim(),
                  'description': desc.text
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text("পোস্ট করুন"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
              child: const Text("WBCS / WBPSC ▾", style: TextStyle(color: Color(0xFFE53935), fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: "রিফ্রেশ", onPressed: fetchCloudData),
          IconButton(icon: const Icon(Icons.admin_panel_settings), tooltip: "অ্যাডমিন প্যানেল", onPressed: showAdminLogin),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchCloudData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.all(14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFFF7043)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("লাইভ ক্লাউড সক্রিয়", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text("আপনি যা পোস্ট করবেন সবার ফোনে চলে যাবে", style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                          Icon(Icons.cloud_done, size: 45, color: Colors.white),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizPlayScreen(questions: questions))),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.shade200)),
                                child: Column(
                                  children: [
                                    const Icon(Icons.quiz, color: Colors.orange, size: 30),
                                    const SizedBox(height: 6),
                                    Text("ডেইলি কুইজ (${questions.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CAScreen(currentAffairs: currentAffairs))),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue.shade200)),
                                child: Column(
                                  children: [
                                    const Icon(Icons.menu_book, color: Colors.blue, size: 30),
                                    const SizedBox(height: 6),
                                    Text("কারেন্ট অ্যাফেয়ার্স (${currentAffairs.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14.0),
                      child: Text("আজকের গুরুত্বপূর্ণ কারেন্ট অ্যাফেয়ার্স", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    currentAffairs.isEmpty
                        ? const Padding(padding: EdgeInsets.all(14), child: Text("কোনো কারেন্ট অ্যাফেয়ার্স নেই। অ্যাডমিন প্যানেল থেকে পোস্ট করুন।"))
                        : Container(
                            height: 190,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              itemCount: currentAffairs.length,
                              itemBuilder: (ctx, i) {
                                var ca = currentAffairs[i];
                                return Container(
                                  width: 240,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                        child: Image.network(
                                          ca['imageUrl'] ?? '',
                                          height: 110,
                                          width: 240,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(height: 110, color: Colors.grey[200], child: const Icon(Icons.image)),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(ca['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}

class CAScreen extends StatelessWidget {
  final List<Map<String, dynamic>> currentAffairs;
  CAScreen({required this.currentAffairs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ডেইলি কারেন্ট অ্যাফেয়ার্স")),
      body: currentAffairs.isEmpty
          ? const Center(child: Text("কোনো পোস্ট নেই!"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: currentAffairs.length,
              itemBuilder: (ctx, i) {
                var item = currentAffairs[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  elevation: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(item['imageUrl'] ?? '', width: double.infinity, height: 180, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50)),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['title'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text(item['description'] ?? '', style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class QuizPlayScreen extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  QuizPlayScreen({required this.questions});

  @override
  _QuizPlayScreenState createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  int currentQuestionIndex = 0;
  int score = 0;
  int? selectedAnswerIndex;
  bool isAnswered = false;

  void checkAnswer(int index) {
    if (isAnswered) return;
    setState(() {
      selectedAnswerIndex = index;
      isAnswered = true;
      if (index == widget.questions[currentQuestionIndex]['correctIndex']) score++;
    });
  }

  void nextQuestion() {
    setState(() {
      if (currentQuestionIndex < widget.questions.length - 1) {
        currentQuestionIndex++;
        selectedAnswerIndex = null;
        isAnswered = false;
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text("মক টেস্ট সমাপ্ত!"),
            content: Text("আপনার স্কোর: $score / ${widget.questions.length}"),
            actions: [
              TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text("হোমে ফিরুন"))
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("ডেইলি টেস্ট")),
        body: const Center(child: Text("কোনো প্রশ্ন নেই! অ্যাডমিন প্যানেল থেকে প্রশ্ন যোগ করুন।")),
      );
    }

    var q = widget.questions[currentQuestionIndex];
    List<dynamic> options = q['options'] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text("ডেইলি কুইজ প্র্যাকটিস")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("প্রশ্ন ${currentQuestionIndex + 1} / ${widget.questions.length}", style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text(q['question'] ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),
            ...List.generate(options.length, (index) {
              Color btnColor = Colors.white;
              if (isAnswered) {
                if (index == q['correctIndex']) btnColor = Colors.green.shade100;
                else if (index == selectedAnswerIndex) btnColor = Colors.red.shade100;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(backgroundColor: btnColor, padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14)),
                  onPressed: () => checkAnswer(index),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("${String.fromCharCode(65 + index)}. ${options[index]}", style: const TextStyle(color: Colors.black87, fontSize: 15)),
                  ),
                ),
              );
            }),
            if (isAnswered) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text("ব্যাখ্যা: ${q['explanation'] ?? 'নেই'}"),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935), padding: const EdgeInsets.symmetric(vertical: 13)),
                onPressed: nextQuestion,
                child: Text(currentQuestionIndex == widget.questions.length - 1 ? "ফলাফল দেখুন" : "পরবর্তী প্রশ্ন", style: const TextStyle(color: Colors.white)),
              )
            ]
          ],
        ),
      ),
    );
  }
}
