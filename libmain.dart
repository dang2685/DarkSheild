import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const DarkShieldApp());

// ====== BRAND CONSTANTS ======
const Color kBg = Colors.black;
const Color kCyan = Color(0xFF00E8FF);
const Color kCyanEdge = Color(0xFF00C8D8);
const Color kTurq = Color(0xFF00C4C4);
const Color kViolet = Color(0xFF7B56FF);
const Duration kBreathInhale = Duration(seconds: 6);
const Duration kBreathExhale = Duration(seconds: 6);

enum SanctuaryMode { silent, pulse, aura }

// ====== SIMPLE APP STATE (IN-MEMORY FOR TESTING) ======
class AppState extends ChangeNotifier {
  SanctuaryMode mode = SanctuaryMode.silent;
  final List<VaultEntry> entries = [];
  bool orbView = true;

  void setMode(SanctuaryMode m) {
    mode = m; notifyListeners();
  }

  void toggleView() { orbView = !orbView; notifyListeners(); }

  void addEntry(String text) {
    if (text.trim().isEmpty) return;
    entries.insert(0, VaultEntry(DateTime.now(), text));
    notifyListeners();
  }
}

class VaultEntry {
  final DateTime created;
  final String text; // we won’t show text in list preview (privacy)
  VaultEntry(this.created, this.text);
}

// ====== APP ROOT ======
class DarkShieldApp extends StatelessWidget {
  const DarkShieldApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DarkShield',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBg,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: kCyan, fontSize: 16),
        ),
        colorScheme: const ColorScheme.dark(primary: kCyan),
        fontFamily: 'Roboto',
      ),
      home: InheritedAppState(
        state: AppState(),
        child: const WelcomeGate(),
      ),
    );
  }
}

// ====== VERY LIGHTWEIGHT INHERITED STATE (no packages) ======
class InheritedAppState extends InheritedWidget {
  final AppState state;
  const InheritedAppState({super.key, required this.state, required super.child});
  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedAppState>()!.state;
  @override
  bool updateShouldNotify(covariant InheritedAppState oldWidget) => oldWidget.state != state;
}

// ====== 1) WELCOME GATE (rotating sanctuary lines) ======
class WelcomeGate extends StatefulWidget {
  const WelcomeGate({super.key});
  @override
  State<WelcomeGate> createState() => _WelcomeGateState();
}

class _WelcomeGateState extends State<WelcomeGate> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final List<String> lines = const [
    "Enter your sanctuary",
    "Where your feelings can rest",
    "Nothing follows you in here",
  ];
  int idx = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 20))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => idx = (idx + 1) % lines.length);
          _controller.forward(from: 0);
        }
      })
      ..forward();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Neural-ocean background
          const NeuralOceanBackground(),
          // Upright shield
          Center(
            child: SizedBox(
              width: 240, height: 360,
              child: CustomPaint(painter: ShieldPainter(edgeOnly: true)),
            ),
          ),
          // Title + rotating line + CTA
          Column(
            children: [
              const SizedBox(height: 100),
              Text("DarkShield",
                style: TextStyle(
                  color: kCyan,
                  fontSize: 32,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                )),
              const Spacer(),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 800),
                opacity: 1,
                child: Text(lines[idx],
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kCyan, fontSize: 18)),
              ),
              const SizedBox(height: 16),
              Text("Emotional protection, without judgment.",
                style: TextStyle(color: kCyan.withOpacity(0.8))),
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: kCyan,
                    side: const BorderSide(color: kCyanEdge),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SanctuaryModeSelect())
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18.0, vertical: 12),
                    child: Text("Enter Sanctuary"),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

