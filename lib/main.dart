import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyEduApp());
}

// গ্লোবাল স্টেট ম্যানেজমেন্ট (কোর্স, কয়েন ও অ্যালার্মের জন্য)
class AppState {
  static int userCoins = 25; // রেফারেল কয়েন ব্যালেন্স (১ কয়েন = ১ টাকা)
  static String userCity = 'Kolkata, West Bengal';
  static List<String> purchasedCourses = ['WBCS 2026 Foundation Batch'];
  static List<Map<String, String>> adminNotifications = [
    {'title': 'WBCS লাইভ ক্লাস শুরু', 'msg': 'আজ সন্ধ্যা ৭টায় ইতিহাস লাইভ ক্লাস শুরু হবে।'},
  ];
  static List<Map<String, dynamic>> alarms = [
    {'id': 1, 'time': '06:00 AM', 'title': 'সকাল ৬:০০ - কারেন্ট অ্যাফেয়ার্স', 'active': true},
    {'id': 2, 'time': '09:30 AM', 'title': 'সকাল ৯:৩০ - অঙ্ক প্র্যাকটিস', 'active': true},
    {'id': 3, 'time': '08:00 PM', 'title': 'রাত ৮:০০ - ফুল মক টেস্ট', 'active': true},
  ];
}

class MyEduApp extends StatefulWidget {
  const MyEduApp({super.key});

  @override
  State<MyEduApp> createState() => _MyEduAppState();
}

class _MyEduAppState extends State<MyEduApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Target Civil Service',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFD32F2F),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFD32F2F), foregroundColor: Colors.white),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFD32F2F),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF212121), foregroundColor: Colors.white),
      ),
      home: MainNavigationHolder(
        onToggleTheme: toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class MainNavigationHolder extends StatefulWidget {
  final Function(bool) onToggleTheme;
  final bool isDarkMode;

  const MainNavigationHolder({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<MainNavigationHolder> createState() => _MainNavigationHolderState();
}

class _MainNavigationHolderState extends State<MainNavigationHolder> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // অ্যাপ খোলার সাথে সাথে পারমিশন নিশ্চিতকরণ ডায়ালগ
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkMandatoryPermissions());
  }

  void _checkMandatoryPermissions() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('অনুমতি নিশ্চিতকরণ (Permissions)'),
        content: const Text(
          'অ্যাপটি সঠিকভাবে চালানোর জন্য:\n\n'
          '১. লোকেশন অনুমতি (লাইভ জেলা ট্র্যাকিংয়ের জন্য)\n'
          '২. ক্যামেরা অনুমতি (প্রোফাইল ছবি আপলোডের জন্য)\n'
          '৩. নোটিফিকেশন অনুমতি (ক্লাসের আপডেট ও অ্যালার্মের জন্য চালু রাখা বাধ্যতামূলক)',
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('সমস্ত পারমিশন সক্রিয় করা হয়েছে!')),
              );
            },
            child: const Text('Allow All (অনুমতি দিন)', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeScreenContent(),
      const MyOrdersScreen(),
      const JobAlertsScreen(),
      const StoreScreenContent(),
    ];

    return Scaffold(
      drawer: AppSideDrawer(
        isDarkMode: widget.isDarkMode,
        onToggleTheme: widget.onToggleTheme,
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFD32F2F),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'My Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Job Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Store'),
        ],
      ),
    );
  }
}

