import 'dart:convert';
import 'package:flutter/material.dart';

class ResultsPage extends StatelessWidget {
  final String prediction;
  final double confidenceScore;
  final List<dynamic> top3Predictions;
  final String? spectrogramBase64;

  const ResultsPage({
    super.key,
    required this.prediction,
    required this.confidenceScore,
    required this.top3Predictions,
    this.spectrogramBase64,
  });

  Color _getPredictionColor(String pred) {
    return pred.toLowerCase() == "healthy"
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = _getPredictionColor(prediction);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () =>
                        Navigator.popUntil(context, (r) => r.isFirst),
                  ),
                  const Expanded(
                    child: Text(
                      "Analysis Results",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // balance the back button
                ],
              ),
            ),

            // ── Scrollable Content ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top Prediction Hero ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            mainColor.withOpacity(0.2),
                            mainColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: mainColor.withOpacity(0.4)),
                      ),
                      child: Column(
                        children: [
                          // Confidence circle
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: mainColor, width: 4),
                              color: mainColor.withOpacity(0.1),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${confidenceScore.round()}%",
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  "confidence",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            prediction,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: mainColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            prediction.toLowerCase() == "healthy"
                                ? "No anomalies detected in your respiratory audio."
                                : "Potential anomaly detected. Please consult a healthcare professional.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.5),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Top 3 Predictions ──
                    _SectionLabel("Differential Diagnosis"),
                    const SizedBox(height: 10),
                    ...List.generate(top3Predictions.length, (i) {
                      final pred = top3Predictions[i];
                      final name = pred['class'] ?? 'Unknown';
                      final conf = (pred['confidence'] ?? 0.0).toDouble();
                      final isTop = i == 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isTop
                              ? mainColor.withOpacity(0.12)
                              : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isTop
                                ? mainColor.withOpacity(0.4)
                                : Colors.white10,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Rank badge
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isTop
                                    ? mainColor.withOpacity(0.2)
                                    : Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  "#${i + 1}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isTop ? mainColor : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: isTop ? 16 : 14,
                                  fontWeight:
                                      isTop ? FontWeight.bold : FontWeight.w500,
                                  color:
                                      isTop ? Colors.white : Colors.white70,
                                ),
                              ),
                            ),
                            // Confidence bar + text
                            SizedBox(
                              width: 100,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "${conf.toStringAsFixed(1)}%",
                                    style: TextStyle(
                                      fontSize: isTop ? 16 : 13,
                                      fontWeight: FontWeight.bold,
                                      color: isTop
                                          ? mainColor
                                          : Colors.white54,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: conf / 100,
                                      backgroundColor: Colors.white10,
                                      valueColor: AlwaysStoppedAnimation(
                                        isTop ? mainColor : Colors.white24,
                                      ),
                                      minHeight: 4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),

                    // ── Spectrogram Image ──
                    if (spectrogramBase64 != null) ...[
                      _SectionLabel("Mel Spectrogram"),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            base64Decode(spectrogramBase64!),
                            fit: BoxFit.contain,
                            width: double.infinity,
                            errorBuilder: (ctx, err, st) => const Padding(
                              padding: EdgeInsets.all(24),
                              child: Center(
                                child: Text("Could not load spectrogram",
                                    style: TextStyle(color: Colors.grey)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Disclaimer ──
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withOpacity(0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: Colors.amber.withOpacity(0.8), size: 18),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              "This is not a medical diagnosis. Always consult a healthcare professional.",
                              style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 11,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Record Again Button ──
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.mic_rounded, size: 20),
                        label: const Text(
                          "Record Again",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () =>
                            Navigator.popUntil(context, (r) => r.isFirst),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}