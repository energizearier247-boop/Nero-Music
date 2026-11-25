// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
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
const neroAuthRedirectUrl = 'com.neromusic://login-callback';

/// Root messenger key for notifications that must be shown after async work.
final GlobalKey<ScaffoldMessengerState> neroScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Allows authentication flows to navigate after async work without using a
/// BuildContext that may no longer be mounted.
final GlobalKey<NavigatorState> neroNavigatorKey = GlobalKey<NavigatorState>();

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
  late final StreamSubscription<AuthState> _authSubscription;
  Session? _session;
  bool _passwordRecovery = false;
  bool _showSignInAfterVerification = false;
  bool _verificationRedirectInProgress = false;

  @override
  void initState() {
    super.initState();
    _session = Supabase.instance.client.auth.currentSession;
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange
        .listen(_handleAuthState);
    _restorePendingVerification();
    _loadTheme();
  }

  Future<void> _restorePendingVerification() async {
    final prefs = await SharedPreferences.getInstance();
    final pending =
        prefs.getBool('nero_pending_email_verification') ?? false;
    if (pending && Supabase.instance.client.auth.currentSession != null) {
      await _redirectToSignInAfterVerification();
    }
  }

  Future<void> _handleAuthState(AuthState state) async {
    if (state.session != null) {
      final prefs = await SharedPreferences.getInstance();
      final pending =
          prefs.getBool('nero_pending_email_verification') ?? false;
      if (pending) {
        await _redirectToSignInAfterVerification();
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _session = state.session;
      _passwordRecovery = state.event == AuthChangeEvent.passwordRecovery;
    });
  }

  Future<void> _redirectToSignInAfterVerification() async {
    if (_verificationRedirectInProgress) return;
    _verificationRedirectInProgress = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('nero_pending_email_verification');
      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;
      setState(() {
        _session = null;
        _passwordRecovery = false;
        _showSignInAfterVerification = true;
      });

      // Replace the complete navigation stack. This prevents the Android
      // back button from returning to Create Account or the verification flow.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        neroNavigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) =>
                const AuthScreen(signUp: false, accountType: 'Listener'),
          ),
          (_) => false,
        );
      });
    } finally {
      _verificationRedirectInProgress = false;
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
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
        scaffoldMessengerKey: neroScaffoldMessengerKey,
        navigatorKey: neroNavigatorKey,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        themeMode: _themeMode,
        home: _passwordRecovery
            ? const PasswordUpdateScreen()
            : _showSignInAfterVerification
                ? const AuthScreen(signUp: false, accountType: 'Listener')
                : _session == null
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
        final prefs = await SharedPreferences.getInstance();
        final response = await auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          emailRedirectTo: neroAuthRedirectUrl,
          data: {'full_name': _name.text.trim(), 'account_type': widget.accountType},
        );
        if (!mounted) {
      return;
    }
        final verifiedImmediately = response.session != null;
        if (verifiedImmediately) {
          await prefs.remove('nero_pending_email_verification');
        } else {
          await prefs.setBool('nero_pending_email_verification', true);
        }
        if (!mounted) return;
        _message(verifiedImmediately
            ? 'Your account has been created.'
            : 'Registration submitted. Check your email to verify your account before signing in.');
        if (verifiedImmediately) {
          neroNavigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const NeroHomeScreen()), (_) => false);
        }
      } else {
        await auth.signInWithPassword(email: _email.text.trim(), password: _password.text);
        if (!mounted) {
      return;
    }
        neroNavigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const NeroHomeScreen()), (_) => false);
      }
    } on AuthException catch (error) {
      if (widget.signUp) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('nero_pending_email_verification');
      }
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

  void _message(String value) {
    neroScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      _message('Enter your email address first.');
      return;
    }

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: neroAuthRedirectUrl,
      );
      if (!mounted) return;
      neroScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset instructions have been sent if the account exists.',
          ),
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      neroScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      neroScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Unable to send reset instructions. Please try again.'),
        ),
      );
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
              if (!widget.signUp)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text('Forgot password?'),
                  ),
                ),
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


class PasswordUpdateScreen extends StatefulWidget {
  const PasswordUpdateScreen({super.key});

  @override
  State<PasswordUpdateScreen> createState() => _PasswordUpdateScreenState();
}

class _PasswordUpdateScreenState extends State<PasswordUpdateScreen> {
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    final password = _password.text;
    if (password.length < 8) {
      _message('Use at least 8 characters for your new password.');
      return;
    }
    if (password != _confirmPassword.text) {
      _message('The passwords do not match.');
      return;
    }

