import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(TargetCivilServiceApp());
}

class TargetCivilServiceApp extends StatefulWidget {
  @override
  _TargetCivilServiceAppState createState() => _TargetCivilServiceAppState();
}

class _TargetCivilServiceAppState extends State<TargetCivilServiceApp> {
  bool isDarkMode = false;

  void toggleTheme(bool val) {
    setState(() => isDarkMode = val);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Target Civil Service',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFD32F2F),
        scaffoldBackgroundColor: const Color(0xFFF5F6F8),
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFD32F2F),
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'Roboto',
      ),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: AuthCheckScreen(toggleTheme: toggleTheme, isDarkMode: isDarkMode),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthCheckScreen extends StatefulWidget {
  final Function(bool) toggleTheme;
  final bool isDarkMode;
  const AuthCheckScreen({required this.toggleTheme, required this.isDarkMode});

  @override
  _AuthCheckScreenState createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  bool isChecking = true;
  bool isLoggedIn = false;
  Map<String, dynamic> userData = {};

  @override
  void initState() {
    super.initState();
    checkUser();
  }

  Future<void> checkUser() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('u_phone');
    if (phone != null && phone.isNotEmpty) {
      setState(() {
        isLoggedIn = true;
        userData = {
          'name': prefs.getString('u_name') ?? 'শিক্ষার্থী',
          'phone': phone,
          'exam': prefs.getString('u_exam') ?? 'WBCS',
          'roll': prefs.getInt('u_roll') ?? 1,
          'image': prefs.getString('u_image') ?? '',
          'isPremium': prefs.getBool('u_premium') ?? false,
          'streak': prefs.getInt('u_streak') ?? 1,
        };
        isChecking = false;
      });
    } else {
      setState(() => isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isChecking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F))));
    }
    return isLoggedIn
        ? AddaRootScreen(
            userData: userData,
            toggleTheme: widget.toggleTheme,
            isDarkMode: widget.isDarkMode,
          )
        : LoginFlowScreen(toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode);
  }
}

class LoginFlowScreen extends StatefulWidget {
  final Function(bool) toggleTheme;
  final bool isDarkMode;
  const LoginFlowScreen({required this.toggleTheme, required this.isDarkMode});

  @override
  _LoginFlowScreenState createState() => _LoginFlowScreenState();
}

class _LoginFlowScreenState extends State<LoginFlowScreen> {
  final String firebaseUrl = "https://target-civil-service-default-rtdb.firebaseio.com";
  int step = 1;
  final phoneCtrl = TextEditingController();
  final otpCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final examCtrl = TextEditingController(text: "WBCS / WBPSC");
  final imgCtrl = TextEditingController();
  String generatedOtp = "1234";

