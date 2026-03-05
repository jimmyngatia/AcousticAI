import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'results_page.dart';

void main() {
  runApp(const AcousticAIApp());
}

class AcousticAIApp extends StatelessWidget {
  const AcousticAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Acoustic AI',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFEF4444),
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFEF4444),
          surface: Color(0xFF1E1E1E),
          secondary: Colors.blueAccent,
        ),
      ),
      home: const MobileWrapper(child: WelcomeScreen()),
    );
  }
}

// ─────────────────────────── MOBILE WRAPPER ───────────────────────────

class MobileWrapper extends StatelessWidget {
  final Widget child;
  const MobileWrapper({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          decoration: const BoxDecoration(
            border: Border.symmetric(
              vertical: BorderSide(color: Colors.white10, width: 0.5),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────── WELCOME SCREEN ───────────────────────────

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.settings_voice_rounded,
                size: 80,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "Respiratory Health AI",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              "Analyze lung sounds to detect symptoms using AI-driven acoustic biomarkers.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const MobileWrapper(child: RecorderScreen()),
                  ),
                ),
                child: const Text(
                  "Start Analysis",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── RECORDER SCREEN ───────────────────────────

class RecorderScreen extends StatefulWidget {
  const RecorderScreen({super.key});

  @override
  State<RecorderScreen> createState() => _RecorderScreenState();
}

// Explicit state machine — eliminates the boolean race condition that caused
// the recorder to keep running after the stop button was tapped.
enum _RecState { idle, starting, recording, stopping, done }

class _RecorderScreenState extends State<RecorderScreen> {
  AudioRecorder? _recorder;
  _RecState _state = _RecState.idle;
  int _seconds = 0;
  String? _audioPath;
  Timer? _clockTimer;
  Timer? _waveTimer;
  final List<double> _waves = List.generate(20, (_) => 5.0);
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _waveTimer?.cancel();
    _recorder?.dispose();
    super.dispose();
  }

  // ── timers ────────────────────────────────────────────────────────────

  void _startTimers() {
    _clockTimer?.cancel();
    _waveTimer?.cancel();

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
    _waveTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (mounted) {
        setState(() {
          for (int i = 0; i < _waves.length; i++) {
            _waves[i] = 6.0 + _rng.nextDouble() * 44;
          }
        });
      }
    });
  }

  void _stopTimers() {
    _clockTimer?.cancel();
    _waveTimer?.cancel();
  }

  // ── tap handler ───────────────────────────────────────────────────────

  Future<void> _onButtonTap() async {
    if (_state == _RecState.starting || _state == _RecState.stopping) return;
    if (_state == _RecState.recording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  // ── start recording ───────────────────────────────────────────────────

  Future<void> _startRecording() async {
    setState(() => _state = _RecState.starting);

    await _recorder?.dispose();
    _recorder = AudioRecorder();

    final granted = await _recorder!.hasPermission();
    if (!granted) {
      if (mounted) setState(() => _state = _RecState.idle);
      _showError(
        "Microphone permission denied.\n"
        "Click the lock icon in the address bar and allow microphone access.",
      );
      return;
    }

    const config = RecordConfig(
      encoder: AudioEncoder.wav,
      sampleRate: 16000,
      numChannels: 1,
    );

    final String path;
    if (kIsWeb) {
      path = ''; // ignored on web — record package returns a blob URL
    } else {
      final dir = await getTemporaryDirectory();
      path = '${dir.path}/lung_${DateTime.now().millisecondsSinceEpoch}.wav';
    }

    try {
      await _recorder!.start(config, path: path);
    } catch (e) {
      debugPrint("start() error: $e");
      if (mounted) setState(() => _state = _RecState.idle);
      _showError(
        "Could not start microphone.\n"
        "Try: flutter run -d chrome --web-browser-flag \"--disable-web-security\"",
      );
      return;
    }

    await Future.delayed(const Duration(milliseconds: 400));

    final active = await _recorder!.isRecording();
    if (!active) {
      if (mounted) setState(() => _state = _RecState.idle);
      _showError("Recorder failed to become active. Try refreshing.");
      return;
    }

    if (mounted) {
      setState(() {
        _state = _RecState.recording;
        _seconds = 0;
      });
      _startTimers();
    }
  }

  // ── stop recording ────────────────────────────────────────────────────
  //
  // THE KEY FIX:
  //   1. Immediately transition to `stopping` state — UI freezes at once.
  //   2. Cancel timers immediately — waveform and clock stop.
  //   3. Await recorder.stop() — this is what was previously racing the dialog.
  //   4. Navigate only after stop() completes.

  Future<void> _stopRecording() async {
    // 1. Freeze UI immediately
    setState(() => _state = _RecState.stopping);
    _stopTimers();
    if (mounted) setState(() => _waves.fillRange(0, _waves.length, 5.0));

    // 2. Stop the recorder.
    //    On web, recorder.stop() can hang indefinitely if the browser never
    //    resolves the underlying MediaRecorder.stop() promise.
    //    We race it against a 3-second fallback so we always make progress.
    final recorderRef = _recorder; // capture before possible reassignment
    await Future.any([
      Future(() async {
        try {
          final result = await recorderRef?.stop();
          debugPrint("Recording saved: $result");
          if (mounted) setState(() => _audioPath = result);
        } catch (e) {
          debugPrint("stop() error (non-fatal): $e");
        }
      }),
      Future.delayed(const Duration(seconds: 3), () {
        debugPrint("stop() fallback timer fired — proceeding anyway");
      }),
    ]);

    // 3. Show Analyze button
    if (mounted) setState(() => _state = _RecState.done);
  }

  // ── navigation ────────────────────────────────────────────────────────

  void _navigateToResults() {
    if (_audioPath == null) {
      _showError("No audio file found. Please record again.");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFFEF4444)),
            SizedBox(height: 20),
            Text(
              "Analysing audio via AI...",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );

    _uploadAudioAndNavigate();
  }

  Future<void> _uploadAudioAndNavigate() async {
    const String apiUrl = "https://acoustic-backend-410789680410.us-central1.run.app/predict";
    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(await http.MultipartFile.fromPath('file', _audioPath!));
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (!mounted) return;
      Navigator.pop(context); // close dialog

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MobileWrapper(
              child: ResultsPage(
                prediction: data['prediction'],
                confidenceScore: data['confidence_percent'].toDouble(),
                top3Predictions: data['top3_predictions'] as List<dynamic>,
                spectrogramBase64: data['spectrogram_base64'],
              ),
            ),
          ),
        );
      } else {
        _showError("Server error: ${response.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close dialog
      _showError("Failed to connect to backend: $e");
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  // ── helpers ───────────────────────────────────────────────────────────

  String get _clock {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  bool get _isRecording => _state == _RecState.recording;
  bool get _isDone => _state == _RecState.done;
  bool get _isBusy =>
      _state == _RecState.starting || _state == _RecState.stopping;

  // ── build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Audio Capture"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Clock
              Text(
                _clock,
                style: const TextStyle(
                    fontSize: 72, fontWeight: FontWeight.w200),
              ),
              const SizedBox(height: 12),

              // Status label
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _state == _RecState.stopping
                      ? "Stopping…"
                      : _isDone
                          ? "Recording complete"
                          : _isRecording
                              ? "Recording… breathe deeply"
                              : "Place microphone near chest\nand breathe deeply",
                  key: ValueKey(_state),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isRecording
                        ? const Color(0xFFEF4444)
                        : _isDone
                            ? Colors.greenAccent
                            : Colors.grey,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 50),

              // Waveform bars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _waves.map((h) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 4,
                    height: _isRecording ? h : 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 80),

              // Record / Stop button — hidden after recording is done
              if (!_isDone)
                GestureDetector(
                  onTap: _isBusy ? null : _onButtonTap,
                  child: AnimatedScale(
                    scale: _isRecording ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      height: 90,
                      width: 90,
                      decoration: BoxDecoration(
                        color: _isRecording
                            ? Colors.white
                            : const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withOpacity(0.35),
                            blurRadius: 24,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: _isBusy
                          ? const Padding(
                              padding: EdgeInsets.all(28),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFFEF4444),
                              ),
                            )
                          : Icon(
                              _isRecording
                                  ? Icons.stop_rounded
                                  : Icons.mic_rounded,
                              size: 45,
                              color: _isRecording
                                  ? Colors.red
                                  : Colors.white,
                            ),
                    ),
                  ),
                ),

              // Analyze button — shown after recording is done
              if (_isDone) ...[
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.greenAccent.withOpacity(0.4), width: 2),
                    color: Colors.greenAccent.withOpacity(0.08),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 50,
                    color: Colors.greenAccent,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 6,
                    ),
                    icon: const Icon(Icons.biotech_rounded, size: 22),
                    label: const Text(
                      "Analyze",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _navigateToResults,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: const Text(
                      "Discard & Re-record",
                      style: TextStyle(fontSize: 15),
                    ),
                    onPressed: () {
                      setState(() {
                        _state = _RecState.idle;
                        _seconds = 0;
                        _audioPath = null;
                        _waves.fillRange(0, _waves.length, 5.0);
                      });
                    },
                  ),
                ),
              ],
              const SizedBox(height: 28),

              if (kIsWeb && !_isRecording)
                const Text(
                  "Browser: records in Opus format",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }
}