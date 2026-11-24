// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

void main() {
  runApp(const NeroMusicApp());
}

const Color neroBlack = Color(0xFF09090D);
const Color neroSurface = Color(0xFF15151D);
const Color neroSurface2 = Color(0xFF20202A);
const Color neroRed = Color(0xFFED174C);
const Color neroPink = Color(0xFFFF4F91);
const Color neroMuted = Color(0xFFAAAAB5);

class NeroMusicApp extends StatelessWidget {
  const NeroMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nero Music',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: neroBlack,
        colorScheme: const ColorScheme.dark(
          primary: neroRed,
          secondary: neroPink,
          surface: neroSurface,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: neroBlack,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: neroSurface,
          hintStyle: const TextStyle(color: neroMuted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [neroRed, neroPink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: neroRed.withValues(alpha: 0.28),
                        blurRadius: 35,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.graphic_eq_rounded,
                    size: 58,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'NERO MUSIC',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your Music. Your World.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: neroPink,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Listen, store, share and earn.',
                textAlign: TextAlign.center,
                style: TextStyle(color: neroMuted, fontSize: 14),
              ),
              const SizedBox(height: 42),
              _PrimaryButton(
                label: 'GET STARTED',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AccountChoiceScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 13),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SignInScreen(),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: neroSurface2),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('SIGN IN'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NeroHomeScreen(),
                  ),
                ),
                child: const Text(
                  'EXPLORE APP PREVIEW',
                  style: TextStyle(color: neroPink, letterSpacing: 1),
                ),
              ),
              const Spacer(),
              const Text(
                'MUSIC CONNECTS US',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: neroMuted,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountChoiceScreen extends StatelessWidget {
  const AccountChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create your account')),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 18),
            const Text(
              'How will you use Nero Music?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 9),
            const Text(
              'You can listen with a Listener account and apply to become a verified artist later.',
              style: TextStyle(color: neroMuted, height: 1.5),
            ),
            const SizedBox(height: 28),
            _ChoiceCard(
              icon: Icons.headphones_rounded,
              title: 'Listener',
              subtitle: 'Discover, stream, save and purchase music.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SignUpScreen(accountType: 'Listener'),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _ChoiceCard(
              icon: Icons.mic_rounded,
              title: 'Apply as an Artist',
              subtitle: 'Create an account and submit an artist application for verification.',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SignUpScreen(accountType: 'Artist applicant'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AccountFormScreen(
      title: 'Welcome back',
      buttonLabel: 'SIGN IN',
      accountType: 'Listener',
    );
  }
}

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key, required this.accountType});

  final String accountType;

  @override
  Widget build(BuildContext context) {
    return AccountFormScreen(
      title: 'Create your account',
      buttonLabel: 'CREATE ACCOUNT',
      accountType: accountType,
      showName: true,
    );
  }
}

class AccountFormScreen extends StatefulWidget {
  const AccountFormScreen({
    super.key,
    required this.title,
    required this.buttonLabel,
    required this.accountType,
    this.showName = false,
  });

