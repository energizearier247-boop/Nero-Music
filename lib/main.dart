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

    if (!mounted) {
      return;
    }
    setState(() {
      _session = state.session;
      _passwordRecovery = state.event == AuthChangeEvent.passwordRecovery;
    });
  }

  Future<void> _redirectToSignInAfterVerification() async {
    if (_verificationRedirectInProgress) {
      return;
    }
    _verificationRedirectInProgress = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('nero_pending_email_verification');
      await Supabase.instance.client.auth.signOut();

      if (!mounted) {
        return;
      }
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
    if (!_formKey.currentState!.validate()) {
      return;
    }
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
        if (!mounted) {
          return;
        }
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
      if (!mounted) {
        return;
      }
      neroScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset instructions have been sent if the account exists.',
          ),
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      neroScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
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
      if (!mounted) {
        return;
      }
      _message('Your password has been updated.');
    } on AuthException catch (error) {
      if (mounted) {
        _message(error.message);
      }
    } catch (_) {
      if (mounted) {
        _message('Unable to update your password. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
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
      const LibraryScreen(),
      const _OwnerEarningsTab(),
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

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final AudioPlayer _bannerPlayer = AudioPlayer();
  List<Map<String, dynamic>> _featuredTracks = [];
  int _featuredIndex = 0;
  bool _featuredLoading = false;
  bool _bannerPlaying = false;
  String? _loadedFeaturedUrl;
  StreamSubscription<PlayerState>? _bannerStateSubscription;

  Map<String, dynamic>? get _currentFeatured =>
      _featuredTracks.isEmpty ? null : _featuredTracks[_featuredIndex];

  @override
  void initState() {
    super.initState();
    unawaited(_loadFeaturedTracks());
    _bannerStateSubscription = _bannerPlayer.playerStateStream.listen((state) {
      if (mounted) setState(() => _bannerPlaying = state.playing);
    });
  }

  @override
  void dispose() {
    _bannerStateSubscription?.cancel();
    _bannerPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadFeaturedTracks() async {
    setState(() => _featuredLoading = true);
    final client = HttpClient();
    try {
      final uri = Uri.https('itunes.apple.com', '/search', {
        'term': 'Afrobeats hits',
        'entity': 'song',
        'limit': '25',
        'media': 'music',
      });
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 15));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(const Duration(seconds: 15));
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Featured music returned ${response.statusCode}.');
      }
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final results = decoded['results'] as List<dynamic>? ?? const [];
      final tracks = results
          .whereType<Map<String, dynamic>>()
          .where((track) => track['previewUrl'] is String)
          .toList();
      if (mounted) {
        setState(() {
          _featuredTracks = tracks;
          _featuredLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _featuredLoading = false);
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _playFeatured({bool toggle = false, int? targetIndex}) async {
    if (_featuredTracks.isEmpty) {
      if (_featuredLoading) return;
      await _loadFeaturedTracks();
      if (_featuredTracks.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Featured music is unavailable right now. Try again shortly.')),
          );
        }
        return;
      }
    }

    if (targetIndex != null) {
      _featuredIndex = (targetIndex + _featuredTracks.length) % _featuredTracks.length;
    }
    final track = _currentFeatured!;
    final url = track['previewUrl'] as String?;
    if (url == null || url.isEmpty) return;

    try {
      if (toggle && _loadedFeaturedUrl == url) {
        if (_bannerPlaying) {
          await _bannerPlayer.pause();
        } else {
          unawaited(_bannerPlayer.play());
        }
        return;
      }
      await _bannerPlayer.setUrl(url);
      _loadedFeaturedUrl = url;
      if (mounted) setState(() {});
      unawaited(_bannerPlayer.play());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not play this featured preview.')),
        );
      }
    }
  }

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
            onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SearchScreen())),
            decoration: const InputDecoration(hintText: 'Search songs, albums and artists', prefixIcon: Icon(Icons.search, color: neroPink)),
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
                  Image.asset('assets/nero_music_banner.webp', fit: BoxFit.cover, alignment: Alignment.topCenter),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [neroDark.withValues(alpha: 0.04), neroDark.withValues(alpha: 0.82)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 86,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentFeatured?['trackName']?.toString().toUpperCase() ?? 'FEEL THE MUSIC',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _currentFeatured?['artistName']?.toString() ?? 'Discover new sounds. Support the artists you love.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                        if (_featuredLoading) const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
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
                          onPressed: () => unawaited(_playFeatured(targetIndex: _featuredIndex - 1)),
                        ),
                        _BannerControl(
                          icon: _bannerPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          label: _bannerPlaying ? 'Pause' : 'Play',
                          prominent: true,
                          onPressed: () => unawaited(_playFeatured(toggle: true)),
                        ),
                        _BannerControl(
                          icon: Icons.skip_next_rounded,
                          label: 'Next',
                          onPressed: () => unawaited(_playFeatured(targetIndex: _featuredIndex + 1)),
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
          Row(children: [
            Expanded(child: _MusicCard(title: 'Afro-beats', subtitle: 'Fresh African sounds', imagePath: 'assets/afrobeats_stage.jpg', onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SearchScreen(initialQuery: 'Afrobeats'))))),
            const SizedBox(width: 12),
            Expanded(child: _MusicCard(title: 'Late Night', subtitle: 'R&B and chill', imagePath: 'assets/late_night_studio.jpg', onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SearchScreen(initialQuery: 'Late Night R&B'))))),
          ]),
          const SizedBox(height: 22),
          const Text('Explore genres', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: ['Afrobeats', 'Gospel', 'Hip-Hop', 'R&B', 'Pop', 'Highlife']
                .map((g) => ActionChip(
                      label: Text(g),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => SearchScreen(initialQuery: g),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          _MenuTile(icon: Icons.mic, title: 'Artist opportunities', subtitle: 'Apply to publish music and earn', onTap: () => _open(context, 'Artist application')),
        ],
      );
}


