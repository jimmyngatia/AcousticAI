import 'dart:math';
import 'package:flutter/material.dart';

class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          "AI Analysis",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header badge ──
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.greenAccent.withOpacity(0.35)),
                ),
                child: const Text(
                  "ANALYSIS COMPLETE",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.8,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Score card ──
            _ScoreCard(),
            const SizedBox(height: 28),

            // ── Section: Graphical Analysis ──
            _SectionTitle("Graphical Analysis"),
            const SizedBox(height: 12),
            _SpectrogramCard(),
            const SizedBox(height: 28),

            // ── Section: Observations ──
            _SectionTitle("Observations"),
            const SizedBox(height: 12),
            ..._observations.map((o) => _ObservationTile(o)),
            const SizedBox(height: 28),

            // ── Section: Conclusions ──
            _SectionTitle("Conclusions"),
            const SizedBox(height: 12),
            _ConclusionsCard(),
            const SizedBox(height: 28),

            // ── Disclaimer ──
            _DisclaimerCard(),
            const SizedBox(height: 28),

            // ── CTA button ──
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  "Record Again",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () =>
                    Navigator.popUntil(context, (r) => r.isFirst),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── SCORE CARD ───────────────────────────────

class _ScoreCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.greenAccent.withOpacity(0.12),
            Colors.teal.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Score circle
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.greenAccent, width: 3),
              color: Colors.greenAccent.withOpacity(0.08),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "88",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "/ 100",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Healthy Lung Function",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Your respiratory acoustics are within normal parameters. No significant anomalies detected.",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    height: 1.5,
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

// ─────────────────────────── SPECTROGRAM ──────────────────────────────

class _SpectrogramCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The drawn spectrogram
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(painter: _SpectrogramPainter()),
            ),
          ),

          // Frequency axis labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _AxisLabel("0 Hz"),
                _AxisLabel("500 Hz"),
                _AxisLabel("1 kHz"),
                _AxisLabel("2 kHz"),
                _AxisLabel("4 kHz"),
              ],
            ),
          ),

          // Legend row
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _LegendDot(Colors.cyanAccent, "Vesicular"),
                const SizedBox(width: 16),
                _LegendDot(Colors.greenAccent, "Bronchial"),
                const SizedBox(width: 16),
                _LegendDot(Colors.purpleAccent, "Tracheal"),
                const Spacer(),
                Text(
                  "16 kHz · Mono",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.2),
                    fontSize: 10,
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

class _AxisLabel extends StatelessWidget {
  final String label;
  const _AxisLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withOpacity(0.3),
        fontSize: 10,
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}

