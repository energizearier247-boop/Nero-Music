// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://mavtwrfjkitrgjjxgcca.supabase.co',
);
const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: 'sb_publishable_t9RNQkKcc6oNRR6wqrujgg_-xJnXC-M',
);

const neroRed = Color(0xFFED174C);
const neroPink = Color(0xFFFF4F91);
const neroDark = Color(0xFF09090D);
const neroDarkSurface = Color(0xFF15151D);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabasePublishableKey);
  runApp(const NeroMusicApp());
}

class NeroMusicApp extends StatefulWidget {
  const NeroMusicApp({super.key});

  @override
  State<NeroMusicApp> createState() => NeroMusicAppState();

  static NeroMusicAppState of(BuildContext context) =>
      context.findAncestorStateOfType<NeroMusicAppState>()!;
}

class NeroMusicAppState extends State<NeroMusicApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() => _themeMode = prefs.getBool('nero_dark_mode') == false
        ? ThemeMode.light
        : ThemeMode.dark);
  }

  Future<void> setDarkMode(bool enabled) async {
    setState(() => _themeMode = enabled ? ThemeMode.dark : ThemeMode.light);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('nero_dark_mode', enabled);
  }

  ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: neroRed,
      brightness: brightness,
      primary: neroRed,
      secondary: neroPink,
      surface: dark ? neroDarkSurface : const Color(0xFFF5F3F6),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? neroDark : const Color(0xFFFFF9FC),
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? neroDark : const Color(0xFFFFF9FC),
        foregroundColor: dark ? Colors.white : const Color(0xFF17131A),
        elevation: 0,
      ),
      cardColor: dark ? neroDarkSurface : Colors.white,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? neroDarkSurface : Colors.white,
        indicatorColor: neroRed.withValues(alpha: 0.16),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? neroDarkSurface : const Color(0xFFF1EDF2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Nero Music',
        debugShowCheckedModeBanner: false,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        themeMode: _themeMode,
        home: Supabase.instance.client.auth.currentSession == null
            ? const WelcomeScreen()
            : const NeroHomeScreen(),
      );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
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
                      gradient: const LinearGradient(colors: [neroRed, neroPink]),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: neroRed.withValues(alpha: 0.25),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.graphic_eq, size: 58, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 26),
                const Text('NERO MUSIC', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 10),
                const Text('Your Music. Your World.', textAlign: TextAlign.center,
                    style: TextStyle(color: neroPink, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Listen, store, share and earn.', textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 42),
                _PrimaryButton(label: 'GET STARTED', onPressed: () => Navigator.push(context,
                    MaterialPageRoute<void>(builder: (_) => const AccountChoiceScreen()))),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute<void>(builder: (_) => const AuthScreen(signUp: false, accountType: 'Listener'))),
                  child: const Text('SIGN IN'),
                ),
                TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute<void>(builder: (_) => const NeroHomeScreen())),
                  child: const Text('EXPLORE APP PREVIEW', style: TextStyle(color: neroPink)),
                ),
                const Spacer(),
                const Text('MUSIC CONNECTS US', textAlign: TextAlign.center,
                    style: TextStyle(letterSpacing: 2, color: neroPink)),
              ],
            ),
          ),
        ),
      );
}

class AccountChoiceScreen extends StatelessWidget {
  const AccountChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Create your account')),
        body: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const Text('How will you use Nero Music?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _MenuTile(icon: Icons.headphones, title: 'Listener', subtitle: 'Discover, save and enjoy music',
                onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const AuthScreen(signUp: true, accountType: 'Listener')))),
            _MenuTile(icon: Icons.mic, title: 'Apply as an Artist', subtitle: 'Create an artist applicant account',
                onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const AuthScreen(signUp: true, accountType: 'Artist applicant')))),
          ],
        ),
      );
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.signUp, required this.accountType});
  final bool signUp;
  final String accountType;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final auth = Supabase.instance.client.auth;
      if (widget.signUp) {
        final response = await auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'full_name': _name.text.trim(), 'account_type': widget.accountType},
        );
        if (!mounted) {
      return;
    }
        final verifiedImmediately = response.session != null;
        _message(verifiedImmediately
            ? 'Your account has been created.'
            : 'Registration submitted. Check your email to verify your account before signing in.');
        if (verifiedImmediately) {
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const NeroHomeScreen()), (_) => false);
        }
      } else {
        await auth.signInWithPassword(email: _email.text.trim(), password: _password.text);
        if (!mounted) {
      return;
    }
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const NeroHomeScreen()), (_) => false);
      }
    } on AuthException catch (error) {
      if (mounted) {
        _message(error.message);
      }
    } catch (_) {
      if (mounted) {
        _message('Unable to connect. Check your internet connection and try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _message(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      _message('Enter your email address first.');
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        _message('Password reset instructions have been sent if the account exists.');
      }
    } on AuthException catch (error) {
      if (mounted) {
        _message(error.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.signUp ? widget.accountType : 'Sign in')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Text(widget.signUp ? 'Create your account' : 'Welcome back',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 22),
              if (widget.signUp) ...[
                TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline)),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter your name' : null),
                const SizedBox(height: 14),
              ],
              TextFormField(controller: _email, keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.email_outlined)),
                  validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email address' : null),
              const SizedBox(height: 14),
              TextFormField(controller: _password, obscureText: _obscure,
                  decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _obscure = !_obscure))),
                  validator: (v) => v == null || v.length < 8 ? 'Use at least 8 characters' : null),
              if (!widget.signUp) {
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text('Forgot password?'),
                  ),
                ),
              }
              const SizedBox(height: 18),
              _PrimaryButton(label: _busy ? 'PLEASE WAIT...' : widget.signUp ? 'CREATE ACCOUNT' : 'SIGN IN',
                  onPressed: _busy ? null : _submit),
              const SizedBox(height: 12),
              Text(widget.signUp
                  ? 'Email verification may be required before your first sign-in.'
                  : 'Your account is securely managed by Supabase.',
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
}