  final String title;
  final String buttonLabel;
  final String accountType;
  final bool showName;

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.accountType)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Text(widget.title,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Your Nero Music account starts here.',
              style: TextStyle(color: neroMuted),
            ),
            const SizedBox(height: 26),
            if (widget.showName) ...[
              _Field(
                controller: _nameController,
                label: 'Full name',
                icon: Icons.person_outline,
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Enter your name' : null,
              ),
              const SizedBox(height: 14),
            ],
            _Field(
              controller: _emailController,
              label: 'Email address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || !value.contains('@')) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _Field(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline,
              obscureText: true,
              validator: (value) => (value == null || value.length < 8)
                  ? 'Use at least 8 characters'
                  : null,
            ),
            const SizedBox(height: 24),
            _PrimaryButton(
              label: widget.buttonLabel,
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account services will be connected in Stage 1.'),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 14),
            const Text(
              'Demo interface only: account creation and sign-in are not active until Supabase is connected.',
              textAlign: TextAlign.center,
              style: TextStyle(color: neroMuted, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: neroPink),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: neroSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: neroSurface2),
        ),
        child: Row(
          children: [
            Icon(icon, color: neroPink, size: 34),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 5),
                  Text(subtitle,
                      style: const TextStyle(color: neroMuted, height: 1.35)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: neroMuted),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: neroRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class NeroHomeScreen extends StatefulWidget {
  const NeroHomeScreen({super.key});

  @override
  State<NeroHomeScreen> createState() => _NeroHomeScreenState();
}

class _NeroHomeScreenState extends State<NeroHomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    _HomeTab(),
    _ExploreTab(),
    _LibraryTab(),
    _EarningsTab(),
    _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        backgroundColor: neroSurface,
        indicatorColor: neroRed.withValues(alpha: 0.22),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.library_music_outlined), selectedIcon: Icon(Icons.library_music), label: 'Library'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Earnings'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NERO MUSIC', style: TextStyle(color: neroPink, fontWeight: FontWeight.w900, letterSpacing: 1.6)),
                  SizedBox(height: 5),
                  Text('Your sound starts here.', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search songs, albums and artists',
            prefixIcon: Icon(Icons.search, color: neroPink),
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: [Color(0xFF8D1238), Color(0xFF301326)]),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FEEL THE MUSIC', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
              SizedBox(height: 7),
              Text('Discover new sounds. Support the artists you love.',
                  style: TextStyle(color: Colors.white70, height: 1.4)),
              SizedBox(height: 15),
              Icon(Icons.graphic_eq, size: 42, color: Colors.white),
            ],
          ),
        ),
        const SizedBox(height: 25),
        const _SectionHeading(title: 'Made for you', action: 'See all'),
        const SizedBox(height: 13),
        const Row(
          children: [
            Expanded(child: _MusicTile(title: 'Afrobeats Mix', subtitle: 'Fresh African sounds', icon: Icons.album)),
            SizedBox(width: 12),
            Expanded(child: _MusicTile(title: 'Late Night', subtitle: 'R&B and chill', icon: Icons.nightlight_round)),
          ],
        ),
        const SizedBox(height: 25),
        const _SectionHeading(title: 'Explore genres', action: 'Browse'),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            _GenreChip(label: 'Afrobeats'),
            _GenreChip(label: 'Gospel'),
            _GenreChip(label: 'Hip-Hop'),
            _GenreChip(label: 'R&B'),
            _GenreChip(label: 'Pop'),
            _GenreChip(label: 'Highlife'),
          ],
        ),
        const SizedBox(height: 25),
        const _SectionHeading(title: 'Artist opportunities', action: 'Learn more'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(color: neroSurface, borderRadius: BorderRadius.circular(18)),
          child: const Row(
            children: [
              Icon(Icons.mic_external_on, color: neroPink, size: 34),
              SizedBox(width: 13),
              Expanded(
                child: Text('Are you an artist? Apply to publish your music and earn from eligible activity.',
                    style: TextStyle(height: 1.4)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExploreTab extends StatelessWidget {
  const _ExploreTab();

  @override
  Widget build(BuildContext context) => const _SimpleTab(
        title: 'Explore',
        subtitle: 'Find music, artists, albums and playlists.',
        icon: Icons.explore,
        details: ['Trending music', 'New releases', 'Top artists', 'Afrobeats', 'Gospel', 'Hip-Hop', 'R&B'],
      );
}

class _LibraryTab extends StatelessWidget {
  const _LibraryTab();

  @override
  Widget build(BuildContext context) => const _SimpleTab(
        title: 'My Library',
        subtitle: 'Your private music and saved collection.',
        icon: Icons.library_music,
        details: ['Private music vault', 'My uploads', 'Playlists', 'Favourites', 'Purchased music', 'Downloads'],
      );
}

class _EarningsTab extends StatelessWidget {
  const _EarningsTab();

  @override
  Widget build(BuildContext context) => const _SimpleTab(
        title: 'Earnings',
        subtitle: 'Artist earnings and transaction history will appear here.',
        icon: Icons.account_balance_wallet,
        details: ['Available balance: —', 'Pending earnings: —', 'Streaming royalties', 'Music sales', 'Withdrawal requests'],
      );
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) => const _SimpleTab(
        title: 'My Profile',
        subtitle: 'Manage your Nero Music account.',
        icon: Icons.person,
        details: ['Personal information', 'Artist application', 'Premium membership', 'Payment methods', 'Settings', 'Help and support'],
      );
}

class _SimpleTab extends StatelessWidget {
  const _SimpleTab({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.details,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> details;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 7),
        Text(subtitle, style: const TextStyle(color: neroMuted)),
        const SizedBox(height: 22),
        for (final item in details)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: neroSurface, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Icon(icon, color: neroPink),
                const SizedBox(width: 13),
                Expanded(child: Text(item)),
                const Icon(Icons.chevron_right, color: neroMuted),
              ],
            ),
          ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.action});

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        Text(action, style: const TextStyle(color: neroPink, fontSize: 12)),
      ],
    );
  }
}

class _MusicTile extends StatelessWidget {
  const _MusicTile({required this.title, required this.subtitle, required this.icon});

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: neroSurface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 82,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(colors: [neroRed, Color(0xFF51152F)]),
            ),
            child: Icon(icon, size: 42, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(color: neroMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: neroSurface,
      side: BorderSide.none,
      labelStyle: const TextStyle(color: Colors.white),
    );
  }
}
