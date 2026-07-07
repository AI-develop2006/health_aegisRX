import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/state/app_state.dart';
// ignore: unused_import
import '../../../shared/models/prescription.dart';

class PatientNotificationsScreen extends StatelessWidget {
  const PatientNotificationsScreen({super.key});

  // 60-30-10 Design Tokens
  static const _bg = Color(0xFFF7F4EB);
  static const _card = Color(0xFFFFFFFF);
  static const _text = Color(0xFF4A3325);
  static const _sub = Color(0xFFD4A387);
  static const _border = Color(0xFFB88E74);
  static const _teal = Color(0xFF2E8B90);
  static const _red = Color(0xFFB33A3A);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final String? pendingRequestId = appState.activePendingRequestId;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.sora(
            fontWeight: FontWeight.bold,
            color: _text,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: pendingRequestId == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.notifications_none_rounded,
                        size: 64, color: _border),
                    const SizedBox(height: 16),
                    Text(
                      'No new notifications.',
                      style: GoogleFonts.inter(
                        color: _sub,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pending Requests',
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _teal, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _teal.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _teal.withOpacity(0.4), width: 1),
                              ),
                              child: const Icon(Icons.emergency_share_rounded,
                                  color: _teal, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Doctor Connection Request',
                                    style: GoogleFonts.sora(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: _text,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ID: $pendingRequestId',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10,
                                      color: _sub,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'A doctor is requesting temporary session access to view your health profile and write a prescription. Do you grant access?',
                          style: GoogleFonts.inter(
                            color: _sub,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () async {
                                await appState
                                    .rejectConsultation(pendingRequestId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Request declined successfully.')),
                                );
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _red,
                                side: const BorderSide(color: _red, width: 1.5),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('Decline',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      color: _red)),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () async {
                                await appState
                                    .acceptConsultation(pendingRequestId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Access session granted successfully.')),
                                );
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _teal,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text('Grant Access',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