  void sendOtp() {
    if (phoneCtrl.text.trim().length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("সঠিক ১০ সংখ্যার মোবাইল নম্বর লিখুন")));
      return;
    }
    setState(() {
      generatedOtp = "1234";
      step = 2;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("আপনার ওটিপি কোড হলো: $generatedOtp")));
  }

  void verifyOtp() {
    if (otpCtrl.text.trim() == generatedOtp) {
      setState(() => step = 3);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ভুল ওটিপি! পুনরায় চেষ্টা করুন")));
    }
  }

  Future<void> completeRegistration() async {
    if (nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("আপনার সম্পূর্ণ নাম লিখুন")));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    int currentRoll = (prefs.getInt('u_roll') ?? 0) + 1;

    final profile = {
      'name': nameCtrl.text.trim(),
      'phone': phoneCtrl.text.trim(),
      'exam': examCtrl.text.trim(),
      'roll': currentRoll,
      'image': imgCtrl.text.trim(),
      'score': 0,
      'isPremium': false,
      'streak': 1,
      'registeredAt': DateTime.now().toIso8601String(),
    };

    // লোকাল ফোনে আগে তথ্য সংরক্ষণ করে সরাসরি সফলভাবে ভেতরে ঢুকিয়ে দেবে
    await prefs.setString('u_name', profile['name'] as String);
    await prefs.setString('u_phone', profile['phone'] as String);
    await prefs.setString('u_exam', profile['exam'] as String);
    await prefs.setInt('u_roll', currentRoll);
    await prefs.setString('u_image', profile['image'] as String);
    await prefs.setBool('u_premium', false);
    await prefs.setInt('u_streak', 1);

    // ব্যাকগ্রাউন্ডে ক্লাউডে পাঠাবে
    http.put(
      Uri.parse('$firebaseUrl/users/${phoneCtrl.text.trim()}.json'),
      body: jsonEncode(profile),
    ).catchError((_) {});

    // কোনো এরর না দেখিয়ে সরাসরি হোম স্ক্রিনে প্রবেশ
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AddaRootScreen(
          userData: profile,
          toggleTheme: widget.toggleTheme,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFD32F2F).withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.school, size: 45, color: Color(0xFFD32F2F)),
              ),
              const SizedBox(height: 20),
              Text(
                step == 1 ? "মোবাইল নম্বর লিখুন" : (step == 2 ? "ওটিপি যাচাইকরণ" : "শিক্ষার্থী প্রোফাইল"),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                step == 1 ? "লগইন করতে আপনার ফোন নম্বর দিন" : (step == 2 ? "স্ক্রিনে আসা ৪ সংখ্যার কোড লিখুন" : "আপনার বিবরণ পূরণ করুন"),
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              if (step == 1) ...[
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(labelText: "মোবাইল নম্বর", prefixText: "+91 ", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
                    onPressed: sendOtp,
                    child: const Text("ওটিপি পাঠান", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ] else if (step == 2) ...[
                TextField(
                  controller: otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(labelText: "৪ সংখ্যার ওটিপি", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
                    onPressed: verifyOtp,
                    child: const Text("ওটিপি যাচাই করুন", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ] else ...[
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "আপনার সম্পূর্ণ নাম", border: OutlineInputBorder())),
                const SizedBox(height: 14),
                TextField(controller: examCtrl, decoration: const InputDecoration(labelText: "টার্গেট পরীক্ষা", border: OutlineInputBorder())),
                const SizedBox(height: 14),
                TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: "প্রোফাইল ছবির লিঙ্ক (ঐচ্ছিক)", border: OutlineInputBorder())),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
                    onPressed: completeRegistration,
                    child: const Text("প্রবেশ করুন", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class AddaRootScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(bool) toggleTheme;
  final bool isDarkMode;
  const AddaRootScreen({required this.userData, required this.toggleTheme, required this.isDarkMode});

  @override
  _AddaRootScreenState createState() => _AddaRootScreenState();
}

class _AddaRootScreenState extends State<AddaRootScreen> {
  int _selectedIndex = 0;
  final String firebaseUrl = "https://target-civil-service-default-rtdb.firebaseio.com";
  final String adminId = "sanat";
  final String adminPass = "1234";

  List<Map<String, dynamic>> questions = [];
  List<Map<String, dynamic>> studyNotes = [];
  List<Map<String, dynamic>> liveClasses = [];
  List<Map<String, dynamic>> registeredUsers = [];
  List<Map<String, dynamic>> achievers = [];
  List<Map<String, dynamic>> jobAlerts = [];
  List<Map<String, dynamic>> doubts = [];
  List<Map<String, dynamic>> flashcards = [];
  List<Map<String, dynamic>> paymentRequests = [];
  String appNotice = "নমস্কার! নতুন WBCS মক টেস্ট আপলোড করা হয়েছে।";
  List<String> bookmarkedIds = [];
  List<String> studentNotes = [];
  List<Map<String, dynamic>> studyTodos = [];

  int pollVotesA = 48;
  int pollVotesB = 14;
  int? userVotedOption;

  @override
  void initState() {
    super.initState();
    fetchAllData();
    loadLocalData();
  }

  Future<void> loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      bookmarkedIds = prefs.getStringList('bookmarks') ?? [];
      studentNotes = prefs.getStringList('student_notes') ?? [];
      String? todosRaw = prefs.getString('study_todos');
      if (todosRaw != null) {
        studyTodos = List<Map<String, dynamic>>.from(jsonDecode(todosRaw));
      }
    });
  }

  Future<void> toggleBookmark(String qId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (bookmarkedIds.contains(qId)) {
        bookmarkedIds.remove(qId);
      } else {
        bookmarkedIds.add(qId);
      }
      prefs.setStringList('bookmarks', bookmarkedIds);
    });
  }

  Future<void> saveStudentNotes(List<String> notes) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => studentNotes = notes);
    prefs.setStringList('student_notes', notes);
  }

  Future<void> saveTodos(List<Map<String, dynamic>> todos) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => studyTodos = todos);
    prefs.setString('study_todos', jsonEncode(todos));
  }

  Future<void> fetchAllData() async {
    try {
      final qRes = await http.get(Uri.parse('$firebaseUrl/questions.json')).timeout(const Duration(seconds: 4));
      final snRes = await http.get(Uri.parse('$firebaseUrl/study_notes.json')).timeout(const Duration(seconds: 4));
      final lcRes = await http.get(Uri.parse('$firebaseUrl/live_classes.json')).timeout(const Duration(seconds: 4));
      final uRes = await http.get(Uri.parse('$firebaseUrl/users.json')).timeout(const Duration(seconds: 4));
      final jobRes = await http.get(Uri.parse('$firebaseUrl/job_alerts.json')).timeout(const Duration(seconds: 4));
      final dRes = await http.get(Uri.parse('$firebaseUrl/doubts.json')).timeout(const Duration(seconds: 4));
      final fcRes = await http.get(Uri.parse('$firebaseUrl/flashcards.json')).timeout(const Duration(seconds: 4));
      final prRes = await http.get(Uri.parse('$firebaseUrl/payment_requests.json')).timeout(const Duration(seconds: 4));
      final noticeRes = await http.get(Uri.parse('$firebaseUrl/app_notice.json')).timeout(const Duration(seconds: 4));

      List<Map<String, dynamic>> parseMap(http.Response res) {
        List<Map<String, dynamic>> list = [];
        if (res.statusCode == 200 && res.body != 'null') {
          Map<String, dynamic> data = jsonDecode(res.body);
          data.forEach((key, val) {
            var item = Map<String, dynamic>.from(val);
            item['id'] = key;
            list.add(item);
          });
        }
        return list;
      }

      setState(() {
        questions = parseMap(qRes);
        studyNotes = parseMap(snRes);
        liveClasses = parseMap(lcRes);
        registeredUsers = parseMap(uRes);
        jobAlerts = parseMap(jobRes);
        doubts = parseMap(dRes);
        flashcards = parseMap(fcRes);
        paymentRequests = parseMap(prRes);
        if (noticeRes.statusCode == 200 && noticeRes.body != 'null') {
          appNotice = jsonDecode(noticeRes.body)['text'] ?? appNotice;
        }
      });
    } catch (_) {}
  }

  Future<void> pushCloudData(String path, Map<String, dynamic> data) async {
    await http.post(Uri.parse('$firebaseUrl/$path.json'), body: jsonEncode(data));
    fetchAllData();
  }

  Future<void> removeCloudData(String path, String id) async {
    await http.delete(Uri.parse('$firebaseUrl/$path/$id.json'));
    fetchAllData();
  }

  void openWhatsAppSupport() async {
    const phone = "+919876543210";
    final url = Uri.parse("https://wa.me/$phone?text=নমস্কার, টার্গেট সিভিল সার্ভিস অ্যাপ সংক্রান্ত সাহায্য চাই।");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void showAdminLogin() {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("অ্যাডমিন ক্লাউড কন্ট্রোল", style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: userCtrl, decoration: const InputDecoration(labelText: "আইডি")),
            TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: "পাসওয়ার্ড")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("বাতিল")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () {
              if (userCtrl.text.trim() == adminId && passCtrl.text.trim() == adminPass) {
                Navigator.pop(ctx);
                openMasterAdminHub();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("অনুমতি নেই!")));
              }
            },
            child: const Text("প্রবেশ", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void openMasterAdminHub() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DefaultTabController(
        length: 7,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.90,
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              const TabBar(
                isScrollable: true,
                labelColor: Color(0xFFD32F2F),
                indicatorColor: Color(0xFFD32F2F),
                tabs: [
                  Tab(text: "নোটিশ ব্রডকাস্ট"),
                  Tab(text: "পেমেন্ট অনুমোদন"),
                  Tab(text: "ছাত্র তালিকা (SMS)"),
                  Tab(text: "দ্বিভাষিক কুইজ"),
                  Tab(text: "ফ্ল্যাশ কার্ড"),
                  Tab(text: "ইউটিউব ক্লাস"),
                  Tab(text: "পিডিএফ নোটস"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _adminNoticeSection(),
                    _adminPaymentSection(),
                    _adminUserSection(),
                    _adminQuestionSection(),
                    _adminFlashcardSection(),
                    _adminGenericSection("live_classes", liveClasses, "নতুন ক্লাস যোগ", "ক্লাসের নাম", "শিক্ষক / তারিখ", "YouTube লিঙ্ক"),
                    _adminGenericSection("study_notes", studyNotes, "নতুন নোটস যোগ", "শিরোনাম", "বিবরণ", "পিডিএফ লিঙ্ক"),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _adminNoticeSection() {
    final nCtrl = TextEditingController(text: appNotice);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text("হোম স্ক্রিনের টপ নোটিশ পরিবর্তন করুন", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: nCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "নোটিশ লিখুন", border: OutlineInputBorder())),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), minimumSize: const Size(double.infinity, 45)),
            onPressed: () async {
              await http.put(
                Uri.parse('$firebaseUrl/app_notice.json'),
                body: jsonEncode({'text': nCtrl.text.trim()}),
              );
              fetchAllData();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("নোটিশ আপডেট হয়েছে!")));
            },
            child: const Text("সবার ফোনে আপডেট করুন", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget _adminPaymentSection() {
    return Column(
      children: [
        Expanded(
          child: paymentRequests.isEmpty
              ? const Center(child: Text("কোনো পেন্ডিং পেমেন্ট রিকোয়েস্ট নেই!"))
              : ListView.builder(
                  itemCount: paymentRequests.length,
                  itemBuilder: (ctx, i) => Card(
                    child: ListTile(
                      title: Text("শিক্ষার্থী: ${paymentRequests[i]['userName']}"),
                      subtitle: Text("ফোন: +91 ${paymentRequests[i]['phone']}\nUTR: ${paymentRequests[i]['utr']}"),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text("Approve", style: TextStyle(color: Colors.white, fontSize: 12)),
                        onPressed: () async {
                          await http.patch(
                            Uri.parse('$firebaseUrl/users/${paymentRequests[i]['phone']}.json'),
                            body: jsonEncode({'isPremium': true}),
                          );
                          await removeCloudData("payment_requests", paymentRequests[i]['id']);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("প্রিমিয়াম অ্যাক্টিভেট সম্পন্ন!")));
                        },
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _adminFlashcardSection() {
    return Column(
      children: [
        Expanded(
          child: flashcards.isEmpty
              ? const Center(child: Text("কোনো ফ্ল্যাশ কার্ড নেই!"))
              : ListView.builder(
                  itemCount: flashcards.length,
                  itemBuilder: (ctx, i) => Card(
                    child: ListTile(
                      title: Text(flashcards[i]['word'] ?? ''),
                      subtitle: Text(flashcards[i]['meaning'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => removeCloudData("flashcards", flashcards[i]['id']),
                      ),
                    ),
                  ),
                ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), minimumSize: const Size(double.infinity, 45)),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("নতুন ফ্ল্যাশ কার্ড পোস্ট করুন", style: TextStyle(color: Colors.white)),
          onPressed: () {
            final wCtrl = TextEditingController();
            final mCtrl = TextEditingController();
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("নতুন ফ্ল্যাশ কার্ড"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: wCtrl, decoration: const InputDecoration(labelText: "শব্দ / তথ্য")),
                    TextField(controller: mCtrl, decoration: const InputDecoration(labelText: "অর্থ / সংক্ষিপ্ত বিবরণ")),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      if (wCtrl.text.isNotEmpty) {
                        pushCloudData("flashcards", {'word': wCtrl.text.trim(), 'meaning': mCtrl.text.trim()});
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text("সেভ করুন"),
                  )
                ],
              ),
            );
          },
        )
      ],
    );
  }

  Widget _adminQuestionSection() {
    return Column(
      children: [
        Expanded(
          child: questions.isEmpty
              ? const Center(child: Text("কোনো কুইজ প্রশ্ন নেই!"))
              : ListView.builder(
                  itemCount: questions.length,
                  itemBuilder: (ctx, i) => Card(
                    child: ListTile(
                      title: Text(questions[i]['question'] ?? ''),
                      subtitle: Text("বিকল্প ${(questions[i]['correctIndex'] ?? 0) + 1}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => removeCloudData("questions", questions[i]['id']),
                      ),
                    ),
                  ),
                ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), minimumSize: const Size(double.infinity, 45)),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("নতুন প্রশ্ন যোগ করুন", style: TextStyle(color: Colors.white)),
          onPressed: _showAddQuestionDialog,
        )
      ],
    );
  }

  void _showAddQuestionDialog() {
    final qBn = TextEditingController(), qEn = TextEditingController();
    final o1 = TextEditingController(), o2 = TextEditingController(), o3 = TextEditingController(), o4 = TextEditingController();
    final exp = TextEditingController();
    String sub = "ইতিহাস";
    int cIdx = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setF) => AlertDialog(
          title: const Text("দ্বিভাষিক কুইজ প্রশ্ন"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: sub,
                  items: ["ইতিহাস", "ভূগোল", "সংবিধান", "গণিত", "বিজ্ঞান", "কারেন্ট অ্যাফেয়ার্স", "PYQ (বিগত বছর)"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setF(() => sub = v!),
                  decoration: const InputDecoration(labelText: "বিষয় নির্বাচন"),
                ),
                TextField(controller: qBn, decoration: const InputDecoration(labelText: "প্রশ্ন (বাংলা)")),
                TextField(controller: qEn, decoration: const InputDecoration(labelText: "Question (English)")),
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
                if (qBn.text.isNotEmpty && o1.text.isNotEmpty) {
                  pushCloudData("questions", {
                    'subject': sub,
                    'question': qBn.text.trim(),
                    'questionEn': qEn.text.trim().isEmpty ? qBn.text.trim() : qEn.text.trim(),
                    'options': [o1.text.trim(), o2.text.trim(), o3.text.trim(), o4.text.trim()],
                    'correctIndex': cIdx,
                    'explanation': exp.text.trim(),
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

  Widget _adminGenericSection(String path, List<Map<String, dynamic>> items, String btnTitle, String label1, String label2, String label3) {
    return Column(
      children: [
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text("কোনো তথ্য নেই!"))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => Card(
                    child: ListTile(
                      title: Text(items[i]['title'] ?? ''),
                      subtitle: Text(items[i]['subtitle'] ?? items[i]['description'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => removeCloudData(path, items[i]['id']),
                      ),
                    ),
                  ),
                ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), minimumSize: const Size(double.infinity, 45)),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(btnTitle, style: const TextStyle(color: Colors.white)),
          onPressed: () {
            final t1 = TextEditingController();
            final t2 = TextEditingController();
            final t3 = TextEditingController();

            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("নতুন তথ্য সংযোজন"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: t1, decoration: InputDecoration(labelText: label1)),
                    TextField(controller: t2, decoration: InputDecoration(labelText: label2)),
                    TextField(controller: t3, decoration: InputDecoration(labelText: label3)),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      if (t1.text.isNotEmpty) {
                        pushCloudData(path, {
                          'title': t1.text.trim(),
                          'subtitle': t2.text.trim(),
                          'description': t2.text.trim(),
                          'url': t3.text.trim(),
                          'imageUrl': t3.text.trim(),
                          'date': DateTime.now().toString().substring(0, 10),
                        });
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text("পোস্ট করুন"),
                  )
                ],
              ),
            );
          },
        )
      ],
    );
  }

  Widget _adminUserSection() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("মোট রেজিস্টার্ড ছাত্র: ${registeredUsers.length}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                icon: const Icon(Icons.copy, size: 16, color: Colors.white),
                label: const Text("সব নম্বর কপি", style: TextStyle(color: Colors.white, fontSize: 12)),
                onPressed: () {
                  if (registeredUsers.isEmpty) return;
                  String allPhones = registeredUsers.map((u) => u['phone']?.toString() ?? '').where((p) => p.isNotEmpty).join(',');
                  Clipboard.setData(ClipboardData(text: allPhones));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("সবগুলো নম্বর ক্লিপবোর্ডে কপি হয়েছে!")));
                },
              )
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: registeredUsers.length,
            itemBuilder: (ctx, i) {
              var u = registeredUsers[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: const Color(0xFFD32F2F), child: Text("${u['roll'] ?? (i + 1)}", style: const TextStyle(color: Colors.white))),
                  title: Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("ফোন: +91 ${u['phone']}\nস্ট্যাটাস: ${u['isPremium'] == true ? '⭐ প্রিমিয়াম' : 'ফ্রি'}"),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginFlowScreen(toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode)),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeDashboard(),
          LiveClassesScreen(classes: liveClasses),
          SubjectExamScreen(questions: questions, userPhone: widget.userData['phone'], onBookmark: toggleBookmark, bookmarkedIds: bookmarkedIds),
          StudyNotesScreen(notes: studyNotes),
          DoubtForumScreen(doubts: doubts, userName: widget.userData['name'], firebaseUrl: firebaseUrl, onRefresh: fetchAllData),
          LeaderboardScreen(users: registeredUsers),
          JobAlertsScreen(jobs: jobAlerts),
          FlashcardScreen(cards: flashcards),
          SyllabusScreen(),
          StudentNotebookScreen(notes: studentNotes, onSave: saveStudentNotes),
          StudyPlannerScreen(todos: studyTodos, onSave: saveTodos),
          PaymentScreen(userName: widget.userData['name'], phone: widget.userData['phone'], firebaseUrl: firebaseUrl),
          _buildProfileTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green.shade700,
        icon: const Icon(Icons.chat, color: Colors.white),
        label: const Text("WhatsApp সাপোর্ট", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: openWhatsAppSupport,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFD32F2F),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.live_tv), label: "Live"),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: "Tests"),
          BottomNavigationBarItem(icon: Icon(Icons.picture_as_pdf), label: "Notes"),
          BottomNavigationBarItem(icon: Icon(Icons.question_answer), label: "Doubts"),
        ],
      ),
    );
  }

  Widget _buildHomeDashboard() {
    return RefreshIndicator(
      onRefresh: fetchAllData,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: const Color(0xFFD32F2F),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: widget.userData['image'].toString().isNotEmpty ? NetworkImage(widget.userData['image']) : null,
                  backgroundColor: Colors.white24,
                  child: widget.userData['image'].toString().isEmpty ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onLongPress: showAdminLogin,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16)),
                    child: Text("${widget.userData['exam']} ▾", style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.amber.shade800, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: Colors.white, size: 16),
                    Text(" ${widget.userData['streak'] ?? 1} দিন", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.white), onPressed: () => widget.toggleTheme(!widget.isDarkMode)),
              IconButton(icon: const Icon(Icons.workspace_premium, color: Colors.amber), onPressed: () => setState(() => _selectedIndex = 11)),
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: fetchAllData),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.amber.shade100,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.campaign, color: Colors.deepOrange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(appNotice, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFD32F2F), Color(0xFFFF5252)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("নমস্কার, ${widget.userData['name']}!", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("রোল নং: #${widget.userData['roll']} | লক্ষ্য: ${widget.userData['exam']}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(6)),
                              child: const Text("⏳ WBCS প্রিলিমস বাকি: ৫৪ দিন", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.military_tech, size: 50, color: Colors.white),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text("📊 আজকের পোল (Poll of the Day)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD32F2F))),
                          Text("লাইভ ভোট", style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text("সংবিধানের কত নম্বর ধারা অনুযায়ী জাতীয় জরুরি অবস্থা ঘোষণা করা হয়?", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(backgroundColor: userVotedOption == 1 ? Colors.green.shade50 : null),
                              onPressed: () => setState(() { userVotedOption = 1; pollVotesA++; }),
                              child: Text("ধারা ৩৫২ (${pollVotesA} ভোট)", style: const TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(backgroundColor: userVotedOption == 2 ? Colors.red.shade50 : null),
                              onPressed: () => setState(() { userVotedOption = 2; pollVotesB++; }),
                              child: Text("ধারা ৩৫৬ (${pollVotesB} ভোট)", style: const TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.0),
                  child: Text("STUDY MATERIAL & TOOLS", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    _buildIconItem(Icons.live_tv, "লাইভ ক্লাস", Colors.red, () => setState(() => _selectedIndex = 1)),
                    _buildIconItem(Icons.timer, "মক টেস্ট", Colors.deepOrange, () => setState(() => _selectedIndex = 2)),
                    _buildIconItem(Icons.picture_as_pdf, "পিডিএফ নোটস", Colors.green, () => setState(() => _selectedIndex = 3)),
                    _buildIconItem(Icons.question_answer, "ডাউট ফোরাম", Colors.purple, () => setState(() => _selectedIndex = 4)),
                    _buildIconItem(Icons.leaderboard, "স্টেট র‍্যাঙ্ক", Colors.indigo, () => setState(() => _selectedIndex = 5)),
                    _buildIconItem(Icons.work, "চাকরির খবর", Colors.teal, () => setState(() => _selectedIndex = 6)),
                    _buildIconItem(Icons.style, "ফ্ল্যাশ কার্ড", Colors.orange, () => setState(() => _selectedIndex = 7)),
                    _buildIconItem(Icons.menu_book, "সিলেবাস", Colors.brown, () => setState(() => _selectedIndex = 8)),
                    _buildIconItem(Icons.note_alt, "নোটপ্যাড", Colors.cyan.shade800, () => setState(() => _selectedIndex = 9)),
                    _buildIconItem(Icons.checklist, "ডেইলি টার্গেট", Colors.pink.shade700, () => setState(() => _selectedIndex = 10)),
                    _buildIconItem(Icons.workspace_premium, "প্রিমিয়াম", Colors.amber.shade900, () => setState(() => _selectedIndex = 11)),
                    _buildIconItem(Icons.person, "প্রোফাইল", Colors.blue, () => setState(() => _selectedIndex = 12)),
                  ],
                ),
                const SizedBox(height: 40),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return Scaffold(
      appBar: AppBar(title: const Text("প্রোফাইল"), backgroundColor: const Color(0xFFD32F2F)),
      body: ListView(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFD32F2F)),
            accountName: Text(widget.userData['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            accountEmail: Text("রোল নং: #${widget.userData['roll']} | ফোন: +91 ${widget.userData['phone']}"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: widget.userData['image'].toString().isNotEmpty ? NetworkImage(widget.userData['image']) : null,
              child: widget.userData['image'].toString().isEmpty ? Text(widget.userData['name'][0].toUpperCase(), style: const TextStyle(fontSize: 26, color: Color(0xFFD32F2F))) : null,
            ),
          ),
          ListTile(leading: const Icon(Icons.school), title: const Text("টার্গেট পরীক্ষা"), subtitle: Text(widget.userData['exam'])),
          ListTile(
            leading: const Icon(Icons.workspace_premium, color: Colors.amber),
            title: const Text("মেম্বারশিপ স্ট্যাটাস"),
            subtitle: Text(widget.userData['isPremium'] == true ? "প্রিমিয়াম সদস্য" : "ফ্রি সংস্করণ (আপগ্রেড করুন)"),
            onTap: () => setState(() => _selectedIndex = 11),
          ),
          ListTile(leading: const Icon(Icons.local_fire_department, color: Colors.orange), title: const Text("ডেইলি স্টাডি স্ট্রিক"), subtitle: Text("${widget.userData['streak'] ?? 1} দিন সক্রিয়")),
          SwitchListTile(
            secondary: const Icon(Icons.brightness_6),
            title: const Text("ডার্ক মোড (Dark Mode)"),
            value: widget.isDarkMode,
            onChanged: widget.toggleTheme,
          ),
          const Divider(),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("লগআউট", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), onTap: logout),
        ],
      ),
    );
  }
}