class NeroHomeScreen extends StatefulWidget {
  const NeroHomeScreen({super.key});
  @override
  State<NeroHomeScreen> createState() => _NeroHomeScreenState();
}

class _NeroHomeScreenState extends State<NeroHomeScreen> {
  int _index = 0;
  final _titles = const ['Home', 'Explore', 'Library', 'Earnings', 'Profile'];

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomeTab(),
      _ListTab(title: 'Explore', subtitle: 'Find music, artists, albums and playlists.', items: const ['Trending music', 'New releases', 'Top artists', 'Afrobeats', 'Gospel', 'Hip-Hop', 'R&B']),
      _ListTab(title: 'My Library', subtitle: 'Your private music and saved collection.', items: const ['Private music vault', 'My uploads', 'Playlists', 'Favourites', 'Purchased music', 'Downloads']),
      _ListTab(title: 'Earnings', subtitle: 'Artist earnings and transaction history.', items: const ['Available balance', 'Pending earnings', 'Streaming royalties', 'Music sales', 'Withdrawal requests']),
      _ListTab(title: 'My Profile', subtitle: 'Manage your Nero Music account.', items: const ['Personal information', 'Artist application', 'Premium membership', 'Payment methods', 'Settings', 'Help and support']),
    ];
    return Scaffold(
      appBar: _index == 0 ? null : AppBar(title: Text(_titles[_index])),
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
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
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(children: [
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('NERO MUSIC', style: TextStyle(color: neroPink, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              SizedBox(height: 6), Text('Your sound starts here.', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
            ])),
            IconButton(onPressed: () => _open(context, 'Notifications'), icon: const Icon(Icons.notifications_none)),
          ]),
          const SizedBox(height: 18),
          TextField(readOnly: true, onTap: () => _open(context, 'Search music'), decoration: const InputDecoration(hintText: 'Search songs, albums and artists', prefixIcon: Icon(Icons.search, color: neroPink))),
          const SizedBox(height: 22),
          Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [Color(0xFFED174C), Color(0xFFFF4F91)])),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('FEEL THE MUSIC', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)), SizedBox(height: 8), Text('Discover new sounds. Support the artists you love.', style: TextStyle(color: Colors.white)), SizedBox(height: 12), Icon(Icons.graphic_eq, size: 42, color: Colors.white)])),
          const SizedBox(height: 24),
          const Text('Made for you', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: _MusicCard(title: 'Afrobeats Mix', subtitle: 'Fresh African sounds', icon: Icons.album)), const SizedBox(width: 12), Expanded(child: _MusicCard(title: 'Late Night', subtitle: 'R&B and chill', icon: Icons.nightlight_round))]),
          const SizedBox(height: 22),
          const Text('Explore genres', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          Wrap(spacing: 8, children: ['Afrobeats', 'Gospel', 'Hip-Hop', 'R&B', 'Pop', 'Highlife'].map((g) => ActionChip(label: Text(g), onPressed: () => _open(context, g))).toList()),
          const SizedBox(height: 20),
          _MenuTile(icon: Icons.mic, title: 'Artist opportunities', subtitle: 'Apply to publish music and earn', onTap: () => _open(context, 'Artist application')),
        ],
      );
}

class _ListTab extends StatelessWidget {
  const _ListTab({required this.title, required this.subtitle, required this.items});
  final String title;
  final String subtitle;
  final List<String> items;
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    Text(title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
    const SizedBox(height: 7), Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    const SizedBox(height: 22),
    for (final item in items) _MenuTile(icon: title == 'Explore' ? Icons.explore : title == 'My Library' ? Icons.library_music : title == 'Earnings' ? Icons.account_balance_wallet : Icons.person, title: item, onTap: () { if (item == 'Settings') { Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SettingsScreen())); } else { _open(context, item); } }),
  ]);
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.title, this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 12), child: ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
    leading: Icon(icon, color: neroPink), title: Text(title), subtitle: subtitle == null ? null : Text(subtitle!),
    trailing: const Icon(Icons.chevron_right), onTap: onTap,
  ));
}

class _MusicCard extends StatelessWidget {
  const _MusicCard({required this.title, required this.subtitle, required this.icon});
  final String title;
  final String subtitle;
  final IconData icon;
  @override
  Widget build(BuildContext context) => InkWell(onTap: () => _open(context, title), child: Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(height: 85, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [neroRed, neroPink])), child: Icon(icon, color: Colors.white, size: 40)),
    const SizedBox(height: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
  ]))));
}

void _open(BuildContext context, String title) {
  Navigator.push(context, MaterialPageRoute<void>(builder: (_) => DetailScreen(title: title)));
}

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(title)), body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.graphic_eq, color: neroPink, size: 52), const SizedBox(height: 14), Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8), const Text('This section will be activated as its Stage 2 feature is connected.'),
  ]))));
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = NeroMusicApp.of(context);
    return Scaffold(appBar: AppBar(title: const Text('Settings')), body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Appearance', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      SwitchListTile(value: Theme.of(context).brightness == Brightness.dark, activeThumbColor: neroPink, title: const Text('Dark mode'), subtitle: const Text('Turn dark appearance on or off'), onChanged: app.setDarkMode),
      const Divider(),
      ListTile(leading: const Icon(Icons.logout, color: neroPink), title: const Text('Sign out'), onTap: () async {
        await Supabase.instance.client.auth.signOut();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
            (_) => false,
          );
        }
      }),
    ]));
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(height: 54, child: FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(backgroundColor: neroRed, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
  ));
}
