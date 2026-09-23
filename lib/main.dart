import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyEduApp());
}

// গ্লোবাল ডাটাবেস স্টেট
class AppState {
  static int userCoins = 25; // ওয়ালেট কয়েন
  static String userName = 'সনৎ কুমার দাস';
  static String userEmail = 'sanat@example.com';
  static String userTarget = 'WBCS, KP SI & Constable';
  static String userCity = 'কলকাতা, পশ্চিমবঙ্গ';
  static List<String> purchasedCourses = []; // কেনা কোর্স ডিফল্টভাবে খালি
  static List<Map<String, String>> adminNotifications = [
    {'title': 'স্বাগতম!', 'msg': 'টার্গেট সিভিল সার্ভিস অ্যাপে আপনাকে স্বাগতম।'},
  ];
  static List<Map<String, dynamic>> alarms = [
    {'id': 1, 'time': '06:00 AM', 'title': 'সকাল ৬:০০ - কারেন্ট অ্যাফেয়ার্স', 'active': true},
    {'id': 2, 'time': '09:30 AM', 'title': 'সকাল ৯:৩০ - অঙ্ক প্র্যাকটিস', 'active': true},
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

// হোম স্ক্রিন
class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  final PageController _bannerController = PageController();
  int _currentBannerPage = 0;
  Timer? _bannerTimer;

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
    super.dispose();
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
                    // প্রোফাইল আইকনে চাপ দিলে সরাসরি ড্রয়ার মেনু খুলবে
                    Builder(
                      builder: (context) => IconButton(
                        icon: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, color: Color(0xFFD32F2F), size: 20),
                        ),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
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
                  _buildStudyGrid(context),
                  const SizedBox(height: 16),
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

// স্টোর স্ক্রিন
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
          'কোর্সের মূল্য: ₹${c['price']}\n'
          'রেফারেল কয়েন ছাড়: -₹$discount ($discount Coins Used)\n'
          'মোট প্রদান করতে হবে: ₹$finalPrice',
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
                SnackBar(content: Text('${c['title']} সফলভাবে কেনা হয়েছে! "My Orders"-এ যুক্ত করা হলো।')),
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
                        child: Text(isBought ? 'Already Purchased' : 'Buy Now', style: const TextStyle(color: Colors.white)),
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

// My Orders
class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders (আমার কোর্স)'), backgroundColor: const Color(0xFFD32F2F)),
      body: AppState.purchasedCourses.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'আপনি এখনও কোনো কোর্স কেনেননি।\nস্টোর (Store) থেকে কোর্স ক্রয় করতে পারবেন।',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            )
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
                      child: const Text('পড়ুন', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ইন-অ্যাপ ভিডিও প্লেয়ার
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
                  Text('ভিডিও চলছে...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                Text(isPaid ? '🔒 প্রিমিয়াম পেইড ক্লাস (আনলকড)' : '🌐 ফ্রি ইউটিউব ক্লাস'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// মাই প্রোফাইল ডিটেইল পেজ
class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile (প্রোফাইল বিবরণ)'), backgroundColor: const Color(0xFFD32F2F)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Center(
              child: CircleAvatar(
                radius: 45,
                backgroundColor: Color(0xFFD32F2F),
                child: Icon(Icons.person, color: Colors.white, size: 50),
              ),
            ),
            const SizedBox(height: 12),
            Text(AppState.userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(AppState.userEmail, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_city, color: Colors.indigo),
                title: const Text('বর্তমান অবস্থান / জেলা'),
                subtitle: Text(AppState.userCity),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.military_tech, color: Colors.orange),
                title: const Text('টার্গেট পরীক্ষা'),
                subtitle: Text(AppState.userTarget),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.monetization_on, color: Colors.green),
                title: const Text('ওয়ালেট কয়েন ব্যালেন্স'),
                subtitle: Text('${AppState.userCoins} Coins (₹${AppState.userCoins})'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.verified, color: Colors.blue),
                title: const Text('অ্যাক্টিভ কোর্স সংখ্যা'),
                subtitle: Text('${AppState.purchasedCourses.length} টি কোর্স'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// রেফার অ্যান্ড আর্ন
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
                    Text('${AppState.userCoins} কয়েন = ${AppState.userCoins} টাকার সমতুল্য', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                    const SnackBar(content: Text('রেফারেল বোনাস ২৫ কয়েন যোগ হয়েছে!')),
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

// স্টাডি অ্যালার্ম পেজ
class StudyAlarmScreen extends StatefulWidget {
  const StudyAlarmScreen({super.key});

  @override
  State<StudyAlarmScreen> createState() => _StudyAlarmScreenState();
}

class _StudyAlarmScreenState extends State<StudyAlarmScreen> {
  void _addAlarm() async {
    if (AppState.alarms.length >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('সর্বোচ্চ ২০টি অ্যালার্ম যুক্ত করা যাবে।')));
      return;
    }
    final TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time != null && mounted) {
      final textController = TextEditingController();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('পড়ার বিষয় / রুটিন নাম'),
          content: TextField(controller: textController, decoration: const InputDecoration(hintText: 'যেমন: রিভিশন')),
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
              trailing: Switch(
                value: item['active'] as bool,
                activeColor: const Color(0xFFD32F2F),
                onChanged: (val) => setState(() => item['active'] = val),
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

// জব অ্যালার্ট
class JobAlertsScreen extends StatelessWidget {
  const JobAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Alerts (চাকরির খবর)'), backgroundColor: const Color(0xFFD32F2F)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.work, color: Colors.orange, size: 32),
              title: Text('WBPSC Miscellaneous Recruitment', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('লাস্ট ডেট: ৩০ দিন বাকি • বিজ্ঞপ্তি দেখুন'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.work, color: Colors.orange, size: 32),
              title: Text('Kolkata Police Constable & SI', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('নতুন ভ্যাকেন্সি আপডেট • আবেদন চলছে'),
            ),
          ),
        ],
      ),
    );
  }
}

