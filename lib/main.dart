import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // sqflite_common_ffi hanya untuk desktop. Pada Android/iOS,
  // sqflite memakai database factory bawaan platform.
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await loadItemsFromDatabase();

  runApp(const TbXiApp());
}

// ============================================================
// DATA LOKAL SEMENTARA
// ============================================================

class TbItem {
  final String name;
  final String description;
  final String type;

  TbItem({
    required this.name,
    required this.description,
    required this.type,
  });
}

final ValueNotifier<List<TbItem>> itemsNotifier =
    ValueNotifier<List<TbItem>>([
  TbItem(
    name: 'Nasi Gratis',
    description: '5 bungkus tersedia',
    type: 'BERBAGI',
  ),
  TbItem(
    name: 'Sayuran',
    description: 'Segar · Rp5.000',
    type: 'BERBAGI',
  ),
  TbItem(
    name: 'Servis Kipas',
    description: 'Jasa perbaikan',
    type: 'BERBAGI',
  ),
]);

void addItem(TbItem item) {
  itemsNotifier.value = [
    item,
    ...itemsNotifier.value,
  ];
}

// ============================================================
// DATA PENGGUNA
// ============================================================

String currentUserName = '';
String currentUserPhone = '';
String currentUserEmail = '';

// ============================================================
// APP
// ============================================================

class TbXiApp extends StatelessWidget {
  const TbXiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TB XI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F7F4),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9A7500),
        ),
      ),
      home: const AppStartPage(),
    );
  }
}

// ============================================================
// APP START
// ============================================================

class AppStartPage extends StatefulWidget {
  const AppStartPage({super.key});

  @override
  State<AppStartPage> createState() => _AppStartPageState();
}

class _AppStartPageState extends State<AppStartPage> {
  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    final db = await DatabaseHelper.instance.database;

    final users = await db.query(
      'users',
      orderBy: 'id DESC',
      limit: 1,
    );

    if (!mounted) return;

    if (users.isNotEmpty) {
      final user = users.first;

      currentUserName = user['name'] as String;
      currentUserPhone = user['phone'] as String;
      currentUserEmail = user['email'] as String;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const WelcomePage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF9A7500),
        ),
      ),
    );
  }
}


