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
      title: 'Target Civil Service',
      theme: ThemeData(
        primaryColor: Color(0xFFD32F2F),
        scaffoldBackgroundColor: Color(0xFFF5F6F8),
        fontFamily: 'Roboto',
      ),
      home: AddaRootScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AddaRootScreen extends StatefulWidget {
  @override
  _AddaRootScreenState createState() => _AddaRootScreenState();
}

class _AddaRootScreenState extends State<AddaRootScreen> {
  int _selectedIndex = 0;
  final String firebaseUrl = "https://target-civil-service-default-rtdb.firebaseio.com";
  
  // গোপন অ্যাডমিন লগইন তথ্য
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

  // সিক্রেট অ্যাডমিন উইন্ডো
  void showAdminLogin() {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("সিস্টেম নিয়ন্ত্রণ", style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: userCtrl, decoration: InputDecoration(labelText: "আইডি", prefixIcon: Icon(Icons.person))),
            SizedBox(height: 10),
            TextField(controller: passCtrl, obscureText: true, decoration: InputDecoration(labelText: "পাসওয়ার্ড", prefixIcon: Icon(Icons.lock))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("বাতিল")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFD32F2F)),
            onPressed: () {
              if (userCtrl.text.trim() == adminId && passCtrl.text.trim() == adminPass) {
                Navigator.pop(ctx);
                openAdminHub();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("অনুমতি নেই!")));
              }
            },
            child: Text("প্রবেশ", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void openAdminHub() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DefaultTabController(
        length: 2,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              TabBar(
                labelColor: Color(0xFFD32F2F),
                indicatorColor: Color(0xFFD32F2F),
                tabs: [Tab(text: "কুইজ তথ্য"), Tab(text: "কারেন্ট অ্যাফেয়ার্স")],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: questions.isEmpty
                              ? Center(child: Text("কোনো তথ্য নেই!"))
                              : ListView.builder(
                                  itemCount: questions.length,
                                  itemBuilder: (ctx, i) => Card(
                                    child: ListTile(
                                      title: Text(questions[i]['question'] ?? ''),
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => deleteQuestionFromCloud(questions[i]['id']),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFD32F2F), minimumSize: Size(double.infinity, 45)),
                          icon: Icon(Icons.add, color: Colors.white),
                          label: Text("নতুন কুইজ তৈরি করুন", style: TextStyle(color: Colors.white)),
                          onPressed: showAddQuestionDialog,
                        )
                      ],
                    ),
                    Column(
                      children: [
                        Expanded(
                          child: currentAffairs.isEmpty
                              ? Center(child: Text("কোনো তথ্য নেই!"))
                              : ListView.builder(
                                  itemCount: currentAffairs.length,
                                  itemBuilder: (ctx, i) => Card(
                                    child: ListTile(
                                      title: Text(currentAffairs[i]['title'] ?? ''),
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => deleteCAFromCloud(currentAffairs[i]['id']),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFD32F2F), minimumSize: Size(double.infinity, 45)),
                          icon: Icon(Icons.add_photo_alternate, color: Colors.white),
                          label: Text("নতুন পোস্ট তৈরি করুন", style: TextStyle(color: Colors.white)),
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
          title: Text("নতুন কুইজ তথ্য"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: q, decoration: InputDecoration(labelText: "প্রশ্ন")),
                TextField(controller: o1, decoration: InputDecoration(labelText: "বিকল্প ১")),
                TextField(controller: o2, decoration: InputDecoration(labelText: "বিকল্প ২")),
                TextField(controller: o3, decoration: InputDecoration(labelText: "বিকল্প ৩")),
                TextField(controller: o4, decoration: InputDecoration(labelText: "বিকল্প ৪")),
                DropdownButtonFormField<int>(
                  value: cIdx,
                  items: [0, 1, 2, 3].map((i) => DropdownMenuItem(value: i, child: Text("বিকল্প ${i + 1}"))).toList(),
                  onChanged: (v) => setF(() => cIdx = v!),
                  decoration: InputDecoration(labelText: "সঠিক বিকল্প কোনটি?"),
                ),
                TextField(controller: exp, decoration: InputDecoration(labelText: "উত্তরের ব্যাখ্যা")),
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
              child: Text("সংরক্ষণ করুন"),
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
        title: Text("নতুন তথ্য সংযোজন"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: t, decoration: InputDecoration(labelText: "শিরোনাম")),
              TextField(controller: d, decoration: InputDecoration(labelText: "তারিখ")),
              TextField(controller: img, decoration: InputDecoration(labelText: "ছবির URL লিঙ্ক")),
              TextField(controller: desc, decoration: InputDecoration(labelText: "বিস্তারিত তথ্য"), maxLines: 3),
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
            child: Text("পোস্ট করুন"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
          : IndexedStack(
              index: _selectedIndex,
              children: [
                _buildHomeDashboard(),
                QuizPlayScreen(questions: questions),
                CAScreen(currentAffairs: currentAffairs),
                _buildSimplePlaceholder("স্টাডি মেটেরিয়াল"),
                _buildProfileTab(),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFFD32F2F),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Tests"),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: "Current"),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: "Study"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "My Zone"),
        ],
      ),
    );
  }

  Widget _buildHomeDashboard() {
    return RefreshIndicator(
      onRefresh: fetchCloudData,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: Color(0xFFD32F2F),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.school, color: Colors.white, size: 20),
                ),
                SizedBox(width: 8),
                // গোপন অ্যাক্সেস: এই বক্সে ৩ সেকেন্ড লং প্রেস করলেই অ্যাডমিন খুলবে
                GestureDetector(
                  onLongPress: showAdminLogin,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Text("WBCS / West Bengal Exams ▾", style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 12),
                padding: EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.monetization_on, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text("50", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(icon: Icon(Icons.refresh, color: Colors.white), onPressed: fetchCloudData),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    height: 44,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey),
                        SizedBox(width: 8),
                        Text("সার্চ মক টেস্ট, কারেন্ট অ্যাফেয়ার্স...", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                ),

                Container(
                  margin: EdgeInsets.symmetric(horizontal: 12),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFD32F2F), Color(0xFFFF5252)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                              child: Text("TARGET 2026", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                            ),
                            SizedBox(height: 6),
                            Text("WBCS প্রিলিমস ও মেনস সম্পূর্ণ গাইড", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                            SizedBox(height: 4),
                            Text("ডেইলি মক টেস্ট ও ফ্রি নোটস", style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                      Icon(Icons.military_tech, size: 55, color: Colors.white),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text("STUDY MATERIAL", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade700, letterSpacing: 0.5)),
                ),
                SizedBox(height: 10),

                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    _buildIconItem(Icons.quiz, "ডেইলি কুইজ", Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizPlayScreen(questions: questions)))),
                    _buildIconItem(Icons.newspaper, "কারেন্ট অ্যাফেয়ার্স", Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => CAScreen(currentAffairs: currentAffairs)))),
                    _buildIconItem(Icons.menu_book, "স্টাডি নোটস", Colors.green, () {}),
                    _buildIconItem(Icons.assignment, "টেস্ট সিরিজ", Colors.deepOrange, () {}),
                    _buildIconItem(Icons.ondemand_video, "ভিডিও ক্লাস", Colors.redAccent, () {}),
                    _buildIconItem(Icons.work, "চাকরির খবর", Colors.teal, () {}),
                    _buildIconItem(Icons.book, "ই-বুকস", Colors.purple, () {}),
                    _buildIconItem(Icons.pie_chart, "পারফরম্যান্স", Colors.indigo, () {}),
                  ],
                ),

                SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("সাম্প্রতিক ঘটনাবলী", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CAScreen(currentAffairs: currentAffairs))), child: Text("সব দেখুন >", style: TextStyle(color: Color(0xFFD32F2F)))),
                    ],
                  ),
                ),

                currentAffairs.isEmpty
                    ? Padding(padding: EdgeInsets.all(16), child: Text("শীঘ্রই নতুন আপডেট আসছে..."))
                    : Container(
                        height: 190,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          itemCount: currentAffairs.length,
                          itemBuilder: (ctx, i) {
                            var ca = currentAffairs[i];
                            return Container(
                              width: 230,
                              margin: EdgeInsets.only(right: 12, bottom: 8),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                                    child: Image.network(
                                      ca['imageUrl'] ?? '',
                                      height: 105,
                                      width: 230,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(height: 105, color: Colors.grey[200], child: Icon(Icons.image, color: Colors.grey)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(ca['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                SizedBox(height: 30),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildIconItem(IconData icon, String title, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 6),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSimplePlaceholder(String title) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: Color(0xFFD32F2F)),
      body: Center(child: Text("$title শীঘ্রই যোগ করা হবে")),
    );
  }

  Widget _buildProfileTab() {
    return Scaffold(
      appBar: AppBar(title: Text("প্রোফাইল"), backgroundColor: Color(0xFFD32F2F)),
      body: ListView(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Color(0xFFD32F2F)),
            accountName: Text("সনৎ কুমার দাস"),
            accountEmail: Text("সিভিল সার্ভিস পরীক্ষার্থী"),
            currentAccountPicture: CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, size: 40, color: Color(0xFFD32F2F))),
          ),
          ListTile(leading: Icon(Icons.bookmark), title: Text("সংরক্ষিত কুইজ"), onTap: () {}),
          ListTile(leading: Icon(Icons.history), title: Text("টেস্ট ফলাফল"), onTap: () {}),
          ListTile(leading: Icon(Icons.info_outline), title: Text("অ্যাপ সম্পর্কে"), onTap: () {}),
        ],
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
      appBar: AppBar(title: Text("সাম্প্রতিক ঘটনাবলী"), backgroundColor: Color(0xFFD32F2F)),
      body: currentAffairs.isEmpty
          ? Center(child: Text("কোনো তথ্য পাওয়া যায়নি!"))
          : ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: currentAffairs.length,
              itemBuilder: (ctx, i) {
                var item = currentAffairs[i];
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(item['imageUrl'] ?? '', width: double.infinity, height: 180, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 180, color: Colors.grey[200], child: Icon(Icons.broken_image, size: 40))),
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['title'] ?? '', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            SizedBox(height: 6),
                            Text(item['description'] ?? '', style: TextStyle(fontSize: 13, color: Colors.black87)),
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
            title: Text("মক টেস্ট সমাপ্ত!"),
            content: Text("আপনার মোট স্কোর: $score / ${widget.questions.length}"),
            actions: [
              TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: Text("ফিরে যান"))
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
        appBar: AppBar(title: Text("ডেইলি টেস্ট"), backgroundColor: Color(0xFFD32F2F)),
        body: Center(child: Text("শীঘ্রই নতুন কুইজ আসছে...")),
      );
    }

    var q = widget.questions[currentQuestionIndex];
    List<dynamic> options = q['options'] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text("ডেইলি মক টেস্ট"), backgroundColor: Color(0xFFD32F2F)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("প্রশ্ন ${currentQuestionIndex + 1} / ${widget.questions.length}", style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(q['question'] ?? '', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 18),
            ...List.generate(options.length, (index) {
              Color btnColor = Colors.white;
              if (isAnswered) {
                if (index == q['correctIndex']) btnColor = Colors.green.shade100;
                else if (index == selectedAnswerIndex) btnColor = Colors.red.shade100;
              }

              return Container(
                margin: EdgeInsets.only(bottom: 10),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: btnColor,
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  onPressed: () => checkAnswer(index),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("${String.fromCharCode(65 + index)}. ${options[index]}", style: TextStyle(color: Colors.black87, fontSize: 14)),
                  ),
                ),
              );
            }),
            if (isAnswered) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade200)),
                child: Text("ব্যাখ্যা: ${q['explanation'] ?? 'নেই'}", style: TextStyle(fontSize: 13)),
              ),
              Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFD32F2F), padding: EdgeInsets.symmetric(vertical: 13)),
                onPressed: nextQuestion,
                child: Text(currentQuestionIndex == widget.questions.length - 1 ? "ফলাফল দেখুন" : "পরবর্তী প্রশ্ন", style: TextStyle(color: Colors.white)),
              )
            ]
          ],
        ),
      ),
    );
  }
}