class StudentNotebookScreen extends StatefulWidget {
  final List<String> notes;
  final Function(List<String>) onSave;
  const StudentNotebookScreen({required this.notes, required this.onSave});

  @override
  _StudentNotebookScreenState createState() => _StudentNotebookScreenState();
}

class _StudentNotebookScreenState extends State<StudentNotebookScreen> {
  late List<String> localNotes;

  @override
  void initState() {
    super.initState();
    localNotes = List.from(widget.notes);
  }

  void addNoteDialog() {
    final nCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("নতুন নোট লিখুন"),
        content: TextField(controller: nCtrl, maxLines: 4, decoration: const InputDecoration(labelText: "পড়ার সূত্র বা তথ্য লিখুন")),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (nCtrl.text.isNotEmpty) {
                setState(() => localNotes.add(nCtrl.text.trim()));
                widget.onSave(localNotes);
                Navigator.pop(ctx);
              }
            },
            child: const Text("সেভ করুন"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("আমার পার্সোনাল নোটপ্যাড"), backgroundColor: const Color(0xFFD32F2F)),
      body: localNotes.isEmpty
          ? const Center(child: Text("কোনো নোট নেই! নিচের বাটনে চাপ দিয়ে নতুন নোট লিখুন।"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: localNotes.length,
              itemBuilder: (ctx, i) => Card(
                child: ListTile(
                  title: Text(localNotes[i]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() => localNotes.removeAt(i));
                      widget.onSave(localNotes);
                    },
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD32F2F),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: addNoteDialog,
      ),
    );
  }
}

class StudyPlannerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> todos;
  final Function(List<Map<String, dynamic>>) onSave;
  const StudyPlannerScreen({required this.todos, required this.onSave});

  @override
  _StudyPlannerScreenState createState() => _StudyPlannerScreenState();
}

class _StudyPlannerScreenState extends State<StudyPlannerScreen> {
  late List<Map<String, dynamic>> localTodos;

  @override
  void initState() {
    super.initState();
    localTodos = List.from(widget.todos);
  }

  void addTodoDialog() {
    final tCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("আজকের স্টাডি টার্গেট"),
        content: TextField(controller: tCtrl, decoration: const InputDecoration(labelText: "যেমন: আধুনিক ভারতের ইতিহাস অধ্যায় ৫")),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (tCtrl.text.isNotEmpty) {
                setState(() => localTodos.add({'title': tCtrl.text.trim(), 'done': false}));
                widget.onSave(localTodos);
                Navigator.pop(ctx);
              }
            },
            child: const Text("যুক্ত করুন"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ডেইলি স্টাডি প্ল্যানার"), backgroundColor: const Color(0xFFD32F2F)),
      body: localTodos.isEmpty
          ? const Center(child: Text("আজকের কোনো পড়ার টার্গেট সেট করা হয়নি!"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: localTodos.length,
              itemBuilder: (ctx, i) => Card(
                child: CheckboxListTile(
                  title: Text(
                    localTodos[i]['title'],
                    style: TextStyle(decoration: localTodos[i]['done'] ? TextDecoration.lineThrough : null),
                  ),
                  value: localTodos[i]['done'],
                  onChanged: (val) {
                    setState(() => localTodos[i]['done'] = val ?? false);
                    widget.onSave(localTodos);
                  },
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD32F2F),
        child: const Icon(Icons.add_task, color: Colors.white),
        onPressed: addTodoDialog,
      ),
    );
  }
}

class QuizPlayScreen extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final String userPhone;
  final Function(String) onBookmark;
  final List<String> bookmarkedIds;

