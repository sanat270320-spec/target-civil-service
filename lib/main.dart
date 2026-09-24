import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ==========================================
// ১. ফায়ারবেস ও অ্যাপ কনফিগারেশন
// ==========================================
class AppConfig {
  static const String appName = "টার্গেট সিভিল সার্ভিস";
  static const String adminPhone = "6295411997";
  static const String adminEmail = "sanatd214@gmail.com";
  static const String defaultMasterPin = "123456789";

  // আপনার লাইভ ফায়ারবেস ডাটাবেস URL
  static const String firebaseUrl =
      "https://target-civil-service-default-rtdb.firebaseio.com";
}

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
// ২. স্প্ল্যাশ স্ক্রিন
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
    final phone = prefs.getString('user_phone');

    if (!mounted) return;
    if (isAdmin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
      );
    } else if (phone != null && phone.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const StudentHomeScreen()),
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
// ৩. অথেনটিকেশন (ইউজার ও অ্যাডমিন)
// ==========================================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  void _showPinDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("সুপার অ্যাডমিন পিন"),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 9,
          decoration: const InputDecoration(hintText: "৯ সংখ্যার পিন লিখুন"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("বাতিল")),
          ElevatedButton(
            onPressed: () async {
              if (pinController.text.trim() == AppConfig.defaultMasterPin) {
                Navigator.pop(context);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_admin', true);
                await prefs.setString('user_phone', AppConfig.adminPhone);
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

  Future<void> _registerUser() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (phone == AppConfig.adminPhone) {
      _showPinDialog();
      return;
    }

    if (name.isEmpty || phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("সঠিক নাম এবং ১০ সংখ্যার ফোন নম্বর দিন")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // ফায়ারবেস ক্লাউডে ইউজার সেভ করা
      final url = Uri.parse("${AppConfig.firebaseUrl}/users/$phone.json");
      await http.put(
        url,
        body: jsonEncode({
          "name": name,
          "phone": phone,
          "createdAt": DateTime.now().toIso8601String(),
        }),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);
      await prefs.setString('user_phone', phone);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const StudentHomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ইন্টারনেট এরর: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Icon(Icons.school, size: 70, color: Colors.deepPurple),
            const SizedBox(height: 16),
            const Text(
              AppConfig.appName,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "পুরো নাম", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: "মোবাইল নম্বর",
                border: OutlineInputBorder(),
                counterText: "",
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                onPressed: _isLoading ? null : _registerUser,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("প্রবেশ করুন", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ৪. সুপার অ্যাডমিন ড্যাশবোর্ড (অনলাইন ক্লাউড কন্ট্রোল)
// ==========================================
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  // ফায়ারবেস থেকে সব বিষয় ও প্রশ্ন টেনে আনা
  Future<void> _fetchSubjects() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse("${AppConfig.firebaseUrl}/questions.json");
      final response = await http.get(url);

      if (response.statusCode == 200 && response.body != "null") {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<Map<String, dynamic>> loaded = [];

        data.forEach((key, value) {
          loaded.add({
            "id": key,
            "name": value["name"] ?? key,
            "duration": value["duration"] ?? 30,
            "questions": value["items"] ?? {},
          });
        });
        setState(() => _subjects = loaded);
      } else {
        setState(() => _subjects = []);
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // নতুন বিষয় তৈরি করে সরাসরি ফায়ারবেসে পুশ করা
  void _createNewSubjectDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("নতুন বিষয় তৈরি করুন"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "উদাঃ আধুনিক ভারত"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("বাতিল")),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context);
                final url = Uri.parse("${AppConfig.firebaseUrl}/questions/$name.json");
                await http.put(
                  url,
                  body: jsonEncode({"name": name, "duration": 30}),
                );
                _fetchSubjects();
              }
            },
            child: const Text("অনলাইনে সেভ করুন"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("সুপার অ্যাডমিন (ক্লাউড মোড)"),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchSubjects),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
              ? const Center(child: Text("কোনো বিষয় পাওয়া যায়নি। নতুন বিষয় তৈরি করুন।"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _subjects.length,
                  itemBuilder: (context, index) {
                    final sub = _subjects[index];
                    final qCount = (sub["questions"] as Map).length;
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.deepPurple,
                          child: Icon(Icons.folder, color: Colors.white),
                        ),
                        title: Text(sub["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("অনলাইন প্রশ্ন: $qCount টি | সময়: ${sub["duration"]} মিনিট"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminSubjectDetailScreen(subject: sub),
                            ),
                          );
                          _fetchSubjects();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

// ==========================================
// ৫. বিষয়ের ভেতরে প্রশ্ন যোগ স্ক্রিন (অ্যাডমিন)
// ==========================================
class AdminSubjectDetailScreen extends StatefulWidget {
  final Map<String, dynamic> subject;
  const AdminSubjectDetailScreen({super.key, required this.subject});

  @override
  State<AdminSubjectDetailScreen> createState() => _AdminSubjectDetailScreenState();
}

class _AdminSubjectDetailScreenState extends State<AdminSubjectDetailScreen> {
  void _addQuestionDialog() {
    final qCtrl = TextEditingController();
    final optA = TextEditingController();
    final optB = TextEditingController();
    final optC = TextEditingController();
    final optD = TextEditingController();
    int correct = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("অনলাইনে প্রশ্ন যোগ করুন"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: qCtrl, decoration: const InputDecoration(labelText: "প্রশ্ন")),
                TextField(controller: optA, decoration: const InputDecoration(labelText: "অপশন A")),
                TextField(controller: optB, decoration: const InputDecoration(labelText: "অপশন B")),
                TextField(controller: optC, decoration: const InputDecoration(labelText: "অপশন C")),
                TextField(controller: optD, decoration: const InputDecoration(labelText: "অপশন D")),
                const SizedBox(height: 10),
                DropdownButton<int>(
                  value: correct,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text("সঠিক উত্তর: A")),
                    DropdownMenuItem(value: 1, child: Text("সঠিক উত্তর: B")),
                    DropdownMenuItem(value: 2, child: Text("সঠিক উত্তর: C")),
                    DropdownMenuItem(value: 3, child: Text("সঠিক উত্তর: D")),
                  ],
                  onChanged: (v) => setDialogState(() => correct = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("বাতিল")),
            ElevatedButton(
              onPressed: () async {
                if (qCtrl.text.isNotEmpty && optA.text.isNotEmpty) {
                  Navigator.pop(context);
                  final subName = widget.subject["name"];
                  final url = Uri.parse("${AppConfig.firebaseUrl}/questions/$subName/items.json");

                  await http.post(
                    url,
                    body: jsonEncode({
                      "q": qCtrl.text.trim(),
                      "options": [optA.text.trim(), optB.text.trim(), optC.text.trim(), optD.text.trim()],
                      "answer": correct,
                    }),
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("প্রশ্ন সবার জন্য লাইভ সেভ হয়েছে!")),
                    );
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text("লাইভ সেভ করুন"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map questions = widget.subject["questions"] as Map;
    return Scaffold(
      appBar: AppBar(title: Text("${widget.subject["name"]} - প্রশ্ন")),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: _addQuestionDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: questions.isEmpty
          ? const Center(child: Text("কোনো প্রশ্ন নেই। + বাটনে চাপ দিয়ে যোগ করুন।"))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: questions.values.map((item) {
                return Card(
                  child: ListTile(
                    title: Text(item["q"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("সঠিক উত্তর: অপশন ${String.fromCharCode(65 + (item["answer"] as int))}"),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// ==========================================
// ৬. ছাত্রছাত্রীদের লাইভ হোম ও এক্সাম স্ক্রিন
// ==========================================
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  List<Map<String, dynamic>> _liveSubjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLiveSubjects();
  }

  Future<void> _loadLiveSubjects() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse("${AppConfig.firebaseUrl}/questions.json");
      final response = await http.get(url);

      if (response.statusCode == 200 && response.body != "null") {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<Map<String, dynamic>> list = [];
        data.forEach((k, v) {
          list.add({
            "name": v["name"] ?? k,
            "duration": v["duration"] ?? 30,
            "questions": v["items"] ?? {},
          });
        });
        setState(() => _liveSubjects = list);
      }
    } catch (e) {
      debugPrint("Load error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadLiveSubjects),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _liveSubjects.isEmpty
              ? const Center(child: Text("অ্যাডমিন এখনো কোনো বিষয় আপলোড করেনি।"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _liveSubjects.length,
                  itemBuilder: (context, index) {
                    final sub = _liveSubjects[index];
                    final qCount = (sub["questions"] as Map).length;
                    return Card(
                      elevation: 2,
                      child: ListTile(
                        leading: const Icon(Icons.quiz, color: Colors.deepPurple, size: 36),
                        title: Text(sub["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("মোট প্রশ্ন: $qCount টি | সময়: ${sub["duration"]} মিনিট"),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                          onPressed: qCount == 0
                              ? null
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("${sub["name"]} পরীক্ষা চালু হচ্ছে...")),
                                  );
                                },
                          child: const Text("টেস্ট দিন", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
