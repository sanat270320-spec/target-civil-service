import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==========================================
// ১. গ্লোবাল কনফিগারেশন ও সুপার অ্যাডমিন সেটিংস
// ==========================================
class AppConfig {
  static const String appName = "টার্গেট সিভিল সার্ভিস";
  static const String watermarkText = "TARGET CIVIL SERVICE";

  // সুপার অ্যাডমিন ডিটেইলস
  static const String adminPhone = "6295411997";
  static const String adminEmail = "sanatd214@gmail.com";
  static const String defaultMasterPin = "123456789"; // ১ থেকে ৯ পর্যন্ত পিন

  // ডিফল্ট পেমেন্ট কিউআর কোড
  static const String defaultQrUrl =
      "https://dummyimage.com/600x600/000/fff&text=PhonePe+QR+Code";
}

// ==========================================
// ২. মেইন এন্ট্রি ও স্প্ল্যাশ স্ক্রিন
// ==========================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // স্ক্রিনশট ও স্ক্রিন রেকর্ডিং সম্পূর্ণ ব্লক (Anti-Piracy)
  try {
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  } catch (e) {
    debugPrint("Security Flag Error: $e");
  }

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
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('user_phone');
    final isAdmin = prefs.getBool('is_admin') ?? false;

    if (!mounted) return;

    if (isAdmin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
      );
    } else if (phone != null && phone.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 80, color: Colors.white),
            SizedBox(height: 16),
            Text(
              AppConfig.appName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "লক্ষ্য এবার সিভিল সার্ভিস",
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ৩. ওটিপি-বিহীন রেজিস্ট্রেশন ও অ্যাডমিন পিন ভেরিফিকেশন
// ==========================================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();

  String _selectedState = 'West Bengal';
  final List<String> _states = [
    'West Bengal',
    'Tripura',
    'Assam',
    'Bihar',
    'Jharkhand',
    'Odisha',
    'Delhi',
    'Other'
  ];

  // সুপার অ্যাডমিন পিন ডায়ালগ
  void _showAdminPinDialog() {
    final TextEditingController pinController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text("অ্যাডমিন যাচাইকরণ", style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "সুপার অ্যাডমিন প্যানেলে প্রবেশ করতে আপনার সিক্রেট মাস্টার পিন দিন:",
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 9,
              decoration: const InputDecoration(
                hintText: "৯ সংখ্যার পিন লিখুন",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("বাতিল"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
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
                  const SnackBar(
                    content: Text("ভুল পিন! পুনরায় চেষ্টা করুন।"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text("প্রবেশ করুন", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleContinue() {
    if (!_formKey.currentState!.validate()) return;

    final inputPhone = _phoneController.text.trim();
    final inputEmail = _emailController.text.trim().toLowerCase();

    // সুপার অ্যাডমিন ডিটেকশন
    if (inputPhone == AppConfig.adminPhone || inputEmail == AppConfig.adminEmail) {
      _showAdminPinDialog();
      return;
    }

    // স্টুডেন্টদের টার্গেট এগজাম সিলেকশন স্ক্রিনে পাঠানো
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TargetExamScreen(
          name: _nameController.text.trim(),
          phone: inputPhone,
          email: inputEmail,
          state: _selectedState,
          referralCode: _referralController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school, size: 54, color: Colors.deepPurple),
                  ),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    AppConfig.appName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    "সহজেই অ্যাকাউন্ট তৈরি করুন বা প্রবেশ করুন",
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ),
                const SizedBox(height: 28),

                const Text("আপনার পুরো নাম", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: "উদাঃ সনৎ কুমার দাস",
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? "নাম লিখুন" : null,
                ),
                const SizedBox(height: 14),

                const Text("মোবাইল নম্বর", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: "১০ সংখ্যার মোবাইল নম্বর",
                    prefixIcon: const Icon(Icons.phone_android_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length != 10) {
                      return "সঠিক ১০ সংখ্যার নম্বর দিন";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                const Text("জিমেইল / ইমেইল আইডি", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "example@gmail.com",
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) => v == null || !v.contains('@') ? "সঠিক ইমেইল দিন" : null,
                ),
                const SizedBox(height: 14),

                const Text("আপনার রাজ্য নির্বাচন করুন", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedState,
                  items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) => setState(() => _selectedState = val!),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),

                const Text("রেফারেল কোড (যদি থাকে)", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _referralController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: "উদাঃ TCS50 (ঐচ্ছিক - ₹১০ ছাড়)",
                    prefixIcon: const Icon(Icons.card_giftcard_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _handleContinue,
                    child: const Text(
                      "এগিয়ে যান ➔",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// ৪. টার্গেট চাকরি নির্বাচন (সর্বোচ্চ ৩টি নির্বাচন)
// ==========================================
class TargetExamScreen extends StatefulWidget {
  final String name;
  final String phone;
  final String email;
  final String state;
  final String referralCode;

  const TargetExamScreen({
    super.key,
    required this.name,
    required this.phone,
    required this.email,
    required this.state,
    required this.referralCode,
  });

  @override
  State<TargetExamScreen> createState() => _TargetExamScreenState();
}

class _TargetExamScreenState extends State<TargetExamScreen> {
  final List<String> _availableExams = [
    'WBCS (Exe / All Groups)',
    'RRB NTPC & Group D',
    'WBP & KP Police (SI/Constable)',
    'SSC (CGL, CHSL, MTS, GD)',
    'WBPSC (Clerkship, Food SI, Misc)',
    'Banking (IBPS, SBI PO & Clerk)',
    'Primary & Upper Primary TET',
    'All Competitive Exams',
  ];

  final Set<String> _selectedExams = {};

  void _toggleExam(String exam) {
    setState(() {
      if (_selectedExams.contains(exam)) {
        _selectedExams.remove(exam);
      } else {
        if (_selectedExams.length >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("সর্বোচ্চ ৩টি পরীক্ষা নির্বাচন করতে পারবেন!"),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          _selectedExams.add(exam);
        }
      }
    });
  }

  void _completeRegistration() async {
    if (_selectedExams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("অনুগ্রহ করে অন্তত ১টি পরীক্ষা বেছে নিন")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', widget.name);
    await prefs.setString('user_phone', widget.phone);
    await prefs.setString('user_email', widget.email);
    await prefs.setString('user_state', widget.state);
    await prefs.setStringList('target_exams', _selectedExams.toList());
    await prefs.setInt('wallet_coins', widget.referralCode.isNotEmpty ? 10 : 0);

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("টার্গেট পরীক্ষা নির্বাচন")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "নমস্কার, ${widget.name}!",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "আপনি কোন কোন চাকরির প্রস্তুতি নিচ্ছেন? (সর্বোচ্চ ৩টি নির্বাচন করুন)",
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: ListView.builder(
                itemCount: _availableExams.length,
                itemBuilder: (context, index) {
                  final exam = _availableExams[index];
                  final isSelected = _selectedExams.contains(exam);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.deepPurple.shade50 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
                        width: isSelected ? 1.8 : 1.0,
                      ),
                    ),
                    child: ListTile(
                      title: Text(
                        exam,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.deepPurple : Colors.black87,
                        ),
                      ),
                      trailing: Icon(
                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isSelected ? Colors.deepPurple : Colors.grey,
                      ),
                      onTap: () => _toggleExam(exam),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _completeRegistration,
                child: Text(
                  "পড়া শুরু করুন (${_selectedExams.length}/3 নির্বাচিত)",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ৫. হোম স্ক্রিন (Adda247 স্টাইল ইন্টারফেস)
// ==========================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("কোনো নতুন নোটিফিকেশন নেই")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ব্যানার স্লাইডার
            Container(
              margin: const EdgeInsets.all(16),
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Colors.deepPurple, Colors.indigo],
                ),
              ),
              child: const Center(
                child: Text(
                  "🎯 টার্গেট সিভিল সার্ভিস ব্যাচে ভর্তি চলছে!\nলাইভ ক্লাস + মক টেস্ট + নোটস",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // ৮টি প্রধান মেনু গ্রিড
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _menuItem(Icons.play_circle_fill, "লাইভ ক্লাস", Colors.redAccent),
                  _menuItem(Icons.quiz, "মক টেস্ট", Colors.orange),
                  _menuItem(Icons.picture_as_pdf, "পিডিএফ নোটস", Colors.blue),
                  _menuItem(Icons.download, "অফলাইন", Colors.green),
                  _menuItem(Icons.forum, "ডাউট ফোরাম", Colors.purple),
                  _menuItem(Icons.history_edu, "PYP হাব", Colors.teal),
                  _menuItem(Icons.bookmark, "বুকমার্ক", Colors.amber),
                  _menuItem(Icons.support_agent, "হেল্পলাইন", Colors.lightGreen),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ==========================================
// ৬. সুপার অ্যাডমিন ড্যাশবোর্ড স্ক্রিন
// ==========================================
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("সুপার অ্যাডমিন প্যানেল"),
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.security, size: 40, color: Colors.deepPurple),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("সুপার অ্যাডমিন লগইন সক্রিয়", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("নম্বর: 6295411997 | পিন: 123456789", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    leading: Icon(Icons.people, color: Colors.blue),
                    title: Text("রেজিস্টার্ড স্টুডেন্ট লিস্ট"),
                    subtitle: Text("রোল নম্বর, ফোন ও রাজ্য ট্র্যাকিং"),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.payment, color: Colors.green),
                    title: Text("পেমেন্ট ও ইউটিআর ভেরিফিকেশন"),
                    subtitle: Text("লাইভ UTR অ্যাপ্রুভাল"),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.library_books, color: Colors.orange),
                    title: Text("ডাইনামিক বিষয় ও প্রশ্ন ব্যাংক"),
                    subtitle: Text("বিষয় তৈরি ও ১০০টি করে প্রশ্ন আপলোড"),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.notifications_active, color: Colors.red),
                    title: Text("পুশ নোটিফিকেশন ব্রডকাস্ট"),
                    subtitle: Text("এক ক্লিকে সবার ফোনে নোটিস পাঠানো"),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