  const QuizPlayScreen({required this.questions, required this.userPhone, required this.onBookmark, required this.bookmarkedIds});

  @override
  _QuizPlayScreenState createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  int currentIdx = 0;
  double score = 0.0;
  int correctCount = 0;
  int wrongCount = 0;
  int? selected;
  int remainingSeconds = 600;
  Timer? timer;
  bool isEnglish = false;
  bool isOmrMode = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--);
      } else {
        t.cancel();
        submitExam();
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void submitExam() async {
    timer?.cancel();
    try {
      await http.patch(
        Uri.parse("https://target-civil-service-default-rtdb.firebaseio.com/users/${widget.userPhone}.json"),
        body: jsonEncode({'score': score.toInt()}),
      );
    } catch (_) {}

    int totalTimeSpent = 600 - remainingSeconds;
    double accuracy = (correctCount + wrongCount) > 0 ? (correctCount / (correctCount + wrongCount)) * 100 : 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("📊 পারফরম্যান্স অ্যানালিটিক্স রিপোর্ট", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("মোট প্রাপ্ত নম্বর: ${score.toStringAsFixed(2)} / ${widget.questions.length}"),
            const SizedBox(height: 6),
            Text("✅ সঠিক উত্তর: $correctCount টি", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            Text("❌ ভুল উত্তর: $wrongCount টি (প্রতিটিতে -০.২৫)", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            Text("⏱️ সময় লেগেছে: ${totalTimeSpent ~/ 60} মিনিট ${totalTimeSpent % 60} সেকেন্ড"),
            Text("🎯 নির্ভুলতা (Accuracy): ${accuracy.toStringAsFixed(1)}%"),
          ],
        ),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text("হোমে ফিরুন"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("মক টেস্ট"), backgroundColor: const Color(0xFFD32F2F)),
        body: const Center(child: Text("কোনো প্রশ্ন নেই!")),
      );
    }
    var q = widget.questions[currentIdx];
    List options = q['options'] ?? [];
    String qId = q['id'] ?? '';
    bool isBookmarked = widget.bookmarkedIds.contains(qId);

    int minutes = remainingSeconds ~/ 60;
    int seconds = remainingSeconds % 60;

    String questionText = isEnglish ? (q['questionEn'] ?? q['question']) : q['question'];

    return Scaffold(
      appBar: AppBar(
        title: Text("${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}"),
        backgroundColor: const Color(0xFFD32F2F),
        actions: [
          IconButton(
            icon: Icon(isEnglish ? Icons.language : Icons.translate, color: Colors.white),
            tooltip: "ভাষা পরিবর্তন",
            onPressed: () => setState(() => isEnglish = !isEnglish),
          ),
          IconButton(
            icon: Icon(isOmrMode ? Icons.view_list : Icons.circle_outlined, color: Colors.white),
            tooltip: "OMR মোড",
            onPressed: () => setState(() => isOmrMode = !isOmrMode),
          ),
          IconButton(
            icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, color: Colors.white),
            onPressed: () => widget.onBookmark(qId),
          ),
          TextButton(onPressed: submitExam, child: const Text("জমা দিন", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("বিষয়: ${q['subject'] ?? 'সাধারণ'} | প্রশ্ন ${currentIdx + 1} / ${widget.questions.length}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(questionText ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),

            if (isOmrMode) ...[
              const Text("OMR বাবল স্পর্শ করে পূরণ করুন:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.deepOrange)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(options.length, (i) {
                  bool isChosen = selected == i;
                  return InkWell(
                    onTap: selected == null
                        ? () {
                            setState(() {
                              selected = i;
                              if (i == q['correctIndex']) {
                                score += 1.0;
                                correctCount++;
                              } else {
                                score -= 0.25;
                                wrongCount++;
                              }
                            });
                          }
                        : null,
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: isChosen ? Colors.black87 : Colors.grey.shade300,
                      child: Text(
                        String.fromCharCode(65 + i),
                        style: TextStyle(color: isChosen ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              ...List.generate(options.length, (i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text("${String.fromCharCode(65 + i)}. ${options[i]}", style: const TextStyle(fontSize: 14)),
              )),
            ] else ...[
              ...List.generate(options.length, (i) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selected != null ? (i == q['correctIndex'] ? Colors.green.shade100 : (selected == i ? Colors.red.shade100 : null)) : null,
                  ),
                  onPressed: selected == null ? () {
                    setState(() {
                      selected = i;
                      if (i == q['correctIndex']) {
                        score += 1.0;
                        correctCount++;
                      } else {
                        score -= 0.25;
                        wrongCount++;
                      }
                    });
                  } : null,
                  child: Text("${options[i]}"),
                ),
              )),
            ],

            if (selected != null) ...[
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
                onPressed: () {
                  setState(() {
                    if (currentIdx < widget.questions.length - 1) {
                      currentIdx++;
                      selected = null;
                    } else {
                      submitExam();
                    }
                  });
                },
                child: const Text("পরবর্তী প্রশ্ন", style: TextStyle(color: Colors.white)),
              )
            ]
          ],
        ),
      ),
    );
  }
}