// ১. মূল হোম স্ক্রিন
class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  final PageController _bannerController = PageController();
  int _currentBannerPage = 0;
  Timer? _bannerTimer;

  // প্রোফাইল ৫ সেকেন্ড চেপে ধরে রাখার জন্য টাইমার
  Timer? _adminSecretHoldTimer;

  final List<String> _banners = [
    'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800&q=80',
    'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800&q=80',
    'https://images.unsplash.com/photo-1497633762265-9d179a990aa6?w=800&q=80',
  ];

  final List<String> _examCountdowns = [
    '⏳ WBCS প্রিলিমস বাকি: ৪৫ দিন',
    '⏳ কলকাতা পুলিশ কনস্টেবল বাকি: ২০ দিন',
    '⏳ WBPSC ক্লার্কশিপ পরীক্ষা বাকি: ৩৫ দিন',
  ];
  int _countdownIndex = 0;
  Timer? _countdownTimer;
  bool _showCountdown = true;

  @override
  void initState() {
    super.initState();
    // ব্যানার প্রতি ৩ সেকেন্ডে নিজে নিজেই ঘুরবে
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentBannerPage < _banners.length - 1) {
        _currentBannerPage++;
      } else {
        _currentBannerPage = 0;
      }
      if (_bannerController.hasClients) {
        _bannerController.animateToPage(
          _currentBannerPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _countdownIndex = (_countdownIndex + 1) % _examCountdowns.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _countdownTimer?.cancel();
    _bannerController.dispose();
    _adminSecretHoldTimer?.cancel();
    super.dispose();
  }

  // ৫ সেকেন্ড চেপে ধরে থাকার লজিক
  void _startAdminHoldTimer() {
    _adminSecretHoldTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('অ্যাডমিন অ্যাক্সেস নিশ্চিত হয়েছে! ড্যাশবোর্ড খোলা হচ্ছে...'),
            backgroundColor: Colors.indigo,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      }
    });
  }

  void _cancelAdminHoldTimer() {
    _adminSecretHoldTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // টপ হেডার
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${AppState.userCity} ▾',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_active, color: Colors.white),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationInboxScreen()));
                      },
                    ),
                    // প্রোফাইল আইকন (৫ সেকেন্ড চেপে ধরে রাখলে অ্যাডমিন প্যানেল খুলবে)
                    GestureDetector(
                      onTapDown: (_) => _startAdminHoldTimer(),
                      onTapUp: (_) => _cancelAdminHoldTimer(),
                      onTapCancel: () => _cancelAdminHoldTimer(),
                      child: const Tooltip(
                        message: 'Hold 5 seconds for Admin',
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, color: Color(0xFFD32F2F), size: 22),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Search courses, batches, topics...', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_showCountdown)
                    Container(
                      color: Colors.amber.shade100,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _examCountdowns[_countdownIndex],
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.brown, fontSize: 13),
                            ),
                          ),
                          InkWell(
                            onTap: () => setState(() => _showCountdown = false),
                            child: const Icon(Icons.close, size: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  // ব্যানার স্লাইডার
                  Container(
                    margin: const EdgeInsets.all(12),
                    height: 155,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: PageView.builder(
                        controller: _bannerController,
                        itemCount: _banners.length,
                        itemBuilder: (context, index) {
                          return Image.network(_banners[index], fit: BoxFit.cover);
                        },
                      ),
                    ),
                  ),
                  // ১২টি স্টাডি গ্রিড আইকন
                  _buildStudyGrid(context),
                  const SizedBox(height: 16),
                  // পেইড কোর্স হাব
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1E3C72), Color(0xFF2A5298)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars, color: Colors.amber, size: 40),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('পেইড কোর্স হাব (Store)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('টার্গেট ব্যাচ ও এক্সক্লুসিভ ক্লাস দেখুন', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const StoreScreenContent()));
                          },
                          child: const Text('লিস্ট দেখুন', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ফ্রি ক্লাস ফিড (ইন-অ্যাপ ভিডিও লিঙ্ক)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Free Live Classes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('View all >', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const InAppVideoPlayerScreen(
                                  title: 'WBPSC স্পেশাল ফ্রি লাইভ ক্লাস',
                                  isPaid: false,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_circle_fill, size: 50, color: Colors.red),
                                  SizedBox(height: 6),
                                  Text('ফ্রি লাইভ ক্লাস দেখতে ক্লিক করুন', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyGrid(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {'title': 'Current Affairs', 'icon': Icons.newspaper, 'color': Colors.blue},
      {'title': 'Job Alerts', 'icon': Icons.notifications_active, 'color': Colors.orange, 'page': const JobAlertsScreen()},
      {'title': 'Quizzes', 'icon': Icons.quiz, 'color': Colors.indigo},
      {'title': 'PYP PDF', 'icon': Icons.picture_as_pdf, 'color': Colors.red},
      {'title': 'Articles', 'icon': Icons.article, 'color': Colors.teal},
      {'title': 'Free PDF', 'icon': Icons.file_copy, 'color': Colors.deepOrange},
      {'title': 'All India Mock', 'icon': Icons.assignment, 'color': Colors.purple},
      {'title': 'Subject-wise Quizzes', 'icon': Icons.menu_book, 'color': Colors.amber.shade800, 'page': const SubjectWiseQuizScreen()},
      {'title': 'Videos', 'icon': Icons.play_circle_fill, 'color': Colors.redAccent},
      {'title': 'Power Capsule', 'icon': Icons.bolt, 'color': Colors.amber},
      {'title': 'Free Live Classes', 'icon': Icons.live_tv, 'color': Colors.deepPurple},
      {'title': 'My Resources', 'icon': Icons.download_for_offline, 'color': Colors.blueGrey},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.85,
          crossAxisSpacing: 8,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return InkWell(
            onTap: () {
              if (item['page'] != null) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => item['page'] as Widget));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item['title']} সেকশনটি প্রস্তুত হচ্ছে...')),
                );
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: (item['color'] as Color).withOpacity(0.15),
                  child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 24),
                ),
                const SizedBox(height: 6),
                Text(
                  item['title'] as String,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ২. স্টোর স্ক্রিন (পেইড কোর্স ও কয়েন ডিসকাউন্ট)
class StoreScreenContent extends StatefulWidget {
  const StoreScreenContent({super.key});

  @override
  State<StoreScreenContent> createState() => _StoreScreenContentState();
}

class _StoreScreenContentState extends State<StoreScreenContent> {
  final List<Map<String, dynamic>> courses = [
    {'title': 'WBCS 2026 Foundation Batch', 'price': 1999, 'validity': '১ বছর', 'color': Colors.blue.shade800},
    {'title': 'কলকাতা পুলিশ কনস্টেবল স্পেশাল ব্যাচ', 'price': 999, 'validity': '৬ মাস', 'color': Colors.red.shade800},
    {'title': 'WBPSC ক্লার্কশিপ ক্র্যাশ কোর্স', 'price': 799, 'validity': '৪ মাস', 'color': Colors.green.shade800},
  ];

  void _buyCourse(Map<String, dynamic> c) {
    if (AppState.purchasedCourses.contains(c['title'])) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('আপনি ইতিমধ্যেই এই কোর্সটি কিনেছেন! "My Orders"-এ দেখুন।')),
      );
      return;
    }

    int discount = AppState.userCoins;
    int finalPrice = (c['price'] as int) - discount;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(c['title']),
        content: Text(
          'আসল মূল্য: ₹${c['price']}\n'
          'রেফারেল কয়েন ছাড়: -₹$discount ($discount Coins Used)\n'
          'মোট পরিশোধযোগ্য: ₹$finalPrice',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              setState(() {
                AppState.purchasedCourses.add(c['title']);
                AppState.userCoins = 0;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${c['title']} সফলভাবে কেনা হয়েছে! "My Orders"-এ যুক্ত হলো।')),
              );
            },
            child: const Text('পেমেন্ট কনফার্ম করুন', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('পেইড কোর্স স্টোর (Store)'), backgroundColor: const Color(0xFFD32F2F)),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final c = courses[index];
          final isBought = AppState.purchasedCourses.contains(c['title']);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: c['color'] as Color,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Center(
                    child: Text(
                      c['title'] as String,
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('মেয়াদ: ${c['validity']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          Text('কয়েন ছাড় উপলভ্য: ₹${AppState.userCoins}', style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('₹${c['price']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isBought ? Colors.grey : const Color(0xFFD32F2F),
                        ),
                        onPressed: () => _buyCourse(c),
                        child: Text(isBought ? 'Purchased' : 'Buy Now', style: const TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ৩. My Orders (কেনা কোর্সের পড়াশোনা ও ভিডিও অ্যাক্সেস)
class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders (আমার পেইড কোর্স)'), backgroundColor: const Color(0xFFD32F2F)),
      body: AppState.purchasedCourses.isEmpty
          ? const Center(child: Text('আপনি এখনও কোনো পেইড কোর্স কেনেননি।'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: AppState.purchasedCourses.length,
              itemBuilder: (context, index) {
                final course = AppState.purchasedCourses[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.verified, color: Colors.green, size: 36),
                    title: Text(course, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('পেমেন্ট সফল • আনলকড পেইড ক্লাস'),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InAppVideoPlayerScreen(
                              title: '$course - প্রিমিয়াম ক্লাস',
                              isPaid: true,
                            ),
                          ),
                        );
                      },
                      child: const Text('পড়ুন / ক্লাস', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ৪. ইন-অ্যাপ ভিডিও প্লেয়ার স্ক্রিন
class InAppVideoPlayerScreen extends StatelessWidget {
  final String title;
  final bool isPaid;

  const InAppVideoPlayerScreen({super.key, required this.title, required this.isPaid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: const Color(0xFFD32F2F)),
      body: Column(
        children: [
          Container(
            height: 220,
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_fill, color: Colors.red, size: 64),
                  SizedBox(height: 8),
                  Text('ইন-অ্যাপ লাইভ ভিডিও চলছে...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(isPaid ? '🔒 প্রিমিয়াম পেইড ক্লাস (সম্পূর্ণ আনলকড)' : '🌐 ফ্রি ইউটিউব ক্লাস'),
                const Divider(height: 30),
                const Text('ক্লাস নোটস ও স্টাডি পিডিএফ:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('পিডিএফ ডাউনলোড শুরু হয়েছে...')));
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download Class PDF'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ৫. রেফার অ্যান্ড আর্ন স্ক্রিন
class ReferEarnScreen extends StatefulWidget {
  const ReferEarnScreen({super.key});

  @override
  State<ReferEarnScreen> createState() => _ReferEarnScreenState();
}

class _ReferEarnScreenState extends State<ReferEarnScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Refer & Earn'), backgroundColor: const Color(0xFFD32F2F)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.amber.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.monetization_on, size: 50, color: Colors.amber),
                    const SizedBox(height: 6),
                    const Text('আপনার ওয়ালেট ব্যালেন্স', style: TextStyle(color: Colors.brown)),
                    Text('${AppState.userCoins} Coins', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text('${AppState.userCoins} কয়েন = ${AppState.userCoins} টাকার সমতুল্য (কোর্স ফি-তে ছাড়)', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('কীভাবে কাজ করে?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 6),
                    Text('• নতুন বন্ধু ডাউনলোড করলে সে পাবে ১০ টাকা।'),
                    Text('• আপনার অ্যাকাউন্টে জমা হবে ২৫ কয়েন (২৫ টাকা)।'),
                    Text('• পেইড কোর্স কেনার সময় কয়েন ব্যবহার করে সরাসরি ছাড় পাওয়া যাবে।'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Expanded(child: Text('https://targetcivilservice.com/ref/SANAT25', style: TextStyle(fontWeight: FontWeight.bold))),
                  Icon(Icons.copy, color: Colors.blue),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                icon: const Icon(Icons.share, color: Colors.white),
                label: const Text('বন্ধুদের হোয়াটসঅ্যাপে শেয়ার করুন', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  setState(() {
                    AppState.userCoins += 25;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('রেফারেল শেয়ার সম্পন্ন! অ্যাকাউন্টে ২৫ কয়েন যোগ করা হয়েছে।')),
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

// ৬. স্টাডি রুটিন অ্যালার্ম (১৫-২০টি অ্যালার্ম)
class StudyAlarmScreen extends StatefulWidget {
  const StudyAlarmScreen({super.key});

  @override
  State<StudyAlarmScreen> createState() => _StudyAlarmScreenState();
}

class _StudyAlarmScreenState extends State<StudyAlarmScreen> {
  void _addAlarm() async {
    if (AppState.alarms.length >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('আপনি সর্বোচ্চ ২০টি অ্যালার্ম যুক্ত করতে পারবেন।')));
      return;
    }
    final TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time != null && mounted) {
      final textController = TextEditingController();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('পড়ার বিষয় / রুটিন নাম'),
          content: TextField(controller: textController, decoration: const InputDecoration(hintText: 'যেমন: রিজনিং রিভিশন')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  AppState.alarms.add({
                    'id': AppState.alarms.length + 1,
                    'time': time.format(context),
                    'title': textController.text.isEmpty ? 'পড়ার সময় হয়েছে' : textController.text,
                    'active': true,
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('অ্যালার্ম সফলভাবে শিডিউল করা হয়েছে!')),
                );
              },
              child: const Text('সেভ'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('স্টাডি রুটিন অ্যালার্ম'), backgroundColor: const Color(0xFFD32F2F)),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: AppState.alarms.length,
        itemBuilder: (context, index) {
          final item = AppState.alarms[index];
          return Card(
            child: ListTile(
              leading: Icon(Icons.alarm, color: (item['active'] as bool) ? const Color(0xFFD32F2F) : Colors.grey),
              title: Text(item['time'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              subtitle: Text(item['title'] as String),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: item['active'] as bool,
                    activeColor: const Color(0xFFD32F2F),
                    onChanged: (val) => setState(() => item['active'] = val),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () => setState(() => AppState.alarms.removeAt(index)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD32F2F),
        onPressed: _addAlarm,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('নতুন অ্যালার্ম (${AppState.alarms.length}/20)', style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ৭. জব অ্যালার্ট স্ক্রিন (হোম ও ড্রয়ার উভয় জায়গা থেকেই এক্সেসযোগ্য)
class JobAlertsScreen extends StatelessWidget {
  const JobAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Alerts (চাকরির আপডেট)'), backgroundColor: const Color(0xFFD32F2F)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.work, color: Colors.orange, size: 32),
              title: Text('WBPSC Miscellaneous Recruitment', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('লাস্ট ডেট: ৩০ দিন বাকি • অফিশিয়াল বিজ্ঞপ্তি দেখুন'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.work, color: Colors.orange, size: 32),
              title: Text('Kolkata Police Constable & SI', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('নতুন ভ্যাকেন্সি আপডেট • আবেদন চলছে'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ৮. বিষয়ভিত্তিক কুইজ স্ক্রিন
class SubjectWiseQuizScreen extends StatelessWidget {
  const SubjectWiseQuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subjects = ['গণিত (Mathematics)', 'রিজনিং (Reasoning)', 'ইংরেজি (English)', 'সাধারণ জ্ঞান (General Studies)'];
    return Scaffold(
      appBar: AppBar(title: const Text('Subject-wise Quizzes'), backgroundColor: const Color(0xFFD32F2F)),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: subjects.length,
        itemBuilder: (context, i) => Card(
          child: ListTile(
            leading: const Icon(Icons.quiz, color: Colors.indigo),
            title: Text(subjects[i], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('১৫টি প্রশ্ন • সময়: ১৫ মিনিট • নেগেটিভ মার্কিং আছে'),
            trailing: const Icon(Icons.play_arrow),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${subjects[i]} কুইজ শুরু হচ্ছে...')));
            },
          ),
        ),
      ),
    );
  }
}

// ৯. নোটিফিকেশন ইনবক্স স্ক্রিন
class NotificationInboxScreen extends StatelessWidget {
  const NotificationInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('নোটিফিকেশন সেন্টার'), backgroundColor: const Color(0xFFD32F2F)),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: AppState.adminNotifications.length,
        itemBuilder: (context, i) {
          final n = AppState.adminNotifications[i];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_active, color: Colors.red),
              title: Text(n['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(n['msg']!),
            ),
          );
        },
      ),
    );
  }
}

// ১০. অ্যাডমিন কন্ট্রোল প্যানেল (৫ সেকেন্ড চেপে রাখলে সরাসরি খুলবে)
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _msgController = TextEditingController();

  final List<Map<String, String>> users = [
    {'name': 'অভিষেক রায়', 'city': 'কলকাতা, পশ্চিমবঙ্গ', 'time': '১০ মিনিট আগে', 'status': 'Online'},
    {'name': 'প্রিয়াঙ্কা সেন', 'city': 'শিলিগুড়ি, দার্জিলিং', 'time': '২৫ মিনিট আগে', 'status': 'Active'},
    {'name': 'রাহুল মণ্ডল', 'city': 'মালদা, পশ্চিমবঙ্গ', 'time': '১ ঘণ্টা আগে', 'status': 'Offline'},
  ];

  void _sendNotification() {
    if (_titleController.text.isEmpty || _msgController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('শিরোনাম ও মেসেজ লিখুন!')));
      return;
    }
    setState(() {
      AppState.adminNotifications.insert(0, {
        'title': _titleController.text,
        'msg': _msgController.text,
      });
    });
    _titleController.clear();
    _msgController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('পুশ নোটিফিকেশন সমস্ত ছাত্রদের অ্যাপে পাঠানো হয়েছে!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔒 অ্যাডমিন কন্ট্রোল প্যানেল'), backgroundColor: Colors.indigo.shade900),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('লাইভ ছাত্র অবস্থান ট্র্যাকার', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final u = users[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.person, color: Colors.white)),
                    title: Text(u['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('অবস্থান: ${u['city']}\nলাস্ট অ্যাক্টিভ: ${u['time']}'),
                    trailing: Text(u['status']!, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
            const SizedBox(height: 25),
            const Text('সবার ফোনে পুশ নোটিফিকেশন পাঠান', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'নোটিসের শিরোনাম (Title)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _msgController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'নোটিসের বিস্তারিত মেসেজ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade900),
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text('নোটিফিকেশন ব্রডকাস্ট করুন', style: TextStyle(color: Colors.white)),
                onPressed: _sendNotification,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ১১. সাইড ড্রয়ার / প্রোফাইল মেনু
class AppSideDrawer extends StatelessWidget {
  final bool isDarkMode;
  final Function(bool) onToggleTheme;

  const AppSideDrawer({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFD32F2F)),
            accountName: const Text('Sanat Kumar Das', style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text('Live Location: ${AppState.userCity}'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFFD32F2F), size: 36),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('My Profile'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text('My Orders (কেনা কোর্স)'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on, color: Colors.green),
            title: const Text('Refer & Earn'),
            subtitle: Text('${AppState.userCoins} কয়েন ব্যালেন্স'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferEarnScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.alarm),
            title: const Text('Study Planner (১৫-২০টি অ্যালার্ম)'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyAlarmScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.work),
            title: const Text('Job Alerts (চাকরির খবর)'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const JobAlertsScreen()));
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.brightness_6),
            title: const Text('Dark Mode (ডার্ক মোড)'),
            value: isDarkMode,
            onChanged: (val) => onToggleTheme(val),
          ),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Help & Support'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