class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery = 'top hits'});
  final String initialQuery;

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
    _query.text = widget.initialQuery;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_search(widget.initialQuery));
      }
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
      if (!mounted) {
        return;
      }
      setState(() {
        _songs = results[0].where((song) => song['previewUrl'] != null).toList();
        _artists = results[1];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = 'Could not search music right now. Check your internet connection and try again.';
      });
    }
  }

  Future<void> _playSong(Map<String, dynamic> song) async {
    final url = song['previewUrl'] as String?;
    if (url == null || url.isEmpty) {
      return;
    }
    try {
      if (_playingUrl == url && _player.playing) {
        await _player.pause();
        if (mounted) {
          setState(() {});
        }
        return;
      }
      await _player.setUrl(url);
      if (mounted) {
        setState(() {
          _playingUrl = url;
        });
      }
      unawaited(_player.play());
    } catch (_) {
      if (!mounted) {
        return;
      }
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
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: neroPink),
                onSelected: (action) async {
                  if (action == 'play') { await _playSong(song); return; }
                  final result = await LibraryStore.add(action, song);
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'play', child: Text('Play preview')),
                  PopupMenuItem(value: 'Private Music Vault', child: Text('Save to Private Vault')),
                  PopupMenuItem(value: 'Favourites', child: Text('Add to Favourites')),
                  PopupMenuItem(value: 'Downloads', child: Text('Add to Downloads list')),
                  PopupMenuItem(value: 'Purchased Music', child: Text('Add to Purchased list')),
                ],
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

class LibraryStore {
  static const _key = 'nero_library_collections_v1';
  static const sections = <String>[
    'Private Music Vault', 'My Uploads', 'Playlists', 'Favourites',
    'Purchased Music', 'Downloads',
  ];