class SubjectExamScreen extends StatelessWidget {
  final List<Map<String, dynamic>> questions;
  final String userPhone;
  final Function(String) onBookmark;
  final List<String> bookmarkedIds;

  const SubjectExamScreen({required this.questions, required this.userPhone, required this.onBookmark, required this.bookmarkedIds});

  @override
  Widget build(BuildContext context) {
    List<String> subjects = ["সমস্ত বিষয়", "ইতিহাস", "ভূগোল", "সংবিধান", "গণিত", "বিজ্ঞান", "কারেন্ট অ্যাফেয়ার্স", "PYQ (বিগত বছর)"];

    return Scaffold(
      appBar: AppBar(title: const Text("বিষয়ভিত্তিক মক টেস্ট জোন"), backgroundColor: const Color(0xFFD32F2F)),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: subjects.length,
        itemBuilder: (ctx, i) {
          String s = subjects[i];
          int count = s == "সমস্ত বিষয়" ? questions.length : questions.where((q) => q['subject'] == s).length;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFD32F2F), child: Icon(Icons.assignment, color: Colors.white)),
              title: Text(s, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text("মোট প্রশ্ন: $count টি"),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
                child: const Text("শুরু করুন", style: TextStyle(color: Colors.white)),
                onPressed: count == 0
                    ? null
                    : () {
                        List<Map<String, dynamic>> filtered = s == "সমস্ত বিষয়" ? questions : questions.where((q) => q['subject'] == s).toList();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizPlayScreen(questions: filtered, userPhone: userPhone, onBookmark: onBookmark, bookmarkedIds: bookmarkedIds),
                          ),
                        );
                      },
              ),
            ),
          );
        },
      ),
    );
  }
}