// বিষয়ভিত্তিক কুইজ
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
            trailing: const Icon(Icons.play_arrow),
          ),
        ),
      ),
    );
  }
}

// নোটিফিকেশন সেন্টার
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

// হেল্প অ্যান্ড সাপোর্ট পেজ
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support'), backgroundColor: const Color(0xFFD32F2F)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Card(
              child: ListTile(
                leading: Icon(Icons.support_agent, color: Colors.green, size: 40),
                title: Text('২৪/৭ হেল্প ডেস্ক', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('কোর্স বা অ্যাপ সংক্রান্ত যে কোনো সমস্যায় আমাদের সাথে যোগাযোগ করুন।'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.chat, color: Colors.green),
                title: const Text('WhatsApp Support'),
                subtitle: const Text('+91 9876543210'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('হোয়াটসঅ্যাপ সাপোর্ট ওপেন হচ্ছে...')),
                    );
                  },
                  child: const Text('Chat', style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.email, color: Colors.red),
                title: const Text('ইমেল সাপোর্ট'),
                subtitle: const Text('support@targetcivilservice.com'),
                trailing: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Mail'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// অ্যাডমিন ড্যাশবোর্ড
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('সব ফিল্ড পূরণ করুন!')));
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
      const SnackBar(content: Text('পুশ নোটিফিকেশন পাঠানো হয়েছে!')),
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
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'নোটিসের শিরোনাম', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _msgController, maxLines: 3, decoration: const InputDecoration(labelText: 'বিস্তারিত মেসেজ', border: OutlineInputBorder())),
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

// সম্পূর্ণ প্রোফাইল সাইড ড্রয়ার মেনু
class AppSideDrawer extends StatelessWidget {
  final bool isDarkMode;
  final Function(bool) onToggleTheme;

  const AppSideDrawer({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  void _openAdminLogin(BuildContext context) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('অ্যাডমিন প্যানেলে লগইন'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'পাসওয়ার্ড দিন (ডিফল্ট: 12345)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
          ElevatedButton(
            onPressed: () {
              if (passwordController.text == '12345') {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ভুল পাসওয়ার্ড!')));
              }
            },
            child: const Text('প্রবেশ করুন'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // প্রোফাইল হেডার
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFD32F2F)),
            accountName: Text(AppState.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            accountEmail: Text('${AppState.userEmail} | ${AppState.userCity}'),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFFD32F2F), size: 40),
            ),
          ),
          
          // ১. My Profile
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.blue),
            title: const Text('My Profile (আমার প্রোফাইল)'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyProfileScreen()));
            },
          ),

          // ২. My Orders (পেইড কোর্স)
          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined, color: Colors.orange),
            title: const Text('My Orders (কেনা কোর্স)'),
            subtitle: Text('${AppState.purchasedCourses.length} টি কোর্স কেনা আছে'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersScreen()));
            },
          ),

          // ৩. Refer & Earn (ওয়ালেট)
          ListTile(
            leading: const Icon(Icons.monetization_on_outlined, color: Colors.green),
            title: const Text('Refer & Earn (ওয়ালেট ব্যালেন্স)'),
            subtitle: Text('${AppState.userCoins} Coins (₹${AppState.userCoins})'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferEarnScreen()));
            },
          ),

          // ৪. Study Planner (১৫-২০টি অ্যালার্ম)
          ListTile(
            leading: const Icon(Icons.alarm, color: Colors.purple),
            title: const Text('Study Planner (স্টাডি অ্যালার্ম)'),
            subtitle: const Text('দৈনিক পড়ার রুটিন ও রিমাইন্ডার'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StudyAlarmScreen()));
            },
          ),

          // ৫. Job Alerts
          ListTile(
            leading: const Icon(Icons.work_outline, color: Colors.amber),
            title: const Text('Job Alerts (চাকরির আপডেট)'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const JobAlertsScreen()));
            },
          ),

          // ৬. ভাষা নির্বাচন
          ListTile(
            leading: const Icon(Icons.language, color: Colors.teal),
            title: const Text('Language (ভাষা)'),
            subtitle: const Text('বাংলা (ডিফল্ট)'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('বর্তমানে বাংলা ভাষা সক্রিয় আছে।')));
            },
          ),

          // ৭. ডার্ক মোড সুইচ
          SwitchListTile(
            secondary: const Icon(Icons.brightness_6, color: Colors.blueGrey),
            title: const Text('Dark Mode (ডার্ক মোড)'),
            value: isDarkMode,
            onChanged: (val) => onToggleTheme(val),
          ),

          // ৮. হেল্প ও সাপোর্ট
          ListTile(
            leading: const Icon(Icons.support_agent, color: Colors.green),
            title: const Text('Help & Support (সহায়তা)'),
            subtitle: const Text('হোয়াটসঅ্যাপ ও হেল্প ডেস্ক'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
            },
          ),

          const Divider(),

          // ৯. অ্যাডমিন প্যানেল
          ListTile(
            leading: const Icon(Icons.admin_panel_settings, color: Colors.indigo),
            title: const Text('Admin Panel (লগইন)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
            subtitle: const Text('পাসওয়ার্ড: 8436'),
            onTap: () {
              Navigator.pop(context);
              _openAdminLogin(context);
            },
          ),
        ],
      ),
    );
  }
}