// ============================================================
// WELCOME / PEMBUKA
// ============================================================

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  void openLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF123D32),
              Color(0xFF1F6048),
              Color(0xFF071D18),
            ],
            stops: [0.0, 0.48, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Semantics(
                    button: true,
                    label: 'Masuk ke TB XI',
                    child: InkWell(
                      onTap: () => openLogin(context),
                      borderRadius: BorderRadius.circular(155),
                      child: Container(
                        width: 286,
                        height: 286,
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFFE9A3),
                              Color(0xFFD4AF37),
                              Color(0xFF8A5D08),
                              Color(0xFFFFD966),
                            ],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x88000000),
                              blurRadius: 34,
                              spreadRadius: 8,
                              offset: Offset(0, 16),
                            ),
                            BoxShadow(
                              color: Color(0x66E8C65A),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFFF0B8),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: Transform.scale(
                              scale: 1.18,
                              child: Image.asset(
                                'assets/images/tb_xi_logo.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  const Text(
                    'SEDERHANA, BERMAKNA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFFE7A0),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.2,
                      shadows: [
                        Shadow(
                          color: Color(0xAA000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'DEKAT DENGAN MANUSIA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFF7F0D0),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.8,
                      shadows: [
                        Shadow(
                          color: Color(0x99000000),
                          blurRadius: 7,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'KETUK LOGO UNTUK MASUK',
                    style: TextStyle(
                      color: Color(0xB3FFFFFF),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// LOGIN / REGISTRASI
// ============================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> continueToHome() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty || phone.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi nama, nomor HP, dan email.'),
        ),
      );
      return;
    }

    await DatabaseHelper.instance.createUser(
      name: name,
      phone: phone,
      email: email,
    );

    currentUserName = name;
    currentUserPhone = phone;
    currentUserEmail = email;

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // LOGO
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD4AF37),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/tb_xi_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                const Center(
                  child: Text(
                    'TB XI',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                const Center(
                  child: Text(
                    'Sederhana, Bermakna,\nDekat dengan Manusia.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 42),

                const Text(
                  'Buat akun TB XI',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Satu nomor HP untuk satu akun.',
                  style: TextStyle(
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 24),

                _field(
                  controller: nameController,
                  label: 'Nama panggilan',
                  hint: 'Contoh: Budi',
                  icon: Icons.person_outline,
                ),

                const SizedBox(height: 14),

                _field(
                  controller: phoneController,
                  label: 'Nomor HP',
                  hint: 'Contoh: 08123456789',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 14),

                _field(
                  controller: emailController,
                  label: 'Email',
                  hint: 'Contoh: nama@email.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 28),

                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: continueToHome,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF9A7500),
                    ),
                    child: const Text(
                      'LANJUTKAN',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const Text(
                  'Dengan menggunakan TB XI, Anda setuju '
                  'menggunakan layanan dengan baik dan bertanggung jawab.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.black12,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.black12,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HOME
// ============================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  Widget get currentPage {
    switch (selectedIndex) {
      case 1:
        return const ActivityPage();
      case 2:
        return const ProfilePage();
      default:
        return const HomeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: currentPage,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        elevation: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'Aktivitas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Saya',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// AKTIVITAS
// ============================================================

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  bool loading = true;
  List<Map<String, dynamic>> pendingMatches = [];
  List<Map<String, dynamic>> acceptedMatches = [];

  @override
  void initState() {
    super.initState();
    _loadPendingMatches();
  }

  Future<void> _loadPendingMatches() async {
    try {
      final user = await DatabaseHelper.instance.getUserByPhone(
        currentUserPhone,
      );

      if (user == null) {
        if (!mounted) return;
        setState(() {
          loading = false;
        });
        return;
      }

      final userId = user['id'] as int;

      print('ACTIVITY PHONE: $currentUserPhone');
      print('ACTIVITY USER ID: $userId');

      final result =
          await DatabaseHelper.instance.getPendingMatches(ownerUserId: userId);

      final accepted =
          await DatabaseHelper.instance.getAcceptedMatches(userId: userId);

      print('PENDING MATCH RESULT: ${result.length}');
      print('ACCEPTED MATCH RESULT: ${accepted.length}');

      if (!mounted) return;

      setState(() {
        pendingMatches = result;
        acceptedMatches = accepted;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const Text(
                'Aktivitas',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Aktivitas dan riwayat Anda di TB XI.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 28),

              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (pendingMatches.isEmpty)
                _activityCard(
                  icon: Icons.hourglass_empty,
                  title: 'Match sedang berjalan',
                  description:
                      'Belum ada match yang sedang berjalan.',
                  iconColor: const Color(0xFF9A7500),
                )
              else
                ...pendingMatches.map(
                  (match) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      children: [
                        _activityCard(
                          icon: Icons.hourglass_empty,
                          title: 'Permintaan MATCH',
                          description:
                              '${match['name']} · Menunggu konfirmasi',
                          iconColor: const Color(0xFF9A7500),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  await DatabaseHelper.instance
                                      .updateMatchStatus(
                                    matchId: match['match_id'] as int,
                                    status: 'REJECTED',
                                  );

                                  if (!mounted) return;

                                  _loadPendingMatches();
                                },
                                child: const Text('TOLAK'),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: FilledButton(
                                onPressed: () async {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'TERIMA ditekan: ${match['match_id']}',
                                      ),
                                    ),
                                  );

                                  final matchId =
                                      match['match_id'] as int;

                                  print(
                                    'TERIMA MATCH ID: $matchId',
                                  );

                                  final updated =
                                      await DatabaseHelper.instance
                                          .updateMatchStatus(
                                    matchId: matchId,
                                    status: 'ACCEPTED',
                                  );

                                  print(
                                    'MATCH BERHASIL DIUPDATE: $updated',
                                  );

                                  if (!mounted) return;

                                  _loadPendingMatches();
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF5D8055),
                                ),
                                child: const Text('TERIMA'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 14),

              if (acceptedMatches.isEmpty)
                _activityCard(
                  icon: Icons.check_circle_outline,
                  title: 'Selesai',
                  description:
                      'Belum ada match yang selesai.',
                  iconColor: const Color(0xFF5D8055),
                )
              else
                ...acceptedMatches.map(
                  (match) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _activityCard(
                      icon: Icons.check_circle,
                      title: 'MATCH DITERIMA',
                      description:
                          '${match['name']} · Match berhasil dikonfirmasi',
                      iconColor: const Color(0xFF5D8055),
                    ),
                  ),
                ),

              const SizedBox(height: 14),

              _activityCard(
                icon: Icons.history,
                title: 'Riwayat',
                description:
                    'Belum ada aktivitas sebelumnya.',
                iconColor: Colors.black54,
              ),
            ]),
          ),
        ),
      ],
    );
  }

  static Widget _activityCard({
    required IconData icon,
    required String title,
    required String description,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black12,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SAYA
// ============================================================

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Data akun dan aktivitas lokal di perangkat ini akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('BATAL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('KELUAR'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await DatabaseHelper.instance.clearLocalAccount(currentUserPhone);
      currentUserName = '';
      currentUserPhone = '';
      currentUserEmail = '';
      itemsNotifier.value = [];

      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal keluar dari akun: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const Text(
                'Saya',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.black12,
                  ),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFFEDE8D8),
                      child: Icon(
                        Icons.person,
                        size: 32,
                        color: Color(0xFF8A6B08),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUserName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentUserPhone,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentUserEmail,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              _profileMenu(
                icon: Icons.person_outline,
                title: 'Profil',
                subtitle: 'Data diri dan informasi akun',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileDetailPage(),
                    ),
                  );
                },
              ),

              _profileMenu(
                icon: Icons.location_on_outlined,
                title: 'Lokasi',
                subtitle: 'Atur lokasi dan radius pencarian',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LocationPage(),
                    ),
                  );
                },
              ),

              _profileMenu(
                icon: Icons.info_outline,
                title: 'Tentang TB XI',
                subtitle: 'Sederhana, Bermakna, Dekat dengan Manusia.',
              ),

              _profileMenu(
                icon: Icons.logout,
                title: 'Keluar akun',
                subtitle: 'Hapus sesi dan data lokal akun ini',
                iconColor: const Color(0xFFB24C5A),
                onTap: () => _logout(context),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  static Widget _profileMenu({
    required IconData icon,
    required String title,
    required String subtitle,
    Color iconColor = const Color(0xFF8A6B08),
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black12,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: Colors.black38,
          ),
        ],
        ),
      ),
    );
  }
}