    setState(() => _busy = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );
      if (!mounted) return;
      _message('Your password has been updated.');
    } on AuthException catch (error) {
      if (mounted) _message(error.message);
    } catch (_) {
      if (mounted) {
        _message('Unable to update your password. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String value) {
    neroScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Create a new password')),
        body: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const Text(
              'Choose a new password for your Nero Music account.',
              style: TextStyle(fontSize: 17),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _confirmPassword,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Confirm new password'),
            ),
            const SizedBox(height: 22),
            _PrimaryButton(
              label: _busy ? 'PLEASE WAIT...' : 'UPDATE PASSWORD',
              onPressed: _busy ? null : _savePassword,
            ),
          ],
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
      const SearchScreen(),
      _ListTab(title: 'My Library', subtitle: 'Your private music and saved collection.', items: const ['Private music vault', 'My uploads', 'Playlists', 'Favourites', 'Purchased music', 'Downloads']),
      _ListTab(title: 'Earnings', subtitle: 'Artist earnings and transaction history.', items: const ['Available balance', 'Pending earnings', 'Streaming royalties', 'Music sales', 'Withdrawal requests']),
      const _ProfileTab(),
    ];
    return Scaffold(
      appBar: _index == 0 || _index == 1 ? null : AppBar(title: Text(_titles[_index])),
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
          TextField(
            readOnly: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
            ),
            decoration: const InputDecoration(
              hintText: 'Search songs, albums and artists',
              prefixIcon: Icon(Icons.search, color: neroPink),
            ),
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              height: 390,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/nero_music_banner.webp',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          neroDark.withValues(alpha: 0.04),
                          neroDark.withValues(alpha: 0.78),
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 18,
                    right: 18,
                    bottom: 86,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FEEL THE MUSIC',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Discover new sounds. Support the artists you love.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 18,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _BannerControl(
                          icon: Icons.skip_previous_rounded,
                          label: 'Previous',
                          onPressed: () => _open(context, 'Previous featured mix'),
                        ),
                        _BannerControl(
                          icon: Icons.play_arrow_rounded,
                          label: 'Play',
                          prominent: true,
                          onPressed: () => _open(context, 'Featured music'),
                        ),
                        _BannerControl(
                          icon: Icons.skip_next_rounded,
                          label: 'Next',
                          onPressed: () => _open(context, 'Next featured mix'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Made for you', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MusicCard(
                  title: 'Afrobeats Mix',
                  subtitle: 'Fresh African sounds',
                  icon: Icons.album,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MusicCard(
                  title: 'Late Night',
                  subtitle: 'R&B and chill',
                  icon: Icons.nightlight_round,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text('Explore genres', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          Wrap(spacing: 8, children: ['Afrobeats', 'Gospel', 'Hip-Hop', 'R&B', 'Pop', 'Highlife'].map((g) => ActionChip(label: Text(g), onPressed: () => _open(context, g))).toList()),
          const SizedBox(height: 20),
          _MenuTile(icon: Icons.mic, title: 'Artist opportunities', subtitle: 'Apply to publish music and earn', onTap: () => _open(context, 'Artist application')),
        ],
      );
}


class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _query = TextEditingController();
  final AudioPlayer _player = AudioPlayer();
  List<Map<String, dynamic>> _songs = [];
  List<Map<String, dynamic>> _artists = [];
  bool _loading = false;
  String? _error;
  String? _playingUrl;

  @override
  void initState() {
    super.initState();
    _query.text = 'top hits';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_search('top hits'));
    });
  }

  @override
  void dispose() {
    _query.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _itunesSearch(
    String term, String entity,
  ) async {
    final uri = Uri.https('itunes.apple.com', '/search', {
      'term': term,
      'entity': entity,
      'limit': entity == 'song' ? '30' : '12',
      'media': 'music',
    });
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 15));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(const Duration(seconds: 15));
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Music search returned ${response.statusCode}.');
      }
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final results = decoded['results'] as List<dynamic>? ?? const [];
      return results.whereType<Map<String, dynamic>>().toList();
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _search([String? value]) async {
    final term = (value ?? _query.text).trim();
    if (term.isEmpty) {
      setState(() {
        _songs = [];
        _artists = [];
        _error = null;
      });
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _songs = [];
      _artists = [];
    });
    try {
      final results = await Future.wait([
        _itunesSearch(term, 'song'),
        _itunesSearch(term, 'musicArtist'),
      ]);
      if (!mounted) return;
      setState(() {
        _songs = results[0].where((song) => song['previewUrl'] != null).toList();
        _artists = results[1];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not search music right now. Check your internet connection and try again.';
      });
    }
  }

  Future<void> _playSong(Map<String, dynamic> song) async {
    final url = song['previewUrl'] as String?;
    if (url == null || url.isEmpty) return;
    try {
      if (_playingUrl == url && _player.playing) {
        await _player.pause();
        if (mounted) setState(() {});
        return;
      }
      await _player.setUrl(url);
      if (mounted) setState(() => _playingUrl = url);
      unawaited(_player.play());
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This preview could not be played. Please try another track.')),
      );
    }
  }

  Widget _artwork(String? url, {double size = 54}) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: url == null
        ? Container(width: size, height: size, color: neroDarkSurface,
            child: const Icon(Icons.music_note, color: neroPink))
        : Image.network(url, width: size, height: size, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(width: size, height: size,
              color: neroDarkSurface, child: const Icon(Icons.music_note, color: neroPink))),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Discover music')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: _query,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: _search,
          decoration: InputDecoration(
            hintText: 'Search songs or artists worldwide',
            prefixIcon: const Icon(Icons.search, color: neroPink),
            suffixIcon: IconButton(
              tooltip: 'Search',
              onPressed: _loading ? null : () => _search(),
              icon: const Icon(Icons.arrow_forward, color: neroPink),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (_loading) const Center(child: Padding(
          padding: EdgeInsets.all(28), child: CircularProgressIndicator(),
        )),
        if (_error != null) Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
        if (!_loading && _artists.isNotEmpty) ...[
          const Text('Artists', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _artists.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final artist = _artists[index];
                return SizedBox(width: 92, child: Column(children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: neroDarkSurface,
                    backgroundImage: _songs.where((song) => song['artistName'] == artist['artistName'] && song['artworkUrl100'] != null).isNotEmpty
                      ? NetworkImage(_songs.firstWhere((song) => song['artistName'] == artist['artistName'] && song['artworkUrl100'] != null)['artworkUrl100'] as String)
                      : null,
                    child: _songs.where((song) => song['artistName'] == artist['artistName'] && song['artworkUrl100'] != null).isEmpty
                      ? const Icon(Icons.person, color: neroPink, size: 34) : null,
                  ),
                  const SizedBox(height: 7),
                  Text(artist['artistName']?.toString() ?? 'Artist',
                    maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ]));
              },
            ),
          ),
        ],
        if (!_loading && _songs.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text('Songs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final song in _songs)
            Card(child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              leading: _artwork(song['artworkUrl100'] as String?),
              title: Text(song['trackName']?.toString() ?? 'Unknown track', maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(song['artistName']?.toString() ?? 'Unknown artist', maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                tooltip: _playingUrl == song['previewUrl'] && _player.playing ? 'Pause preview' : 'Play preview',
                icon: Icon(_playingUrl == song['previewUrl'] && _player.playing
                  ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  color: neroPink, size: 34),
                onPressed: () => _playSong(song),
              ),
            )),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Play buttons stream the available track preview. Full-length playback depends on a licensed music-streaming provider.',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ],
        if (!_loading && _query.text.trim().isNotEmpty && _songs.isEmpty && _artists.isEmpty && _error == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Text('No matching songs or artists found. Try another spelling or search term.', textAlign: TextAlign.center),
          ),
        if (!_loading && _query.text.trim().isEmpty) ...[
          const Text('Start exploring', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            'Afrobeats', 'Gospel', 'Hip-Hop', 'R&B', 'Pop', 'Highlife',
          ].map((genre) => ActionChip(
            label: Text(genre),
            onPressed: () { _query.text = genre; _search(genre); },
          )).toList()),
        ],
      ],
    ),
  );
}