// ====== 2) MODE SELECT (Silent / Pulse / Aura, shield variants) ======
class SanctuaryModeSelect extends StatelessWidget {
  const SanctuaryModeSelect({super.key});
  @override
  Widget build(BuildContext context) {
    final app = InheritedAppState.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBg,
        title: const Text("Choose your sanctuary mode", style: TextStyle(color: kCyan)),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const NeuralOceanBackground(intensity: 0.25),
          Center(
            child: Wrap(
              spacing: 28, runSpacing: 28,
              alignment: WrapAlignment.center,
              children: [
                _ModeCard(
                  label: "Silent",
                  painter: const ShieldPainter(edgeOnly: true, edgeColor: kCyanEdge),
                  onTap: () { app.setMode(SanctuaryMode.silent); _goHome(context); },
                ),
                _ModeCard(
                  label: "Pulse",
                  painter: const ShieldPainter(edgeOnly: false, bodyShade: 0.25),
                  onTap: () { app.setMode(SanctuaryMode.pulse); _goHome(context); },
                ),
                _ModeCard(
                  label: "Aura",
                  painter: const ShieldPainter(edgeOnly: true, withAura: true),
                  onTap: () { app.setMode(SanctuaryMode.aura); _goHome(context); },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SanctuaryHome()));
  }
}

class _ModeCard extends StatelessWidget {
  final String label;
  final CustomPainter painter;
  final VoidCallback onTap;
  const _ModeCard({required this.label, required this.painter, required this.onTap, super.key});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 180, height: 260,
        child: Column(
          children: [
            Expanded(child: CustomPaint(painter: painter)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: kCyan))
          ],
        ),
      ),
    );
  }
}

// ====== 3) HOME (Unload / Breathe / Vault / Reset) ======
class SanctuaryHome extends StatelessWidget {
  const SanctuaryHome({super.key});
  @override
  Widget build(BuildContext context) {
    final app = InheritedAppState.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBg,
        title: const Text("DarkShield", style: TextStyle(color: kCyan)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const NeuralOceanBackground(intensity: 0.18),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const SizedBox(width: 220, height: 320,
                  child: CustomPaint(painter: ShieldPainter(edgeOnly: true))),
                const SizedBox(height: 24),
                Text("How are you holding up right now?",
                  style: TextStyle(color: kCyan.withOpacity(0.9))),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12, runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _ActionButton("Unload", () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const UnloadScreen()));
                    }),
                    _ActionButton("Breathe", () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BreatheScreen()));
                    }),
                    _ActionButton("Vault", () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VaultScreen()));
                    }),
                    _ActionButton("Reset Mode", () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SanctuaryModeSelect()));
                    }),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  switch (app.mode) {
                    SanctuaryMode.silent => "Mode: Silent",
                    SanctuaryMode.pulse  => "Mode: Pulse",
                    SanctuaryMode.aura   => "Mode: Aura",
                  },
                  style: TextStyle(color: kCyan.withOpacity(0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ActionButton(this.label, this.onTap, {super.key});
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: kCyanEdge),
        foregroundColor: kCyan, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: onTap,
      child: Text(label),
    );
  }
}

// ====== 4) UNLOAD / RELEASE ======
class UnloadScreen extends StatefulWidget {
  const UnloadScreen({super.key});
  @override
  State<UnloadScreen> createState() => _UnloadScreenState();
}

class _UnloadScreenState extends State<UnloadScreen> {
  final _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final app = InheritedAppState.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBg,
        title: const Text("Unload", style: TextStyle(color: kCyan)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const NeuralOceanBackground(intensity: 0.15),
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Say whatever you need to say.", style: TextStyle(color: kCyan, fontSize: 18)),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: kCyanEdge),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black.withOpacity(0.2),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: kCyan),
                      maxLines: null,
                      decoration: const InputDecoration.collapsed(hintText: "Type here…", hintStyle: TextStyle(color: Colors.white24)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: kCyan,
                      side: const BorderSide(color: kCyanEdge),
                    ),
                    onPressed: () {
                      app.addEntry(_controller.text);
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const ReleaseMomentScreen()),
                      );
                    },
                    child: const Text("Release"),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReleaseMomentScreen extends StatelessWidget {
  const ReleaseMomentScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const NeuralOceanBackground(intensity: 0.3),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(width: 240, height: 360, child: CustomPaint(painter: ShieldPainter(edgeOnly: true))),
                SizedBox(height: 24),
                Text("Release complete.", style: TextStyle(color: kCyan, fontSize: 18)),
                SizedBox(height: 8),
                Text("You don’t have to hold everything right now.",
                    style: TextStyle(color: kCyan)),
              ],
            ),
          ),
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Center(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: kCyanEdge), foregroundColor: kCyan),
                onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SanctuaryHome())),
                child: const Text("Return"),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// ====== 5) BREATHE (6–7s slow cycle) ======
