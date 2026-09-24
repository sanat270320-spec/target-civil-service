import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String appName = "টার্গেট সিভিল সার্ভিস";
  static const String watermarkText = "TARGET CIVIL SERVICE";
  static const String adminPhone = "6295411997";
  static const String adminEmail = "sanatd214@gmail.com";
  static const String defaultMasterPin = "123456789";
  static const String defaultQrUrl = "https://dummyimage.com/600x600/000/fff&text=PhonePe+QR+Code";
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
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
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

  void _showAdminPinDialog() {
    final TextEditingController pinController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("অ্যাডমিন যাচাইকরণ"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("মাস্টার পিন দিন (১ থেকে ৯):"),
            const SizedBox(height: 10),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 9,
              decoration: const InputDecoration(hintText: "৯ সংখ্যার পিন"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("বাতিল"),
          ),
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
            child: const Text("প্রবেশ"),
          ),
        ],
      ),
    );
  }

  void _handleContinue() {
    if (!_formKey.currentState!.validate()) return;

    final inputPhone = _phoneController.text.trim();
    final inputEmail = _emailController.text.trim().toLowerCase();

    if (inputPhone == AppConfig.adminPhone || inputEmail == AppConfig.adminEmail) {
      _showAdminPinDialog();
      return;
    }

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
      appBar: AppBar(title: const Text("রেজিস্ট্রেশন")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "পুরো নাম"),
                validator: (v) => v == null || v.isEmpty ? "নাম লিখুন" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(labelText: "মোবাইল নম্বর", counterText: ""),
                validator: (v) => v == null || v.length != 10 ? "১০ সংখ্যার নম্বর দিন" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "ইমেইল"),
                validator: (v) => v == null || !v.contains('@') ? "সঠিক ইমেইল দিন" : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedState,
                items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => _selectedState = val!),
                decoration: const InputDecoration(labelText: "রাজ্য"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _referralController,
                decoration: const InputDecoration(labelText: "রেফারেল কোড (ঐচ্ছিক)"),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                  onPressed: _handleContinue,
                  child: const Text("এগিয়ে যান", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    'WBCS',
    'RRB NTPC & Group D',
    'WBP & KP Police',
    'SSC CGL & MTS',
    'Primary TET',
  ];

  final Set<String> _selectedExams = {};

  void _completeRegistration() async {
    if (_selectedExams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("অন্তত ১টি পরীক্ষা বেছে নিন")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', widget.name);
    await prefs.setString('user_phone', widget.phone);
    await prefs.setString('user_email', widget.email);
    await prefs.setString('user_state', widget.state);
    await prefs.setStringList('target_exams', _selectedExams.toList());

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
      appBar: AppBar(title: const Text("টার্গেট পরীক্ষা")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _availableExams.length,
                itemBuilder: (context, index) {
                  final exam = _availableExams[index];
                  final isSelected = _selectedExams.contains(exam);
                  return CheckboxListTile(
                    title: Text(exam),
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          if (_selectedExams.length < 3) _selectedExams.add(exam);
                        } else {
                          _selectedExams.remove(exam);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                onPressed: _completeRegistration,
                child: const Text("শুরু করুন", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConfig.appName)),
      body: const Center(
        child: Text(
          "টার্গেট সিভিল সার্ভিস হোম স্ক্রিন",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("সুপার অ্যাডমিন প্যানেল"),
        backgroundColor: Colors.black87,
      ),
      body: const Center(
        child: Text("সুপার অ্যাডমিন লগইন সফল!"),
      ),
    );
  }
}