class _BannerControl extends StatelessWidget {
  const _BannerControl({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.prominent = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool prominent;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: prominent ? neroRed : Colors.black.withValues(alpha: 0.48),
            shape: const CircleBorder(),
            child: IconButton(
              onPressed: onPressed,
              color: Colors.white,
              iconSize: prominent ? 34 : 27,
              icon: Icon(icon),
              tooltip: label,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
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


class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                SizedBox(
                  height: 230,
                  width: double.infinity,
                  child: Image.asset(
                    'assets/nero_profile_photo.jpg',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.12),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        neroDark.withValues(alpha: 0.88),
                      ],
                    ),
                  ),
                  child: const Text(
                    'YOUR NERO MUSIC SPACE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'My Profile',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          for (final item in const [
            'Personal information',
            'Artist application',
            'Premium membership',
            'Payment methods',
            'Settings',
            'Help and support',
          ])
            _MenuTile(
              icon: item == 'Settings' ? Icons.settings : Icons.person,
              title: item,
              onTap: () {
                if (item == 'Settings') {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                } else {
                  _open(context, item);
                }
              },
            ),
        ],
      );
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
    Container(height: 85, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [neroRed, neroPink])), child: Icon(icon, color: Colors.white, size: 25)),
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
    const SizedBox(height: 8), const Text('Explore this Nero Music section. More features will appear here as they become available.'),
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
