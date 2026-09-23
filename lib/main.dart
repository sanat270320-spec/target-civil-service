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

class TargetCivilServiceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Target Civil Service',
      theme: ThemeData(
        primaryColor: const Color(0xFFD32F2F),
        scaffoldBackgroundColor: const Color(0xFFF5F6F8),
        fontFamily: 'Roboto',
      ),
      home: AuthCheckScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthCheckScreen extends StatefulWidget {
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
    return isLoggedIn ? AddaRootScreen(userData: userData) : LoginFlowScreen();
  }
}

class LoginFlowScreen extends StatefulWidget {
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
  bool isLoading = false;

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ভুল ওটিপি! পুনরায় চেষ্টা করুন")));
    }
  }

  Future<void> completeRegistration() async {
    if (nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("আপনার সম্পূর্ণ নাম লিখুন")));
      return;
    }
    setState(() => isLoading = true);

    try {
      final userCountRes = await http.get(Uri.parse('$firebaseUrl/users.json?shallow=true'));
      int currentRoll = 1;
      if (userCountRes.statusCode == 200 && userCountRes.body != 'null') {
        Map<String, dynamic> allUsers = jsonDecode(userCountRes.body);
        currentRoll = allUsers.length + 1;
      }

      final profile = {
        'name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'exam': examCtrl.text.trim(),
        'roll': currentRoll,
        'image': imgCtrl.text.trim(),
        'score': 0,
        'registeredAt': DateTime.now().toIso8601String(),
      };

      await http.put(
        Uri.parse('$firebaseUrl/users/${phoneCtrl.text.trim()}.json'),
        body: jsonEncode(profile),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('u_name', profile['name'] as String);
      await prefs.setString('u_phone', profile['phone'] as String);
      await prefs.setString('u_exam', profile['exam'] as String);
      await prefs.setInt('u_roll', currentRoll);
      await prefs.setString('u_image', profile['image'] as String);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AddaRootScreen(userData: profile)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ইন্টারনেট সংযোগ পরীক্ষা করুন")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                step == 1 ? "লগইন করতে আপনার ফোন নম্বর দিন" : (step == 2 ? "আপনার স্ক্রিনে আসা ৪ সংখ্যার কোড লিখুন" : "আপনার বিবরণ পূরণ করুন"),
                style: const TextStyle(color: Colors.black54, fontSize: 13),
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
                    onPressed: isLoading ? null : completeRegistration,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("প্রবেশ করুন", style: TextStyle(color: Colors.white, fontSize: 16)),
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
  const AddaRootScreen({required this.userData});

  @override
  _AddaRootScreenState createState() => _AddaRootScreenState();
}

class _AddaRootScreenState extends State<AddaRootScreen> {
  int _selectedIndex = 0;
  final String firebaseUrl = "https://target-civil-service-default-rtdb.firebaseio.com";
  final String adminId = "WBCS";
  final String adminPass = "8436";

  List<Map<String, dynamic>> questions = [];
  List<Map<String, dynamic>> currentAffairs = [];
  List<Map<String, dynamic>> studyNotes = [];
  List<Map<String, dynamic>> liveClasses = [];
  List<Map<String, dynamic>> registeredUsers = [];
  List<Map<String, dynamic>> achievers = [];
  List<Map<String, dynamic>> jobAlerts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    try {
      final qRes = await http.get(Uri.parse('$firebaseUrl/questions.json'));
      final caRes = await http.get(Uri.parse('$firebaseUrl/current_affairs.json'));
      final snRes = await http.get(Uri.parse('$firebaseUrl/study_notes.json'));
      final lcRes = await http.get(Uri.parse('$firebaseUrl/live_classes.json'));
      final uRes = await http.get(Uri.parse('$firebaseUrl/users.json'));
      final acRes = await http.get(Uri.parse('$firebaseUrl/achievers.json'));
      final jobRes = await http.get(Uri.parse('$firebaseUrl/job_alerts.json'));

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
        currentAffairs = parseMap(caRes);
        studyNotes = parseMap(snRes);
        liveClasses = parseMap(lcRes);
        registeredUsers = parseMap(uRes);
        achievers = parseMap(acRes);
        jobAlerts = parseMap(jobRes);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
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
    const phone = "+916295411997";
    final url = Uri.parse("https://wa.me/$phone?text=নমস্কার, টার্গেট সিভিল সার্ভিস অ্যাপ সম্পর্কে জানতে চাই।");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // সিক্রেট অ্যাডমিন লগইন (৩ সেকেন্ড লং প্রেসে ওপেন হবে)
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

  // মাস্টার অ্যাডমিন কন্ট্রোল প্যানেল
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
                  Tab(text: "ছাত্র তালিকা (SMS)"),
                  Tab(text: "মক কুইজ কন্ট্রোল"),
                  Tab(text: "ইউটিউব ক্লাস"),
                  Tab(text: "পিডিএফ নোটস"),
                  Tab(text: "চাকরির বিজ্ঞপ্তি"),
                  Tab(text: "কৃতী শিক্ষার্থী"),
                  Tab(text: "কারেন্ট অ্যাফেয়ার্স"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _adminUserSection(),
                    _adminQuestionSection(),
                    _adminGenericSection("live_classes", liveClasses, "নতুন ইউটিউব ক্লাস যোগ করুন", "ক্লাসের নাম / বিষয়", "তারিখ / শিক্ষকের নাম", "YouTube লিংক"),
                    _adminGenericSection("study_notes", studyNotes, "নতুন পিডিএফ / নোটস যোগ করুন", "নোটসের বিষয়", "অধ্যায় / বিবরণ", "পিডিএফ ডাউনলোড লিংক (Drive/Web)"),
                    _adminGenericSection("job_alerts", jobAlerts, "নতুন চাকরির বিজ্ঞপ্তি যোগ করুন", "পদের নাম (যেমন: WBCS 2026)", "যোগ্যতা ও শেষ তারিখ", "বিজ্ঞপ্তি / আবেদন লিংক"),
                    _adminAchieverSection(),
                    _adminGenericSection("current_affairs", currentAffairs, "নতুন কারেন্ট অ্যাফেয়ার্স পোস্ট করুন", "শিরোনাম", "বিস্তারিত বিবরণ", "ছবির URL লিঙ্ক"),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // প্রশ্ন যোগ করার আলাদা সেকশন (বিকল্প ও সঠিক উত্তর সহ)
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
                      subtitle: Text("সঠিক উত্তর: বিকল্প ${(questions[i]['correctIndex'] ?? 0) + 1}"),
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
          label: const Text("নতুন মক টেস্ট প্রশ্ন যোগ করুন", style: TextStyle(color: Colors.white)),
          onPressed: _showAddQuestionDialog,
        )
      ],
    );
  }

  void _showAddQuestionDialog() {
    final q = TextEditingController(), o1 = TextEditingController(), o2 = TextEditingController(), o3 = TextEditingController(), o4 = TextEditingController(), exp = TextEditingController();
    int cIdx = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setF) => AlertDialog(
          title: const Text("নতুন মক কুইজ প্রশ্ন"),
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
                  decoration: const InputDecoration(labelText: "সঠিক বিকল্প কোনটি?"),
                ),
                TextField(controller: exp, decoration: const InputDecoration(labelText: "ব্যাখ্যা")),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (q.text.isNotEmpty && o1.text.isNotEmpty) {
                  pushCloudData("questions", {
                    'question': q.text.trim(),
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

  // যেকোনো সাধারণ সেকশন কন্ট্রোল করার উইজেট
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
          onPressed: () => _showAddGenericDialog(path, label1, label2, label3),
        )
      ],
    );
  }

  void _showAddGenericDialog(String path, String label1, String label2, String label3) {
    final t1 = TextEditingController();
    final t2 = TextEditingController();
    final t3 = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("নতুন তথ্য সংযোজন"),
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
  }

  Widget _adminAchieverSection() {
    return Column(
      children: [
        Expanded(
          child: achievers.isEmpty
              ? const Center(child: Text("কোনো তথ্য নেই!"))
              : ListView.builder(
                  itemCount: achievers.length,
                  itemBuilder: (ctx, i) => Card(
                    child: ListTile(
                      leading: CircleAvatar(backgroundImage: NetworkImage(achievers[i]['image'] ?? '')),
                      title: Text(achievers[i]['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("পদ: ${achievers[i]['job']} | রোল: #${achievers[i]['roll']}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => removeCloudData("achievers", achievers[i]['id']),
                      ),
                    ),
                  ),
                ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, minimumSize: const Size(double.infinity, 45)),
          icon: const Icon(Icons.emoji_events, color: Colors.white),
          label: const Text("সফল শিক্ষার্থী যোগ করুন", style: TextStyle(color: Colors.white)),
          onPressed: _showAddAchieverDialog,
        )
      ],
    );
  }

  void _showAddAchieverDialog() {
    final nCtrl = TextEditingController();
    final jCtrl = TextEditingController();
    final rCtrl = TextEditingController();
    final imgCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("সফল শিক্ষার্থীর বিবরণ"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nCtrl, decoration: const InputDecoration(labelText: "নাম")),
              TextField(controller: jCtrl, decoration: const InputDecoration(labelText: "যে চাকরি পেয়েছে (যেমন: WBCS Group A)")),
              TextField(controller: rCtrl, decoration: const InputDecoration(labelText: "রোল নম্বর")),
              TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: "ছবির URL লিঙ্ক")),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (nCtrl.text.isNotEmpty) {
                pushCloudData("achievers", {
                  'name': nCtrl.text.trim(),
                  'job': jCtrl.text.trim(),
                  'roll': rCtrl.text.trim(),
                  'image': imgCtrl.text.trim(),
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text("সংরক্ষণ করুন"),
          )
        ],
      ),
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
              Text("মোট রেজিস্টার্ড ছাত্র: ${registeredUsers.length}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
          child: registeredUsers.isEmpty
              ? const Center(child: Text("কোনো শিক্ষার্থী এখনও রেজিস্টার করেনি!"))
              : ListView.builder(
                  itemCount: registeredUsers.length,
                  itemBuilder: (ctx, i) {
                    var u = registeredUsers[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: const Color(0xFFD32F2F), child: Text("${u['roll'] ?? (i + 1)}", style: const TextStyle(color: Colors.white))),
                        title: Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("ফোন: +91 ${u['phone']}\nটার্গেট: ${u['exam']}"),
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
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => LoginFlowScreen()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD32F2F)))
          : IndexedStack(
              index: _selectedIndex,
              children: [
                _buildHomeDashboard(),
                LiveClassesScreen(classes: liveClasses),
                QuizPlayScreen(questions: questions, userPhone: widget.userData['phone']),
                StudyNotesScreen(notes: studyNotes),
                LeaderboardScreen(users: registeredUsers),
                JobAlertsScreen(jobs: jobAlerts),
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
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: "Rank"),
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
                // ৩ সেকেন্ড চেপে ধরলে অ্যাডমিন ওপেন হবে
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
              IconButton(icon: const Icon(Icons.notifications_active, color: Colors.white), onPressed: () => setState(() => _selectedIndex = 5)),
              IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: fetchAllData),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(16),
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
                          ],
                        ),
                      ),
                      const Icon(Icons.military_tech, size: 50, color: Colors.white),
                    ],
                  ),
                ),

                if (achievers.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                    child: Text("কৃতী শিক্ষার্থী (HALL OF FAME)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ),
                  Container(
                    height: 125,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: achievers.length,
                      itemBuilder: (ctx, i) {
                        var ach = achievers[i];
                        return Container(
                          width: 210,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.amber.shade50, Colors.white]),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundImage: (ach['image'] ?? '').toString().isNotEmpty ? NetworkImage(ach['image']) : null,
                                child: (ach['image'] ?? '').toString().isEmpty ? const Icon(Icons.person) : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ach['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1),
                                    Text(ach['job'] ?? '', style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1),
                                    Text("Roll #${ach['roll']}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14.0),
                  child: Text("STUDY MATERIAL & EXAM ZONE", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
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
                    _buildIconItem(Icons.work, "চাকরির খবর", Colors.teal, () => setState(() => _selectedIndex = 5)),
                    _buildIconItem(Icons.leaderboard, "র‌্যাঙ্ক বোর্ড", Colors.indigo, () => setState(() => _selectedIndex = 4)),
                    _buildIconItem(Icons.person, "প্রোফাইল", Colors.blue, () => setState(() => _selectedIndex = 6)),
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
          ListTile(leading: const Icon(Icons.format_list_numbered), title: const Text("অফিসিয়াল রোল নম্বর"), subtitle: Text("Roll #${widget.userData['roll']}")),
          const Divider(),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text("লগআউট", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)), onTap: logout),
        ],
      ),
    );
  }
}