class DoubtForumScreen extends StatelessWidget {
  final List<Map<String, dynamic>> doubts;
  final String userName;
  final String firebaseUrl;
  final VoidCallback onRefresh;

  const DoubtForumScreen({required this.doubts, required this.userName, required this.firebaseUrl, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final dCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("ডাউট ফোরাম"), backgroundColor: const Color(0xFFD32F2F)),
      body: doubts.isEmpty
          ? const Center(child: Text("কোনো ডাউট নেই! নিচের বাটন চেপে প্রশ্ন করুন।"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: doubts.length,
              itemBuilder: (ctx, i) {
                var d = doubts[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(d['userName'] ?? 'শিক্ষার্থী', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                            Text(d['date'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(d['question'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const Divider(),
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                d['answer'] != null ? "শিক্ষকের উত্তর: ${d['answer']}" : "শীঘ্রই শিক্ষক উত্তর দেবেন...",
                                style: TextStyle(color: d['answer'] != null ? null : Colors.grey, fontStyle: d['answer'] != null ? FontStyle.normal : FontStyle.italic),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD32F2F),
        icon: const Icon(Icons.add_comment, color: Colors.white),
        label: const Text("প্রশ্ন করুন", style: TextStyle(color: Colors.white)),
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("আপনার ডাউট লিখুন"),
              content: TextField(controller: dCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "প্রশ্নটি লিখুন")),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    if (dCtrl.text.isNotEmpty) {
                      await http.post(
                        Uri.parse('$firebaseUrl/doubts.json'),
                        body: jsonEncode({
                          'userName': userName,
                          'question': dCtrl.text.trim(),
                          'date': DateTime.now().toString().substring(0, 10),
                        }),
                      );
                      onRefresh();
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text("পোস্ট করুন"),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}

class FlashcardScreen extends StatelessWidget {
  final List<Map<String, dynamic>> cards;
  const FlashcardScreen({required this.cards});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ডেইলি ফ্ল্যাশ কার্ড"), backgroundColor: const Color(0xFFD32F2F)),
      body: cards.isEmpty
          ? const Center(child: Text("শীঘ্রই নতুন ফ্ল্যাশ কার্ড যোগ করা হবে!"))
          : PageView.builder(
              itemCount: cards.length,
              itemBuilder: (ctx, i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.orange.shade100, Colors.amber.shade50]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lightbulb, size: 50, color: Colors.orange),
                    const SizedBox(height: 20),
                    Text(cards[i]['word'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
                    const Divider(height: 40),
                    Text(cards[i]['meaning'] ?? '', style: const TextStyle(fontSize: 16, color: Colors.black87), textAlign: TextAlign.center),
                    const Spacer(),
                    const Text("পরবর্তী কার্ডের জন্য সোয়াইপ করুন 👉", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ),
    );
  }
}

class SyllabusScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("পরীক্ষার সিলেবাস ও গাইড"), backgroundColor: const Color(0xFFD32F2F)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          ExpansionTile(
            title: Text("WBCS প্রিলিমস সিলেবাস ও বুক-লিস্ট", style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              Padding(
                padding: EdgeInsets.all(12.0),
                child: Text("• ইংরেজি (২৫ নম্বর) - SP Bakshi\n• ভারতীয় ইতিহাস ও জাতীয় আন্দোলন (৫০ নম্বর)\n• ভারতের ভূগোল ও পশ্চিমবঙ্গ (২৫ নম্বর)\n• সংবিধান ও অর্থনীতি (২৫ নম্বর)\n• সাধারণ বিজ্ঞান (২৫ নম্বর)\n• কারেন্ট অ্যাফেয়ার্স (২৫ নম্বর)\n• জিআই ও গণিত (২৫ নম্বর)"),
              )
            ],
          ),
          ExpansionTile(
            title: Text("WBPSC Food SI ও ক্লার্কশিপ সিলেবাস", style: TextStyle(fontWeight: FontWeight.bold)),
            children: [
              Padding(
                padding: EdgeInsets.all(12.0),
                child: Text("• সাধারণ জ্ঞান ও কারেন্ট অ্যাফেয়ার্স (৫০ নম্বর)\n• পাটিগণিত ও গণিত (৫০ নম্বর)\n• সময়: ৯০ মিনিট"),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class PaymentScreen extends StatelessWidget {
  final String userName;
  final String phone;
  final String firebaseUrl;

  const PaymentScreen({required this.userName, required this.phone, required this.firebaseUrl});

  @override
  Widget build(BuildContext context) {
    final utrCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("প্রিমিয়াম ব্যাচ অ্যাক্টিভেশন"), backgroundColor: const Color(0xFFD32F2F)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("টার্গেট সিভিল সার্ভিস প্রিমিয়াম মেম্বারশিপ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text("সমস্ত মেগা মক টেস্ট, স্পেশাল পিডিএফ ও ভিডিও ক্লাস আনলক করুন মাত্র ১৯৯ টাকায়।", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade400)),
              child: Column(
                children: const [
                  Icon(Icons.qr_code_2, size: 160),
                  SizedBox(height: 8),
                  Text("যেকোনো UPI অ্যাপ দিয়ে স্ক্যান করে ১৯৯ টাকা পাঠান", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Text("UPI ID: sanatdas@upi (ডেমো)", style: TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: utrCtrl,
              decoration: const InputDecoration(labelText: "পেমেন্টের UTR / Transaction ID লিখুন", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
                child: const Text("পেমেন্ট ভেরিফিকেশনের জন্য পাঠান", style: TextStyle(color: Colors.white)),
                onPressed: () async {
                  if (utrCtrl.text.isNotEmpty) {
                    await http.post(
                      Uri.parse('$firebaseUrl/payment_requests.json'),
                      body: jsonEncode({
                        'userName': userName,
                        'phone': phone,
                        'utr': utrCtrl.text.trim(),
                        'date': DateTime.now().toString(),
                      }),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("অনুরোধ পাঠানো হয়েছে! অ্যাডমিন চালু করে দেবে।")));
                    Navigator.pop(context);
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class StudyNotesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> notes;
  const StudyNotesScreen({required this.notes});

  void openPdf(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("পিডিএফ নোটস ও মেটেরিয়াল"), backgroundColor: const Color(0xFFD32F2F)),
      body: notes.isEmpty
          ? const Center(child: Text("কোনো নোটস নেই!"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notes.length,
              itemBuilder: (ctx, i) {
                var n = notes[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.picture_as_pdf, color: Colors.white)),
                    title: Text(n['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(n['subtitle'] ?? ''),
                    trailing: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
                      icon: const Icon(Icons.download, size: 16, color: Colors.white),
                      label: const Text("PDF", style: TextStyle(color: Colors.white)),
                      onPressed: () => openPdf(n['url'] ?? ''),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class LiveClassesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> classes;
  const LiveClassesScreen({required this.classes});

  void openYouTube(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ডেইলি লাইভ ক্লাস"), backgroundColor: const Color(0xFFD32F2F)),
      body: classes.isEmpty
          ? const Center(child: Text("আজকের কোনো লাইভ ক্লাস নেই!"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: classes.length,
              itemBuilder: (ctx, i) {
                var c = classes[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.play_arrow, color: Colors.white)),
                    title: Text(c['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(c['subtitle'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.open_in_new, color: Colors.red),
                      onPressed: () => openYouTube(c['url'] ?? ''),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class JobAlertsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> jobs;
  const JobAlertsScreen({required this.jobs});

  void openJob(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("চাকরির খবর ও বিজ্ঞপ্তি"), backgroundColor: const Color(0xFFD32F2F)),
      body: jobs.isEmpty
          ? const Center(child: Text("কোনো চাকরির বিজ্ঞপ্তি নেই!"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: jobs.length,
              itemBuilder: (ctx, i) {
                var j = jobs[i];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.work, color: Colors.white)),
                    title: Text(j['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(j['subtitle'] ?? ''),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      child: const Text("বিজ্ঞপ্তি", style: TextStyle(color: Colors.white, fontSize: 11)),
                      onPressed: () => openJob(j['url'] ?? ''),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class LeaderboardScreen extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  const LeaderboardScreen({required this.users});

  @override
  Widget build(BuildContext context) {
    List sorted = List.from(users);
    sorted.sort((a, b) => (b['score'] ?? 0).compareTo(a['score'] ?? 0));

    return Scaffold(
      appBar: AppBar(title: const Text("স্টেট লিডারবোর্ড ও র‍্যাঙ্কিং"), backgroundColor: const Color(0xFFD32F2F)),
      body: sorted.isEmpty
          ? const Center(child: Text("কোনো তথ্য নেই!"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: sorted.length,
              itemBuilder: (ctx, i) {
                var u = sorted[i];
                Color badgeColor = Colors.grey;
                if (i == 0) badgeColor = Colors.amber;
                if (i == 1) badgeColor = Colors.blueGrey;
                if (i == 2) badgeColor = Colors.brown;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: badgeColor,
                      child: Text("${i + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("টার্গেট: ${u['exam']} | Roll #${u['roll']}"),
                    trailing: Text("${u['score'] ?? 0} Pts", style: const TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                );
              },
            ),
    );
  }
}
