import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/state/app_state.dart';
import '../../../shared/widgets/neon_card.dart';
import 'doctor_patient_history_screen.dart';

class DoctorPatientSearchScreen extends StatefulWidget {
  const DoctorPatientSearchScreen({super.key});

  @override
  State<DoctorPatientSearchScreen> createState() => _DoctorPatientSearchScreenState();
}

class _DoctorPatientSearchScreenState extends State<DoctorPatientSearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _qrStatusText = 'Ready to scan...';
  bool _isScanning = false;

  final List<Map<String, dynamic>> _mockPatients = [
    {
      'id': 'priya_123',
      'name': 'Priya Sharma',
      'age': 34,
      'gender': 'Female',
      'lastEncounter': '20 June 2026',
    },
    {
      'id': 'elena_vance',
      'name': 'Elena Vance',
      'age': 28,
      'gender': 'Female',
      'lastEncounter': '25 June 2026',
    }
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _simulateQrScan() {
    setState(() {
      _isScanning = true;
      _qrStatusText = 'Scanning patient QR...';
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final appState = Provider.of<AppState>(context, listen: false);
      
      // Establish Doctor-Patient live session
      appState.startDoctorPatientSession('elena_vance', 'Elena Vance');

      setState(() {
        _isScanning = false;
        _qrStatusText = 'QR code recognized! Elena Vance connected.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consent validated. Session established.')),
      );

      // Navigate to patient history screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const DoctorPatientHistoryScreen(
            patientId: 'elena_vance',
            patientName: 'Elena Vance',
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    final filteredPatients = _mockPatients.where((p) {
      final name = p['name'].toString().toLowerCase();
      final id = p['id'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || id.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Connect Patient Vault',
          style: GoogleFonts.sora(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. QR Scan Block
            Text(
              'Patient Consent Scan',
              style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            NeonCard(
              neonColor: theme.colorScheme.primary,
              child: Column(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Simulating visual camera viewfinder targeting frame
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _isScanning
                                  ? const Color(0xFF10B981) // active green
                                  : theme.colorScheme.primary.withOpacity(0.6),
                              width: 2.0,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        if (_isScanning)
                          const Positioned(
                            child: CircularProgressIndicator(),
                          ),
                        Positioned(
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _qrStatusText,
                              style: GoogleFonts.jetBrainsMono(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isScanning ? null : _simulateQrScan,
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text(
                        'Simulate QR Scan (Elena Vance)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 2. Search Section
            Text(
              'Manual Search Registry',
              style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search patient name, NPI, or mobile number...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),

            // Filtered Patient List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredPatients.length,
              itemBuilder: (context, index) {
                final patient = filteredPatients[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DoctorPatientHistoryScreen(
                            patientId: patient['id'],
                            patientName: patient['name'],
                          ),
                        ),
                      );
                    },
                    child: NeonCard(
                      borderWidth: 0.5,
                      neonColor: theme.colorScheme.secondary.withOpacity(0.3),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.person, color: theme.colorScheme.secondary),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patient['name'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Age: ${patient['age']} • Last Encounter: ${patient['lastEncounter']}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isLight ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: isLight ? Colors.grey : Colors.white38),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
