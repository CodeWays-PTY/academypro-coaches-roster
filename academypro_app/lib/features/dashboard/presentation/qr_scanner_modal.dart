import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/checkin_controller.dart';
import '../controllers/roster_controller.dart';

class QrScannerModal extends ConsumerStatefulWidget {
  const QrScannerModal({Key? key}) : super(key: key);

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.black,
      builder: (context) => const QrScannerModal(),
    );
  }

  @override
  ConsumerState<QrScannerModal> createState() => _QrScannerModalState();
}

class _QrScannerModalState extends ConsumerState<QrScannerModal> with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  bool _isTorchOn = false;
  String? _bannerMessage;
  bool _bannerIsSuccess = true;
  Timer? _bannerTimer;
  final TextEditingController _manualInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserController.dispose();
    _bannerTimer?.cancel();
    _manualInputController.dispose();
    super.dispose();
  }

  void _triggerScan(String qrCodeData) {
    final result = ref.read(checkInProvider.notifier).processQRScan(qrCodeData);

    _bannerTimer?.cancel();
    setState(() {
      _bannerMessage = result.message;
      _bannerIsSuccess = result.success && !result.isDuplicate;
    });

    _bannerTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _bannerMessage = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final checkInState = ref.watch(checkInProvider);
    final allRecords = checkInState.playerRecords.values.toList();
    final pendingPlayers = allRecords.where((r) => !r.isCheckedIn).toList();
    final checkedInPlayers = allRecords.where((r) => r.isCheckedIn).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28.0),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CONTINUOUS QR SCANNER',
              style: TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 10.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'Checked In: ${checkInState.checkedInCount} / ${checkInState.totalCount}',
              style: const TextStyle(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _isTorchOn ? const Color(0xFFFACC15) : Colors.white70,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
            },
          ),
          const SizedBox(width: 8.0),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Toast Banner for Live Non-Blocking Feedback
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _bannerMessage != null
                  ? Container(
                      key: ValueKey(_bannerMessage),
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      decoration: BoxDecoration(
                        color: _bannerIsSuccess
                            ? const Color(0xFF15803D)
                            : const Color(0xFFB45309), // Green for success, Amber for duplicate/notice
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: (_bannerIsSuccess ? Colors.green : Colors.amber).withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _bannerIsSuccess ? Icons.check_circle : Icons.info_outline,
                            color: Colors.white,
                            size: 22.0,
                          ),
                          const SizedBox(width: 10.0),
                          Expanded(
                            child: Text(
                              _bannerMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox(height: 8.0),
            ),

            // Live Camera Viewfinder Overlay
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: const Color(0xFF334155), width: 2.0),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Simulated Dark Camera Feed Viewport
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22.0),
                        child: Container(
                          color: Colors.black,
                          child: Opacity(
                            opacity: 0.15,
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                              itemBuilder: (context, index) => Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.cyan.withOpacity(0.2), width: 0.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Target Reticle Box
                    Container(
                      width: 240.0,
                      height: 240.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(
                          color: _bannerMessage != null && _bannerIsSuccess
                              ? const Color(0xFF22C55E)
                              : const Color(0xFF38BDF8),
                          width: 3.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_bannerIsSuccess ? const Color(0xFF22C55E) : const Color(0xFF38BDF8))
                                .withOpacity(0.3),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Laser scan line animating up and down
                          AnimatedBuilder(
                            animation: _laserController,
                            builder: (context, child) {
                              return Positioned(
                                top: _laserController.value * 230.0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 3.0,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF38BDF8),
                                    boxShadow: [
                                      BoxShadow(color: Color(0xFF38BDF8), blurRadius: 8, spreadRadius: 2),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const Center(
                            child: Icon(Icons.qr_code_2, color: Colors.white24, size: 90.0),
                          ),
                        ],
                      ),
                    ),

                    // Instruction banner at bottom of viewfinder
                    Positioned(
                      bottom: 20.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(999.0),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.center_focus_strong, color: Color(0xFF38BDF8), size: 16.0),
                            SizedBox(width: 6.0),
                            Text(
                              'Position athlete QR code in reticle',
                              style: TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Continuous Scan Selector Tray (Fast Manual Trigger / Simulation Bar)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'QUICK SCAN ATHLETE BADGE',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        '${pendingPlayers.length} pending',
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0),

                  // Horizontal reel of pending athlete buttons for instant test/simulation tap
                  if (pendingPlayers.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 18.0),
                          SizedBox(width: 8.0),
                          Text(
                            'All squad athletes checked in!',
                            style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold, fontSize: 13.0),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 44.0,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: pendingPlayers.length,
                        separatorBuilder: (ctx, i) => const SizedBox(width: 8.0),
                        itemBuilder: (context, index) {
                          final p = pendingPlayers[index].player;
                          return ElevatedButton.icon(
                            onPressed: () {
                              _triggerScan(p.id);
                            },
                            icon: const Icon(Icons.qr_code_scanner, size: 15.0),
                            label: Text('${p.firstName} ${p.lastName}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E293B),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              side: const BorderSide(color: Color(0xFF334155)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              textStyle: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w600),
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 12.0),

                  // Action Buttons Footer
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF475569)),
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                          ),
                          child: const Text(
                            'Done Scanning',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