  static Future<Map<String, List<Map<String, dynamic>>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) {
      return {
        for (final section in sections) section: <Map<String, dynamic>>[],
      };
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final section in sections)
          section: ((decoded[section] as List<dynamic>?) ?? const [])
              .whereType<Map<String, dynamic>>()
              .map((entry) => Map<String, dynamic>.from(entry)).toList(),
      };
    } catch (_) {
      return {for (final section in sections) section: <Map<String, dynamic>>[]};
    }
  }

  static Future<String> add(String section, Map<String, dynamic> song) async {
    final data = await load();
    final items = data[section] ?? <Map<String, dynamic>>[];
    final id = song['trackId']?.toString() ?? song['trackName']?.toString() ?? '';
    if (items.any((item) => (item['trackId']?.toString() ?? item['trackName']?.toString()) == id)) {
      return 'This track is already in $section.';
    }
    items.add({
      'trackId': song['trackId'],
      'trackName': song['trackName']?.toString() ?? 'Untitled track',
      'artistName': song['artistName']?.toString() ?? 'Unknown artist',
      'artworkUrl100': song['artworkUrl100'],
      'previewUrl': song['previewUrl'],
      'savedAt': DateTime.now().toIso8601String(),
    });
    data[section] = items;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data));
    return 'Saved to $section.';
  }

  static Future<void> remove(String section, Map<String, dynamic> item) async {
    final data = await load();
    data[section]?.removeWhere((entry) => entry['savedAt'] == item['savedAt']);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data));
  }

  static Future<String> addPlaylist(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) {
      return 'Enter a playlist name.';
    }
    final data = await load();
    final playlists = data['Playlists']!;
    if (playlists.any((item) => item['trackName'] == clean)) {
      return 'That playlist already exists.';
    }
    playlists.add({'trackName': clean, 'artistName': 'Playlist', 'savedAt': DateTime.now().toIso8601String(), 'isPlaylist': true});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data));
    return 'Playlist created.';
  }
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _section = LibraryStore.sections.first;
  Future<Map<String, List<Map<String, dynamic>>>>? _future;
  @override
  void initState() { super.initState(); _future = LibraryStore.load(); }
  void _refresh() => setState(() => _future = LibraryStore.load());

  Future<void> _createPlaylist() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('New playlist'),
      content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Playlist name')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Create'))],
    ));
    controller.dispose();
    if (name == null) {
      return;
    }
    final message = await LibraryStore.addPlaylist(name);
    if (!mounted) {
      return;
    }
    _refresh();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addUpload() async {
    final title = TextEditingController();
    final artist = TextEditingController();
    final values = await showDialog<List<String>>(context: context, builder: (context) => AlertDialog(
      title: const Text('Add upload details'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: title, decoration: const InputDecoration(labelText: 'Track title')),
        TextField(controller: artist, decoration: const InputDecoration(labelText: 'Artist')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(context, [title.text, artist.text]), child: const Text('Save'))],
    ));
    if (values == null || values.first.trim().isEmpty) {
      return;
    }
    final result = await LibraryStore.add('My Uploads', {'trackName': values.first.trim(), 'artistName': values[1].trim().isEmpty ? 'Unknown artist' : values[1].trim(), 'savedAt': DateTime.now().toIso8601String()});
    if (!mounted) {
      return;
    }
    _refresh();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
    future: _future,
    builder: (context, snapshot) {
      final data = snapshot.data ?? {for (final section in LibraryStore.sections) section: <Map<String, dynamic>>[]};
      final items = data[_section] ?? <Map<String, dynamic>>[];
      return ListView(padding: const EdgeInsets.all(18), children: [
        const Text('Your Library', style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text('Your music, kept together on this device.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final section in LibraryStore.sections) ChoiceChip(
          label: Text(section), selected: _section == section, onSelected: (_) => setState(() => _section = section),
        )]),
        const SizedBox(height: 16),
        if (_section == 'Playlists') Align(alignment: Alignment.centerLeft, child: FilledButton.icon(onPressed: _createPlaylist, icon: const Icon(Icons.add), label: const Text('Create playlist'))),
        if (_section == 'My Uploads') Align(alignment: Alignment.centerLeft, child: FilledButton.icon(onPressed: _addUpload, icon: const Icon(Icons.add), label: const Text('Add upload details'))),
        const SizedBox(height: 10),
        if (snapshot.connectionState == ConnectionState.waiting) const Center(child: CircularProgressIndicator()),
        if (items.isEmpty && snapshot.connectionState != ConnectionState.waiting) Padding(
          padding: const EdgeInsets.symmetric(vertical: 28), child: Column(children: [
            Icon(Icons.library_music_outlined, size: 42, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 10), Text(_section == 'My Uploads' ? 'Add your track details to start your uploads list.' : _section == 'Playlists' ? 'Create a playlist to organize your music.' : 'No items saved here yet.', textAlign: TextAlign.center),
            if (_section == 'Purchased Music' || _section == 'Downloads') const Padding(padding: EdgeInsets.only(top: 8), child: Text('This list stores track details. It does not purchase or download audio files.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey))),
          ]),
        ),
        for (final item in items) Card(child: ListTile(
          leading: item['artworkUrl100'] is String ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(item['artworkUrl100'] as String, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.music_note))) : const Icon(Icons.music_note, color: neroPink),
          title: Text(item['trackName']?.toString() ?? 'Untitled'),
          subtitle: Text(item['artistName']?.toString() ?? ''),
          trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () async { await LibraryStore.remove(_section, item); _refresh(); }),
        )),
      ]);
    },
  );
}

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _busy = false;
  String? _message;

  Future<void> _startCheckout() async {
    if (Supabase.instance.client.auth.currentUser == null) {
      setState(() => _message = 'Please sign in before subscribing.');
      return;
    }
    setState(() { _busy = true; _message = null; });
    try {
      // The secure Edge Function must be deployed and configured with Paystack
      // secret keys before checkout can be enabled in production.
      final response = await Supabase.instance.client.functions.invoke(
        'create-subscription-checkout',
        body: {'plan': 'listener_monthly', 'amount_kobo': 200000},
      );
      final data = response.data;
      if (data is Map && data['checkout_url'] is String) {
        setState(() => _message =
            'Checkout is ready. Open this link in your browser: ${data['checkout_url']}');
      } else {
        setState(() => _message =
            'Payment setup is not complete yet. No payment has been taken.');
      }
    } catch (_) {
      setState(() => _message =
          'Could not start checkout. Please try again later. No payment has been taken.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nero Music Premium')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [neroRed, neroPink]),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.headphones, color: Colors.white, size: 34),
          SizedBox(height: 18),
          Text('LISTENER MONTHLY', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          SizedBox(height: 8),
          Text('₦2,000 / month', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          SizedBox(height: 8),
          Text('Stream music with a monthly membership.', style: TextStyle(color: Colors.white)),
        ]),
      ),
      const SizedBox(height: 22),
      const Text('Your membership', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      const ListTile(leading: Icon(Icons.check_circle_outline, color: neroPink), title: Text('Monthly access to listener streaming')),
      const ListTile(leading: Icon(Icons.check_circle_outline, color: neroPink), title: Text('Secure payment confirmation')),
      const ListTile(leading: Icon(Icons.check_circle_outline, color: neroPink), title: Text('Manage renewal and cancellation')),
      const SizedBox(height: 14),
      FilledButton(
        onPressed: _busy ? null : _startCheckout,
        child: Text(_busy ? 'Preparing checkout…' : 'Subscribe for ₦2,000/month'),
      ),
      if (_message != null) ...[
        const SizedBox(height: 14),
        SelectableText(_message!, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
      const SizedBox(height: 12),
      const Text('Subscription billing will only begin after secure checkout and payment verification are configured.', style: TextStyle(fontSize: 12, color: Colors.grey)),
    ]),
  );
}

