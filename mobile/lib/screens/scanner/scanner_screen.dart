import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_exception.dart';
import '../../config.dart';
import '../../data/mock_data.dart';
import '../../models/models.dart';
import '../../router.dart';
import '../../state/daily_log_state.dart';
import '../../state/providers.dart';
import '../../state/quota_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import 'post_scan_sheet.dart';

/// AI Food Scanner (Hero Feature).
/// Full-screen viewfinder → animated scanning overlay → post-scan sheet.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;
  Future<void>? _initFuture;
  String? _cameraError;
  bool _analyzing = false;

  late final AnimationController _scanCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  late final AnimationController _glowCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _initFuture = _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'No camera found on this device.');
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (e) {
      // Emulator without a camera, permission denied, etc.
      setState(() => _cameraError = 'Camera unavailable ($e).');
    }
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _glowCtrl.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_analyzing) return;

    // Quota gate: block if exhausted, route to paywall.
    final quota = ref.read(quotaProvider).valueOrNull;
    if (quota != null && quota.isExhausted) {
      _goPaywall();
      return;
    }

    setState(() => _analyzing = true);
    final api = ref.read(apiClientProvider);
    ScanResult? result;
    try {
      File? file;
      if (_controller != null && _controller!.value.isInitialized) {
        final shot = await _controller!.takePicture();
        file = File(shot.path);
      }
      if (file != null) {
        result = await api.scanImage(file);
      } else {
        // No camera (emulator) — try a tiny placeholder call would fail, so
        // fall straight to demo below.
        throw const ApiException(code: 'NETWORK', message: 'no camera');
      }
    } on ApiException catch (e) {
      if (e.isQuotaExceeded) {
        if (mounted) setState(() => _analyzing = false);
        _goPaywall();
        return;
      }
      if (AppConfig.demoFallbackEnabled && e.isNetwork) {
        result = MockData.demoScan;
      } else {
        if (mounted) {
          setState(() => _analyzing = false);
          _snack(e.message);
        }
        return;
      }
    } catch (_) {
      if (AppConfig.demoFallbackEnabled) {
        result = MockData.demoScan;
      } else {
        if (mounted) {
          setState(() => _analyzing = false);
          _snack('Scan failed. Please try again.');
        }
        return;
      }
    }

    if (!mounted) return;
    setState(() => _analyzing = false);
    ref.invalidate(quotaProvider);

    if (result != null) {
      await _showResults(result);
    }
  }

  Future<void> _showResults(ScanResult result) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostScanSheet(
        result: result,
        onAddToLog: (req) async {
          await ref.read(logActionsProvider).addLog(req);
        },
      ),
    );
    if (!mounted) return;
    if (added == true) {
      ref.invalidate(dailyLogProvider);
      _snack('Added to your log 🎉');
      context.go(Routes.dashboard);
    }
  }

  void _goPaywall() => context.push(Routes.paywall);

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final quotaAsync = ref.watch(quotaProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Viewfinder or fallback background.
          FutureBuilder(
            future: _initFuture,
            builder: (context, snap) {
              if (_controller != null &&
                  _controller!.value.isInitialized) {
                return FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.previewSize?.height ?? 1,
                    height: _controller!.value.previewSize?.width ?? 1,
                    child: CameraPreview(_controller!),
                  ),
                );
              }
              return _CameraFallback(error: _cameraError);
            },
          ),

          // Dark scrim for readability.
          Container(color: Colors.black.withValues(alpha: 0.15)),

          // Scan frame + animated line + pulsing glow.
          Center(
            child: _ScanFrame(
              analyzing: _analyzing,
              scanCtrl: _scanCtrl,
              glowCtrl: _glowCtrl,
            ),
          ),

          // Top bar: close + quota badge.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.close_rounded,
                    onTap: () => context.pop(),
                  ),
                  const Spacer(),
                  quotaAsync.maybeWhen(
                    data: (q) => ScanQuotaBadge(quota: q),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          // Bottom: instructions + capture button.
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _analyzing
                          ? 'Analyzing your dish…'
                          : 'Center your meal and tap to scan',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ShutterButton(
                      analyzing: _analyzing,
                      onTap: _capture,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  final bool analyzing;
  final AnimationController scanCtrl;
  final AnimationController glowCtrl;

  const _ScanFrame({
    required this.analyzing,
    required this.scanCtrl,
    required this.glowCtrl,
  });

  @override
  Widget build(BuildContext context) {
    const double box = 280;
    return AnimatedBuilder(
      animation: Listenable.merge([scanCtrl, glowCtrl]),
      builder: (context, _) {
        final glow = analyzing ? (0.3 + glowCtrl.value * 0.5) : 0.25;
        return Container(
          width: box,
          height: box,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.primary
                  .withValues(alpha: (glow + 0.3).clamp(0.0, 1.0)),
              width: 2,
            ),
            boxShadow: analyzing
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: glow),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Stack(
              children: [
                // Corner accents.
                ..._corners(),
                // Animated horizontal scanning line (only while analyzing).
                if (analyzing)
                  Positioned(
                    top: scanCtrl.value * (box - 4),
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.0),
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.0),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.primary.withValues(alpha: 0.8),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _corners() {
    const len = 26.0;
    const thick = 3.0;
    const color = AppColors.primary;
    BorderSide side() => const BorderSide(color: color, width: thick);
    return [
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: len,
          height: len,
          decoration:
              BoxDecoration(border: Border(top: side(), left: side())),
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: len,
          height: len,
          decoration:
              BoxDecoration(border: Border(top: side(), right: side())),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: len,
          height: len,
          decoration:
              BoxDecoration(border: Border(bottom: side(), left: side())),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: len,
          height: len,
          decoration:
              BoxDecoration(border: Border(bottom: side(), right: side())),
        ),
      ),
    ];
  }
}

class _ShutterButton extends StatelessWidget {
  final bool analyzing;
  final VoidCallback onTap;
  const _ShutterButton({required this.analyzing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: analyzing ? null : onTap,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.2),
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Center(
          child: analyzing
              ? const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              : Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white),
                ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _CameraFallback extends StatelessWidget {
  final String? error;
  const _CameraFallback({this.error});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111827),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_camera_outlined,
                color: Colors.white54, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text(
              error == null
                  ? 'Starting camera…'
                  : 'Camera preview unavailable.\nYou can still tap scan to try a demo result.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
