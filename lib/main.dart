import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyEduApp());
}

class MyEduApp extends StatelessWidget {
  const MyEduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Edu App',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFD32F2F),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFD32F2F)),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFD32F2F),
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const MainNavigationHolder(),
    );
  }
}

// মূল নেভিগেশন হোল্ডার (বটম বার কন্ট্রোল)
class MainNavigationHolder extends StatefulWidget {
  const MainNavigationHolder({super.key});

  @override
  State<MainNavigationHolder> createState() => _MainNavigationHolderState();
}

class _MainNavigationHolderState extends State<MainNavigationHolder> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreenContent(),
    const Center(child: Text('My Content (ফ্রি ও পেইড স্টাডি মেটেরিয়ালস)', style: TextStyle(fontSize: 16))),
    const Center(child: Text('Test Prime (মক টেস্ট সিরিজ)', style: TextStyle(fontSize: 16))),
    const StoreScreenContent(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppSideDrawer(),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFD32F2F),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'My Content'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Test Prime'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Store'),
        ],
      ),
    );
  }
}

// ১. হোম স্ক্রিন কনটেন্ট
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
                    const Text(
                      'West Bengal ▾',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.notifications_active, color: Colors.white),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('অ্যাডমিন নোটিফিকেশন সেন্টার')),
                        );
                      },
                    ),
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Color(0xFFD32F2F)),
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

          // স্ক্রলেবল বডি
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

                  // ১২টি স্টাডি আইকন
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
                              Text('টার্গেট ব্যাচ ও মক টেস্টগুলো দেখুন', style: TextStyle(color: Colors.white70, fontSize: 12)),
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

                  // ফ্রি লাইভ ক্লাস ফিড
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
                        Container(
                          height: 130,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_circle_outline, size: 44, color: Colors.red),
                                SizedBox(height: 6),
                                Text('ইন-অ্যাপ ইউটিউব ক্লাস প্লেয়ার', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
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
      {'title': 'Subject-wise Quizzes', 'icon': Icons.menu_book, 'color': Colors.amber.shade800},
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
                  SnackBar(content: Text('${item['title']} সেকশনটি চালু হচ্ছে...')),
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

// ২. স্টোর পেজ (পেইড ব্যাচ)
class StoreScreenContent extends StatelessWidget {
  const StoreScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> courses = [
      {
        'title': 'WBCS 2026 Foundation Batch',
        'price': '₹1999',
        'validity': '১ বছর',
        'coinsOff': '২৫ কয়েন দিয়ে ২৫ টাকা ছাড়',
        'color': Colors.blue.shade800,
      },
      {
        'title': 'কলকাতা পুলিশ কনস্টেবল স্পেশাল ব্যাচ',
        'price': '₹999',
        'validity': '৬ মাস',
        'coinsOff': '২৫ কয়েন দিয়ে ২৫ টাকা ছাড়',
        'color': Colors.red.shade800,
      },
      {
        'title': 'WBPSC ক্লার্কশিপ ক্র্যাশ কোর্স',
        'price': '₹799',
        'validity': '৪ মাস',
        'coinsOff': '২৫ কয়েন দিয়ে ২৫ টাকা ছাড়',
        'color': Colors.green.shade800,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('পেইড কোর্স স্টোর (Store)'),
        backgroundColor: const Color(0xFFD32F2F),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final c = courses[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 90,
                  decoration: BoxDecoration(
                    color: c['color'],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Center(
                    child: Text(
                      c['title'],
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
                          Text(c['coinsOff'], style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text(c['price'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${c['title']} পেমেন্ট গেটওয়েতে পাঠানো হচ্ছে...')),
                          );
                        },
                        child: const Text('Buy Now', style: TextStyle(color: Colors.white)),
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

// ৩. রেফার অ্যান্ড আর্ন স্ক্রিন
class ReferEarnScreen extends StatelessWidget {
  const ReferEarnScreen({super.key});

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
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.monetization_on, size: 50, color: Colors.amber),
                    SizedBox(height: 6),
                    Text('আপনার ব্যালেন্স', style: TextStyle(color: Colors.brown)),
                    Text('25 Coins', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    Text('২৫ কয়েন = ২৫ টাকার সমতুল্য (কোর্স ফি-তে ছাড়)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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
                    Text('• পেইড কোর্স কেনার সময় এই টাকা ছাড় পাওয়া যাবে।'),
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
                  Expanded(child: Text('https://eduapp.com/ref/SANAT25', style: TextStyle(fontWeight: FontWeight.bold))),
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
                label: const Text('বন্ধুদের শেয়ার করুন', style: TextStyle(color: Colors.white)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('রেফারেল লিংক কপি করা হয়েছে!')));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ৪. স্টাডি অ্যালার্ম পেজ (১৫-২০টি অ্যালার্ম)
class StudyAlarmScreen extends StatefulWidget {
  const StudyAlarmScreen({super.key});

  @override
  State<StudyAlarmScreen> createState() => _StudyAlarmScreenState();
}

class _StudyAlarmScreenState extends State<StudyAlarmScreen> {
  final List<Map<String, dynamic>> _alarms = [
    {'time': '06:00 AM', 'title': 'সকাল ৬:০০ - কারেন্ট অ্যাফেয়ার্স', 'active': true},
    {'time': '09:30 AM', 'title': 'সকাল ৯:৩০ - গণিত প্র্যাকটিস', 'active': true},
    {'time': '08:00 PM', 'title': 'রাত ৮:০০ - ফুল মক টেস্ট', 'active': true},
  ];

  void _addAlarm() async {
    if (_alarms.length >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('সর্বোচ্চ ২০টি অ্যালার্ম যুক্ত করতে পারবেন।')));
      return;
    }
    final TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time != null && mounted) {
      final textController = TextEditingController();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('পড়ার বিষয় / রুটিন নাম'),
          content: TextField(controller: textController, decoration: const InputDecoration(hintText: 'যেমন: ইংরেজি রিভিশন')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _alarms.add({
                    'time': time.format(context),
                    'title': textController.text.isEmpty ? 'পড়ার সময়' : textController.text,
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
        itemCount: _alarms.length,
        itemBuilder: (context, index) {
          final item = _alarms[index];
          return Card(
            child: ListTile(
              leading: Icon(Icons.alarm, color: item['active'] ? const Color(0xFFD32F2F) : Colors.grey),
              title: Text(item['time'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              subtitle: Text(item['title']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: item['active'],
                    activeColor: const Color(0xFFD32F2F),
                    onChanged: (val) => setState(() => item['active'] = val),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () => setState(() => _alarms.removeAt(index)),
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
        label: Text('নতুন অ্যালার্ম (${_alarms.length}/20)', style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ৫. মাই অর্ডার্স স্ক্রিন
class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders (কেনা কোর্স)'), backgroundColor: const Color(0xFFD32F2F)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green, size: 36),
              title: const Text('WBCS 2026 Foundation Batch', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('পেমেন্ট সফল • পেইড ক্লাস অ্যাক্টিভ'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('কোর্সের ক্লাসরুমে প্রবেশ করছেন...')));
                },
                child: const Text('Start', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ৬. জব অ্যালার্ট স্ক্রিন
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

// ৭. সাইড ড্রয়ার / প্রোফাইল মেনু
class AppSideDrawer extends StatelessWidget {
  const AppSideDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Color(0xFFD32F2F)),
            accountName: Text('Sanat Kumar Das', style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text('sanat@example.com | Kolkata'),
            currentAccountPicture: CircleAvatar(
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
            subtitle: const Text('২৫ কয়েন = ২৫ টাকা'),
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
            title: const Text('Job Alerts'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const JobAlertsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings (ডার্ক/লাইট মোড)'),
            onTap: () => Navigator.pop(context),
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