class _SpectrogramPainter extends CustomPainter {
  final Random _rng = Random(42);

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0d1117), Color(0xFF0a1628)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Vertical time grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += size.width / 8) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += size.height / 6) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Frequency band waveforms
    const bands = 10;
    final bandColors = [
      Colors.cyanAccent,
      Colors.cyan,
      Colors.tealAccent,
      Colors.greenAccent,
      Colors.green,
      Colors.lightGreenAccent,
      Colors.purpleAccent,
      Colors.purple,
      Colors.blueAccent,
      Colors.blue,
    ];

    for (int b = 0; b < bands; b++) {
      final yBase = size.height * (b + 0.5) / bands;
      final amplitude = size.height / (bands * 1.8);
      final color = bandColors[b % bandColors.length];

      final path = Path()..moveTo(0, yBase);
      double x = 0;
      while (x <= size.width) {
        final dy = (_rng.nextDouble() - 0.5) * amplitude * 2;
        path.lineTo(x, yBase + dy);
        x += 1.5 + _rng.nextDouble() * 3.5;
      }

      // Glow effect: draw twice, blurred then sharp
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withOpacity(0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withOpacity(0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Amplitude envelope overlay (semi-transparent fill)
    final envelopePath = Path()..moveTo(0, size.height);
    double ex = 0;
    while (ex <= size.width) {
      final ey =
          size.height * 0.3 + (_rng.nextDouble() - 0.3) * size.height * 0.5;
      envelopePath.lineTo(ex, ey);
      ex += 4 + _rng.nextDouble() * 8;
    }
    envelopePath.lineTo(size.width, size.height);
    envelopePath.close();

    canvas.drawPath(
      envelopePath,
      Paint()
        ..color = Colors.cyanAccent.withOpacity(0.04)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─────────────────────────── OBSERVATIONS ─────────────────────────────

class _Observation {
  final String title;
  final String detail;
  final Color color;
  final IconData icon;
  final String tag;
  const _Observation(this.title, this.detail, this.color, this.icon, this.tag);
}

const _observations = [
  _Observation(
    "Normal Vesicular Sounds",
    "Soft, low-pitched sounds heard over most lung fields during inspiration. Indicates patent airways and normal alveolar function.",
    Colors.greenAccent,
    Icons.check_circle_outline_rounded,
    "NORMAL",
  ),
  _Observation(
    "No Wheezing Detected",
    "Absence of continuous, high-pitched musical sounds. Rules out significant bronchospasm or airway narrowing.",
    Colors.greenAccent,
    Icons.air_rounded,
    "CLEAR",
  ),
  _Observation(
    "No Crackles or Rales",
    "No discontinuous, explosive sounds detected. This suggests absence of fluid in the small airways or alveoli.",
    Colors.greenAccent,
    Icons.grain_rounded,
    "CLEAR",
  ),
  _Observation(
    "Symmetric Bilateral Airflow",
    "Breath sounds appear equal on both sides, suggesting no major unilateral obstruction or consolidation.",
    Colors.blueAccent,
    Icons.compare_arrows_rounded,
    "NORMAL",
  ),
  _Observation(
    "Respiratory Rate",
    "Estimated 14–16 breaths/min from audio cadence — within the normal adult range of 12–20 breaths/min.",
    Colors.blueAccent,
    Icons.timer_outlined,
    "NORMAL",
  ),
];

class _ObservationTile extends StatelessWidget {
  final _Observation obs;
  const _ObservationTile(this.obs, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: obs.color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: obs.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(obs.icon, color: obs.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        obs.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: obs.color,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: obs.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        obs.tag,
                        style: TextStyle(
                          color: obs.color,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  obs.detail,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    height: 1.5,
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

// ─────────────────────────── CONCLUSIONS ──────────────────────────────

class _ConclusionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.summarize_outlined,
                  color: Colors.blueAccent, size: 22),
              const SizedBox(width: 10),
              const Text(
                "Clinical Summary",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 24),
          const Text(
            "Based on the acoustic analysis of the recorded breath sounds, the following conclusions were drawn:",
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 14),
          _ConclusionPoint(
            "No pathological breath sounds identified.",
            "The absence of wheezing, crackles, stridor, or pleural friction rub suggests clear, unobstructed airways.",
          ),
          _ConclusionPoint(
            "Lung function score: 88/100.",
            "Score calculated from acoustic entropy, frequency distribution, and rhythm regularity.",
          ),
          _ConclusionPoint(
            "Low risk for acute respiratory conditions.",
            "Acoustic profile is inconsistent with pneumonia, COPD exacerbation, or bronchospasm at this time.",
          ),
          _ConclusionPoint(
            "Recommended follow-up.",
            "Repeat analysis in 30 days or immediately if symptoms such as coughing, wheezing, or shortness of breath develop.",
          ),
        ],
      ),
    );
  }
}

class _ConclusionPoint extends StatelessWidget {
  final String title;
  final String body;
  const _ConclusionPoint(this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.arrow_right_rounded,
                color: Colors.blueAccent, size: 20),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "$title ",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  TextSpan(
                    text: body,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── DISCLAIMER ───────────────────────────────

class _DisclaimerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "For informational purposes only. This tool does not constitute a medical diagnosis. "
              "Always consult a qualified healthcare professional for clinical decisions.",
              style: TextStyle(color: Colors.amber, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── SECTION TITLE ────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}