class BreatheScreen extends StatefulWidget {
  const BreatheScreen({super.key});
  @override
  State<BreatheScreen> createState() => _BreatheScreenState();
}

class _BreatheScreenState extends State<BreatheScreen> with TickerProviderStateMixin {
  late final AnimationController inhale;
  late final AnimationController exhale;
  bool exhaling = false;

  @override
  void initState() {
    super.initState();
    inhale = AnimationController(vsync: this, duration: kBreathInhale)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() => exhaling = true);
          exhale.forward(from: 0);
        }
      })
      ..forward();
    exhale = AnimationController(vsync: this, duration: kBreathExhale)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() => exhaling = false);
          inhale.forward(from: 0);
        }
      });
  }

  @override
  void dispose() { inhale.dispose(); exhale.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final progress = exhaling ? exhale : inhale;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBg,
        title: const Text("Breathe", style: TextStyle(color: kCyan)),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: progress,
        builder: (context, _) {
          final t = progress.value; // 0..1
          return Stack(
            fit: StackFit.expand,
            children: [
              NeuralOceanBackground(intensity: 0.22 + 0.1 * (exhaling ? 1 - t : t)),
              Center(
                child: SizedBox(
                  width: 320, height: 320,
                  child: CustomPaint(
                    painter: AuraBreathPainter(phase: t, exhaling: exhaling),
                  ),
                ),
              ),
              Align(
                alignment: Alignment(0, 0.55),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      exhaling ? "Exhale — your feelings have room here." : "Inhale — you're safe.",
                      style: const TextStyle(color: kCyan),
                    ),
                    const SizedBox(height: 8),
                    const Text("Emotional protection, without judgment.",
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

// ====== 6) VAULT (toggle: orbs ↔ list) ======
class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = InheritedAppState.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBg,
        title: Text(app.orbView ? "Vault — Emotional Space" : "Vault — Entries",
            style: const TextStyle(color: kCyan)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => app.toggleView(),
            icon: Icon(app.orbView ? Icons.list_alt : Icons.blur_circular, color: kCyan),
          )
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const NeuralOceanBackground(intensity: 0.2),
          app.orbView ? const OrbCluster() : const EncryptedListView(),
        ],
      ),
    );
  }
}

class EncryptedListView extends StatelessWidget {
  const EncryptedListView({super.key});
  @override
  Widget build(BuildContext context) {
    final app = InheritedAppState.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: app.entries.length,
      itemBuilder: (_, i) {
        final e = app.entries[i];
        final stamp = "${e.created.year}-${e.created.month.toString().padLeft(2,'0')}-${e.created.day.toString().padLeft(2,'0')}";
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: kCyanEdge), borderRadius: BorderRadius.circular(10),
            color: Colors.black.withOpacity(0.25),
          ),
          child: Text("Entry • $stamp • encrypted", style: const TextStyle(color: kCyan)),
        );
      },
    );
  }
}

class OrbCluster extends StatelessWidget {
  const OrbCluster({super.key});
  @override
  Widget build(BuildContext context) {
    final app = InheritedAppState.of(context);
    final rnd = Random(42);
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        // generate positions (free-floating)
        final positions = List.generate(app.entries.isEmpty ? 12 : min(18, app.entries.length + 6), (i) {
          final x = rnd.nextDouble() * (size.width - 160) + 80;
          final y = rnd.nextDouble() * (size.height - 300) + 160;
          return Offset(x, y);
        });
        return CustomPaint(
          painter: OrbPainter(positions: positions),
          size: size,
        );
      },
    );
  }
}