class ProfileDetailPage extends StatefulWidget {
  const ProfileDetailPage({super.key});

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;

  @override
  void initState() {
    super.initState();

    nameController =
        TextEditingController(text: currentUserName);
    phoneController =
        TextEditingController(text: currentUserPhone);
    emailController =
        TextEditingController(text: currentUserEmail);
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> saveProfile() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty || phone.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama, nomor HP, dan email wajib diisi.'),
        ),
      );
      return;
    }

    try {
      final db = await DatabaseHelper.instance.database;

      await db.update(
        'users',
        {
          'name': name,
          'phone': phone,
          'email': email,
        },
        where: 'phone = ?',
        whereArgs: [currentUserPhone],
      );

      currentUserName = name;
      currentUserPhone = phone;
      currentUserEmail = email;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan profil: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: const Color(0xFFF8F7F4),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _field(
            controller: nameController,
            label: 'Nama',
            icon: Icons.person_outline,
          ),

          const SizedBox(height: 14),

          _field(
            controller: phoneController,
            label: 'Nomor HP',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 14),

          _field(
            controller: emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: saveProfile,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF9A7500),
              ),
              child: const Text(
                'SIMPAN PERUBAHAN',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.black12,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.black12,
          ),
        ),
      ),
    );
  }
}

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  double radius = 1;
  Position? currentPosition;
  bool loadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
  }

  Future<void> _loadSavedLocation() async {
    try {
      final db = await DatabaseHelper.instance.database;

      final result = await db.query(
        'users',
        columns: [
          'latitude',
          'longitude',
          'location_radius',
        ],
        where: 'phone = ?',
        whereArgs: [currentUserPhone],
        limit: 1,
      );

      if (result.isEmpty || !mounted) return;

      final data = result.first;

      final latitude =
          double.tryParse(data['latitude']?.toString() ?? '');

      final longitude =
          double.tryParse(data['longitude']?.toString() ?? '');

      final savedRadius =
          double.tryParse(data['location_radius']?.toString() ?? '');

      if (latitude == null || longitude == null) return;

      setState(() {
        currentPosition = Position(
          latitude: latitude,
          longitude: longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );

        if (savedRadius != null) {
          radius = savedRadius.clamp(1, 10);
        }
      });
    } catch (e) {
      debugPrint('Gagal memuat lokasi tersimpan: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      loadingLocation = true;
    });

    try {
      // LINUX/DESKTOP:
      // Langsung gunakan lokasi berdasarkan IP.
      // GPS Linux/GeoClue sering tidak tersedia.
      if (Platform.isLinux) {
        final response = await http
            .get(
              Uri.parse('https://ipinfo.io/json'),
            )
            .timeout(const Duration(seconds: 8));

        if (response.statusCode != 200) {
          throw Exception('Tidak dapat memperoleh lokasi.');
        }

        final data = jsonDecode(response.body);

        final loc = data['loc']?.toString() ?? '';
        final parts = loc.split(',');

        if (parts.length != 2) {
          throw Exception('Koordinat lokasi tidak tersedia.');
        }

        final latitude = double.tryParse(parts[0].trim());
        final longitude = double.tryParse(parts[1].trim());

        final city = data['city']?.toString() ?? '';
        final region = data['region']?.toString() ?? '';
        final country = data['country']?.toString() ?? '';

        if (latitude == null || longitude == null) {
          throw Exception('Koordinat lokasi tidak tersedia.');
        }

        if (!mounted) return;

        setState(() {
          currentPosition = Position(
            longitude: longitude,
            latitude: latitude,
            timestamp: DateTime.now(),
            accuracy: 5000,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lokasi ditemukan: $city, $region, $country',
            ),
          ),
        );

        return;
      }

      // ANDROID / MOBILE:
      // Coba GPS terlebih dahulu.
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (serviceEnabled) {
        LocationPermission permission =
            await Geolocator.checkPermission();

        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {
          try {
            final position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 8),
              ),
            );

            if (!mounted) return;

            setState(() {
              currentPosition = position;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Lokasi GPS berhasil diperoleh.'),
              ),
            );

            return;
          } catch (_) {
            // GPS gagal, lanjut ke fallback IP.
          }
        }
      }

      // FALLBACK IP untuk mobile jika GPS gagal.
      final response = await http
          .get(
            Uri.parse('https://ipinfo.io/json'),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        throw Exception('Tidak dapat memperoleh lokasi.');
      }

      final data = jsonDecode(response.body);

      final loc = data['loc']?.toString() ?? '';
      final parts = loc.split(',');

      if (parts.length != 2) {
        throw Exception('Koordinat lokasi tidak tersedia.');
      }

      final latitude = double.tryParse(parts[0].trim());
      final longitude = double.tryParse(parts[1].trim());

      final city = data['city']?.toString() ?? '';
      final region = data['region']?.toString() ?? '';
      final country = data['country']?.toString() ?? '';

      if (latitude == null || longitude == null) {
        throw Exception('Koordinat lokasi tidak tersedia.');
      }

      if (!mounted) return;

      setState(() {
        currentPosition = Position(
          longitude: longitude,
          latitude: latitude,
          timestamp: DateTime.now(),
          accuracy: 5000,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lokasi ditemukan: $city, $region, $country',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loadingLocation = false;
        });
      }
    }
  }

  Future<void> _saveLocation() async {
    if (currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tentukan lokasi terlebih dahulu.'),
        ),
      );
      return;
    }

    try {
      final db = await DatabaseHelper.instance.database;

      await db.update(
        'users',
        {
          'latitude': currentPosition!.latitude,
          'longitude': currentPosition!.longitude,
          'location_radius': radius,
        },
        where: 'phone = ?',
        whereArgs: [currentUserPhone],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi dan radius berhasil disimpan.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan lokasi: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi'),
        backgroundColor: const Color(0xFFF8F7F4),
      ),
      backgroundColor: const Color(0xFFF8F7F4),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFF8A6B08),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Lokasi Anda',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  currentPosition == null
                      ? 'Lokasi belum ditentukan.'
                      : 'Lokasi berhasil ditemukan.',
                  style: const TextStyle(color: Colors.black54),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        loadingLocation ? null : _getCurrentLocation,
                    icon: loadingLocation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(
                      loadingLocation
                          ? 'Mencari lokasi...'
                          : 'Gunakan lokasi saya',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF9A7500),
                    ),
                  ),
                ),

                if (currentPosition != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Latitude: ${currentPosition!.latitude}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    'Longitude: ${currentPosition!.longitude}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saveLocation,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text(
                      'SIMPAN LOKASI',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF9A7500),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  'Radius pencarian',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Slider(
                  value: radius,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '${radius.round()} km',
                  activeColor: const Color(0xFF9A7500),
                  onChanged: (value) {
                    setState(() {
                      radius = value;
                    });
                  },
                ),
                Center(
                  child: Text(
                    '${radius.round()} km',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeHero extends StatelessWidget {
  const HomeHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF171717),
            Color(0xFF33270D),
            Color(0xFF8A6B08),
          ],
          stops: [0.0, 0.55, 1.0],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26120E05),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -24,
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0x55D4AF37),
                  width: 18,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD4AF37),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/tb_xi_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Text(
                    'TB XI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'Yang dekat,\nlebih berarti.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  height: 1.08,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Temukan yang dibutuhkan. Bagikan yang Anda punya.',
                style: TextStyle(
                  color: Color(0xD9FFFFFF),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x26FFFFFF),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0x40FFFFFF)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFFE8D18A),
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Semarang Selatan · radius 1 KM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  void openPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const HomeHero(),

              const SizedBox(height: 30),

              const Text(
                'Apa yang ingin Anda lakukan?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 16),

              // BERBAGI + MEMBUTUHKAN
              Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      icon: Icons.favorite_border,
                      title: 'BERBAGI',
                      subtitle: 'Saya ingin berbagi',
                      iconColor: const Color(0xFFB24C5A),
                      onTap: () {
                        openPage(
                          context,
                          const FormPage(
                            title: 'Saya Berbagi',
                            description:
                                'Apa yang ingin Anda bagikan?',
                            buttonText: 'BAGIKAN',
                            type: 'BERBAGI',
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ActionButton(
                      icon: Icons.volunteer_activism_outlined,
                      title: 'MEMBUTUHKAN',
                      subtitle: 'Saya membutuhkan',
                      iconColor: const Color(0xFF3F6F8F),
                      onTap: () {
                        openPage(
                          context,
                          const FormPage(
                            title: 'Saya Membutuhkan',
                            description:
                                'Apa yang sedang Anda butuhkan?',
                            buttonText: 'POSTING KEBUTUHAN',
                            type: 'MEMBUTUHKAN',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 34),

              // JUDUL SEKITAR
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Di sekitar Anda',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE8D8),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '≤ 1 KM',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF725900),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // DATA DINAMIS
              ValueListenableBuilder<List<TbItem>>(
                valueListenable: itemsNotifier,
                builder: (context, items, child) {
                  return Column(
                    children: items.map((item) {
                      return NearbyCard(
                        item: item,
                        onMatch: () {
                          openPage(
                            context,
                            MatchPage(
                              itemName: item.name,
                              itemType: item.type,
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ACTION BUTTON
// ============================================================

class ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final bool fullWidth;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      width: fullWidth ? double.infinity : null,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.black12,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(
                      alpha: 0.10,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// NEARBY CARD
// ============================================================

class NearbyCard extends StatelessWidget {
  final TbItem item;
  final VoidCallback onMatch;

  const NearbyCard({
    super.key,
    required this.item,
    required this.onMatch,
  });

  String get emoji {
    final name = item.name.toLowerCase();

    if (name.contains('nasi')) return '🍚';
    if (name.contains('sayur')) return '🥬';
    if (name.contains('beras')) return '🍚';
    if (name.contains('baju')) return '👕';
    if (name.contains('kipas')) return '🔧';

    return '📦';
  }

  String get actionLabel {
    if (item.type == 'BERBAGI') return 'SAYA MENERIMA';
    if (item.type == 'MEMBUTUHKAN' || item.type == 'BUTUH') {
      return 'SAYA BERBAGI';
    }
    return 'SAYA BERBAGI';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black12,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F1E6),
              borderRadius: BorderRadius.circular(15),
            ),
            alignment: Alignment.center,
            child: Text(
              emoji,
              style: const TextStyle(
                fontSize: 28,
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.black45,
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'sekitar Anda',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      item.type == 'PUNYA'
                          ? 'BERBAGI'
                          : item.type == 'BUTUH'
                              ? 'MEMBUTUHKAN'
                              : item.type,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          SizedBox(
            width: 112,
            child: FilledButton(
              onPressed: onMatch,
              style: FilledButton.styleFrom(
                backgroundColor:
                    const Color(0xFF8A6B08),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FORM
// ============================================================

class FormPage extends StatefulWidget {
  final String title;
  final String description;
  final String buttonText;
  final String type;

  const FormPage({
    super.key,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.type,
  });

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  final TextEditingController itemController =
      TextEditingController();

  final TextEditingController detailController =
      TextEditingController();

  @override
  void dispose() {
    itemController.dispose();
    detailController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final name = itemController.text.trim();
    final detail = detailController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan isi nama kebutuhan.'),
        ),
      );
      return;
    }

    final user = await DatabaseHelper.instance.getUserByPhone(
      currentUserPhone,
    );

    if (!mounted) return;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data pengguna tidak ditemukan.'),
        ),
      );
      return;
    }

    await DatabaseHelper.instance.createItem(
      userId: user['id'] as int,
      name: name,
      description: detail.isEmpty ? widget.type : detail,
      type: widget.type,
      latitude: user['latitude'] as double?,
      longitude: user['longitude'] as double?,
    );

    if (!mounted) return;

    addItem(
      TbItem(
        name: name,
        description: detail.isEmpty
            ? widget.type
            : detail,
        type: widget.type,
      ),
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$name berhasil ditambahkan.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF8F7F4),
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              widget.description,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Nama / kebutuhan',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: itemController,
              decoration: InputDecoration(
                hintText:
                    'Contoh: nasi, beras, sayuran...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(
                    color: Colors.black12,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Keterangan',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: detailController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Keterangan singkat...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(
                    color: Colors.black12,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE8D8),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFF8A6B08),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Posting hanya akan terlihat '
                      'oleh pengguna dalam radius maksimal 1 KM.',
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: submit,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF8A6B08),
                ),
                child: Text(
                  widget.buttonText,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MATCH
// ============================================================

class MatchPage extends StatefulWidget {
  final String itemName;
  final String itemType;

  const MatchPage({
    super.key,
    required this.itemName,
    required this.itemType,
  });

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  int step = 0;
  bool loadingMatches = true;
  List<Map<String, dynamic>> matches = [];

  final TextEditingController instructionController =
      TextEditingController();

  String get actionLabel =>
      widget.itemType == 'BERBAGI'
          ? 'SAYA MENERIMA'
          : 'SAYA BERBAGI';

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    try {
      final db = await DatabaseHelper.instance.database;

      final users = await db.query(
        'users',
        where: 'phone = ?',
        whereArgs: [currentUserPhone],
        limit: 1,
      );

      if (users.isEmpty) {
        if (mounted) {
          setState(() {
            loadingMatches = false;
          });
        }
        return;
      }

      final user = users.first;

      final latitude =
          (user['latitude'] as num?)?.toDouble();

      final longitude =
          (user['longitude'] as num?)?.toDouble();

      final radius =
          (user['location_radius'] as num?)?.toDouble() ?? 1;

      if (latitude == null || longitude == null) {
        if (mounted) {
          setState(() {
            loadingMatches = false;
          });
        }
        return;
      }

      final result =
          await DatabaseHelper.instance.findMatches(
        itemId: 0,
        type: widget.itemType,
        name: widget.itemName,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radius,
      );

      if (!mounted) return;

      setState(() {
        matches = result;
        loadingMatches = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loadingMatches = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mencari MATCH: $e'),
        ),
      );
    }
  }

  @override
  void dispose() {
    instructionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (step == 0) {
      return _matchConfirmation();
    }

    if (step == 1) {
      return _waitingPage();
    }

    if (step == 2) {
      return _instructionPage();
    }

    return _finishedPage();
  }

  Widget _matchConfirmation() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F7F4),
        title: const Text('Match'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 30),

            const Icon(
              Icons.favorite,
              size: 64,
              color: Color(0xFFB24C5A),
            ),

            const SizedBox(height: 18),

            Text(
              widget.itemType == 'BERBAGI'
                  ? 'Anda ingin menerima?'
                  : 'Anda ingin berbagi?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              widget.itemName,
              style: const TextStyle(
                fontSize: 21,
                color: Color(0xFF8A6B08),
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 20),

            if (loadingMatches)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (matches.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Belum ada calon MATCH\n'
                    'dalam radius yang ditentukan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: matches.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final match = matches[index];

                    final matchType =
                        match['type'] as String? ?? '';

                    final distance =
                        (match['distance_km'] as num?)
                                ?.toDouble() ??
                            0;

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F1E6),
                        borderRadius:
                            BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.black12,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.itemType}  ↔  $matchType',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF8A6B08),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            match['name'] as String? ??
                                widget.itemName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Jarak ${distance.toStringAsFixed(3)} KM',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () async {
                        try {
                          final db =
                              await DatabaseHelper.instance.database;

                          final users = await db.query(
                            'users',
                            where: 'phone = ?',
                            whereArgs: [currentUserPhone],
                            limit: 1,
                          );

                          if (users.isEmpty) {
                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Data pengguna tidak ditemukan.',
                                ),
                              ),
                            );
                            return;
                          }

                          final requesterUserId =
                              users.first['id'] as int;

                          if (matches.isEmpty) {
                            await DatabaseHelper.instance.createMatchRequest(
                              requesterUserId: requesterUserId,
                              itemName: widget.itemName,
                              itemType: widget.itemType,
                            );

                            if (!mounted) return;

                            setState(() {
                              step = 1;
                            });
                            return;
                          }

                          final candidate = matches.first;

                          final itemId =
                              candidate['id'] as int;

                          final ownerUserId =
                              candidate['user_id'] as int;

                          final alreadyMatched =
                              await DatabaseHelper.instance.hasActiveMatch(
                            itemId: itemId,
                            requesterUserId: requesterUserId,
                            ownerUserId: ownerUserId,
                          );

                          if (alreadyMatched) {
                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'MATCH untuk item ini sudah berjalan atau sudah diterima.',
                                ),
                              ),
                            );

                            return;
                          }

                          await DatabaseHelper.instance.createMatch(
                            itemId: itemId,
                            requesterUserId: requesterUserId,
                            ownerUserId: ownerUserId,
                          );

                          if (!mounted) return;

                          setState(() {
                            step = 1;
                          });
                        } catch (e) {
                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Gagal menyimpan MATCH: $e',
                              ),
                            ),
                          );
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF8A6B08),
                ),
                child: Text(
                  actionLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            TextButton(
              onPressed: () =>
                  Navigator.pop(context),
              child: const Text('BATAL'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _waitingPage() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F7F4),
        title: const Text('Match'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 50),

            const Icon(
              Icons.hourglass_empty,
              size: 70,
              color: Color(0xFF8A6B08),
            ),

            const SizedBox(height: 24),

            const Text(
              'Permintaan tersimpan',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              widget.itemName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Permintaan Anda tersimpan dan akan menunggu calon '
              'yang sesuai.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'Tidak ada nomor telepon atau alamat '
              'pribadi yang dibagikan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black45,
              ),
            ),

            const Spacer(),

            // CEK ULANG CALON
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () async {
                  setState(() {
                    loadingMatches = true;
                  });
                  await _loadMatches();
                  if (!mounted) return;
                  if (matches.isNotEmpty) {
                    setState(() {
                      step = 0;
                    });
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8A6B08),
                ),
                child: const Text(
                  'CEK LAGI CALON',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('BATALKAN MATCH'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _instructionPage() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F7F4),
        title: const Text('Pengambilan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            const Text(
              'Pemberi sudah siap',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              widget.itemName,
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF8A6B08),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Instruksi pengambilan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: instructionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Contoh: Nasi saya taruh di pagar depan ya.',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Colors.black12,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              'Pesan hanya digunakan untuk instruksi '
              'pengambilan. Tidak ada chat antar pengguna.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black45,
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () {
                  setState(() {
                    step = 3;
                  });
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8A6B08),
                ),
                child: const Text(
                  'KONFIRMASI PENGAMBILAN',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _finishedPage() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F7F4),
        title: const Text('Selesai'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 60),

            const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Color(0xFF5F7F52),
            ),

            const SizedBox(height: 24),

            const Text(
              'Selesai',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              widget.itemName,
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF8A6B08),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Semoga bermanfaat.\n'
              'Terima kasih sudah menggunakan TB XI.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                height: 1.6,
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8A6B08),
                ),
                child: const Text('SELESAI'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> loadItemsFromDatabase() async {
  final rows = await DatabaseHelper.instance.getItems();

  itemsNotifier.value = rows.map((row) {
    return TbItem(
      name: row['name'] as String,
      description: row['description'] as String? ?? '',
      type: row['type'] as String,
    );
  }).toList();
}