class _OwnerEarningsTab extends StatelessWidget {
  const _OwnerEarningsTab();

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
    const Text('Owner Earnings', style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
    const SizedBox(height: 6),
    Text('Subscription revenue collected by Nero Music.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    const SizedBox(height: 22),
    Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Total subscription revenue', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      const Text('₦0.00', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      const Text('Revenue will appear here after verified payments are connected.', style: TextStyle(fontSize: 12, color: Colors.grey)),
    ]))),
    const SizedBox(height: 14),
    const Card(child: ListTile(leading: Icon(Icons.receipt_long, color: neroPink), title: Text('Payment records'), subtitle: Text('Verified subscription transactions'))),
    const Card(child: ListTile(leading: Icon(Icons.autorenew, color: neroPink), title: Text('Active subscriptions'), subtitle: Text('Current paid memberships'))),
    const Card(child: ListTile(leading: Icon(Icons.pending_actions, color: neroPink), title: Text('Renewals and cancellations'), subtitle: Text('Subscription status and billing events'))),
    const SizedBox(height: 8),
    const Text('Owner totals must be populated from verified payment webhooks, not from play counts. The secure backend and owner-only access rules are required before this dashboard can show live financial data.', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
  const _MusicCard({required this.title, required this.subtitle, required this.imagePath, required this.onTap});
  final String title;
  final String subtitle;
  final String imagePath;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: onTap,
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: 116, width: double.infinity,
          child: Image.asset(imagePath, fit: BoxFit.cover, alignment: Alignment.center),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      ]),
    ),
  );
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