// ====== PAINTERS ======
class ShieldPainter extends CustomPainter {
  final bool edgeOnly;
  final bool withAura;
  final double bodyShade; // 0..1
  final Color edgeColor;
  const ShieldPainter({
    this.edgeOnly = true,
    this.withAura = false,
    this.bodyShade = 0.35,
    this.edgeColor = kCyanEdge,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final pts = [
      Offset(w*0.5, h*0.05),
      Offset(w*0.87, h*0.28),
      Offset(w*0.70, h*0.95),
      Offset(w*0.30, h*0.95),
      Offset(w*0.13, h*0.28),
    ];
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) { path.lineTo(pts[i].dx, pts[i].dy); }
    path.close();

    if (withAura) {
      final paintAura = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = kTurq.withOpacity(0.4);
      for (double r = 0; r < 18; r += 1) {
        canvas.drawPath(path, paintAura..color = paintAura.color.withOpacity(max(0, 0.35 - r*0.02)));
      }
    }

    if (!edgeOnly) {
      final paintBody = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withOpacity(bodyShade);
      canvas.drawPath(path, paintBody);
    }

    final paintEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..color = edgeColor;
    canvas.drawPath(path, paintEdge);
  }

  @override
  bool shouldRepaint(covariant ShieldPainter oldDelegate) => false;
}

class AuraBreathPainter extends CustomPainter {
  final double phase; // 0..1
  final bool exhaling;
  const AuraBreathPainter({required this.phase, required this.exhaling});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height/2);
    // draw concentric rings with turquoise -> violet fade, sized by breath phase
    for (int i = 0; i < 6; i++) {
      final t = i / 6;
      final baseR = 60.0 + i * 24.0;
      final r = baseR + (exhaling ? (1 - phase) : phase) * 28.0;
      final color = Color.lerp(kTurq, kViolet, t)!.withOpacity(0.28 - t*0.04);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = color;
      canvas.drawCircle(center, r, paint);
    }
    // center heartbeat dot (very faint)
    final beat = sin((phase) * pi);
    final dotPaint = Paint()..color = kCyan.withOpacity(0.35 + 0.25 * beat);
    canvas.drawCircle(center, 4, dotPaint);
    // Shield outline on top
    final shieldSize = Size(size.width * 0.7, size.height * 1.0);
    final off = Offset(center.dx - shieldSize.width/2, center.dy - shieldSize.height/2);
    final shieldRect = Rect.fromLTWH(off.dx, off.dy, shieldSize.width, shieldSize.height);
    canvas.save();
    canvas.translate(shieldRect.left, shieldRect.top);
    final sp = ShieldPainter(edgeOnly: true);
    sp.paint(canvas, shieldRect.size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AuraBreathPainter oldDelegate) => oldDelegate.phase != phase || oldDelegate.exhaling != exhaling;
}

class NeuralOceanBackground extends StatelessWidget {
  final double intensity; // 0..1
  const NeuralOceanBackground({super.key, this.intensity = 0.3});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _NeuralOceanPainter(intensity: intensity));
  }
}

class _NeuralOceanPainter extends CustomPainter {
  final double intensity;
  const _NeuralOceanPainter({required this.intensity});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height/2);
    for (double r = size.shortestSide*0.6; r > 40; r -= 28) {
      final t = r / (size.shortestSide*0.6);
      final col = Color.lerp(kTurq, kViolet, 1 - t)!.withOpacity(0.12 * intensity);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = col;
      canvas.drawCircle(center, r, paint);
    }
  }
  @override
  bool shouldRepaint(covariant _NeuralOceanPainter oldDelegate) => oldDelegate.intensity != intensity;
}

// ====== UTIL ======
class TextGlow extends StatelessWidget {
  final String text;
  final TextStyle style;
  const TextGlow(this.text, {super.key, required this.style});
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(text, style: style.copyWith(color: style.color?.withOpacity(0.25))),
        Text(text, style: style),
      ],
    );
  }
}