// পিডিএফ স্টাডি মেটেরিয়াল স্ক্রিন (ডাউনলোড সহ)
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
      appBar: AppBar(title: const Text("পিডিএফ নোটস ও স্টাডি মেটেরিয়াল"), backgroundColor: const Color(0xFFD32F2F)),
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

// লাইভ ক্লাস স্ক্রিন
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

// চাকরির বিজ্ঞপ্তি স্ক্রিন (Job Alerts)
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
          ? const Center(child: Text("বর্তমানে কোনো নতুন চাকরির বিজ্ঞপ্তি নেই!"))
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
                      child: const Text("Apply / Notice", style: TextStyle(color: Colors.white, fontSize: 11)),
                      onPressed: () => openJob(j['url'] ?? ''),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// লিডারবোর্ড ও স্টেট র‍্যাঙ্কিং স্ক্রিন
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

// টাইমার ও নেগেটিভ মার্কিং সহ ফুল এক্সাম মোড
class QuizPlayScreen extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final String userPhone;
  const QuizPlayScreen({required this.questions, required this.userPhone});

  @override
  _QuizPlayScreenState createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  int currentIdx = 0;
  double score = 0.0;
  int? selected;
  int remainingSeconds = 600;
  Timer? timer;

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
    await http.patch(
      Uri.parse("https://target-civil-service-default-rtdb.firebaseio.com/users/${widget.userPhone}.json"),
      body: jsonEncode({'score': score.toInt()}),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("মক টেস্ট রিপোর্ট"),
        content: Text("মোট স্কোর: ${score.toStringAsFixed(2)} / ${widget.questions.length}\n(ভুল উত্তরে -০.২৫ কাটা হয়েছে)"),
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
        body: const Center(child: Text("কোনো প্রশ্ন যোগ করা হয়নি!")),
      );
    }
    var q = widget.questions[currentIdx];
    List options = q['options'] ?? [];

    int minutes = remainingSeconds ~/ 60;
    int seconds = remainingSeconds % 60;

    return Scaffold(
      appBar: AppBar(
        title: Text("সময় বাকি: ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}"),
        backgroundColor: const Color(0xFFD32F2F),
        actions: [
          TextButton(onPressed: submitExam, child: const Text("জমা দিন", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("প্রশ্ন ${currentIdx + 1} / ${widget.questions.length} (ভুল উত্তরে: -০.২৫)", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(q['question'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),
            ...List.generate(options.length, (i) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: selected != null ? (i == q['correctIndex'] ? Colors.green.shade100 : (selected == i ? Colors.red.shade100 : Colors.white)) : Colors.white,
                ),
                onPressed: selected == null ? () {
                  setState(() {
                    selected = i;
                    if (i == q['correctIndex']) {
                      score += 1.0;
                    } else {
                      score -= 0.25;
                    }
                  });
                } : null,
                child: Text("${options[i]}"),
              ),
            )),
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
