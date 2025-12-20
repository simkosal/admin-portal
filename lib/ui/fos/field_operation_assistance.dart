import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:invoiceninja_flutter/components/bottomsheets/base_bottomsheets.dart';
import 'package:signature/signature.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:http/http.dart' as http;

// --- Data Models ---

class ScheduleItem {
  ScheduleItem({
    required this.client,
    required this.purpose,
    required this.location,
    required this.time,
    required this.latitude,
    required this.longitude,
  });
  final String client;
  final String purpose;
  final String location;
  final String time;
  final double latitude;
  final double longitude;
}

class WorkReport {
  WorkReport({
    required this.id,
    required this.client,
    required this.purpose,
    this.checkIn,
    this.checkOut,
    required this.workSummary,
    required this.photoPaths,
    required this.remarks,
    this.signature,
    required this.timestamp,
    this.synced = false,
  });
  factory WorkReport.fromJson(Map<String, dynamic> json) => WorkReport(
        id: json['id'],
        client: json['client'],
        purpose: json['purpose'],
        checkIn: json['checkIn'],
        checkOut: json['checkOut'],
        workSummary: json['workSummary'],
        photoPaths: List<String>.from(json['photoPaths']),
        remarks: json['remarks'],
        signature: json['signature'],
        timestamp: json['timestamp'],
        synced: json['synced'],
      );
  final int id;
  final String client;
  final String purpose;
  final String? checkIn;
  final String? checkOut;
  final String workSummary;
  final List<String> photoPaths; // Store paths to images
  final String remarks;
  final String? signature; // Base64 encoded signature
  final String timestamp;
  bool synced;

  // Methods for JSON serialization for storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'client': client,
        'purpose': purpose,
        'checkIn': checkIn,
        'checkOut': checkOut,
        'workSummary': workSummary,
        'photoPaths': photoPaths,
        'remarks': remarks,
        'signature': signature,
        'timestamp': timestamp,
        'synced': synced,
      };
}

// --- Main Home Page (Manages State and Views) ---

enum AppView { schedule, activeVisit, checklist, workReport }

enum SyncStatus { online, offline, pending }

class FieldCompanionApp extends StatefulWidget {
  const FieldCompanionApp({super.key});

  @override
  State<FieldCompanionApp> createState() => _FieldCompanionAppState();
}

class _FieldCompanionAppState extends State<FieldCompanionApp> {
  // --- State Variables ---
  AppView _currentView = AppView.schedule;
  SyncStatus _syncStatus = SyncStatus.online;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  // Data
  final List<ScheduleItem> _schedule = [
    ScheduleItem(
        client: 'Acme Corp - Main Office',
        purpose: 'Installation',
        location: '123 Tech Way, Silicon Valley',
        time: 'Today, 10:00 AM - 12:00 PM',
        latitude: 37.7749,
        longitude: -122.4194),
    ScheduleItem(
        client: 'Globex Inc. - Warehouse',
        purpose: 'Routine Maintenance',
        location: '456 Industrial Blvd, Metro City',
        time: 'Today, 02:00 PM - 04:00 PM',
        latitude: 34.0522,
        longitude: -118.2437),
    ScheduleItem(
        client: 'Pied Piper - Data Center',
        purpose: 'Sales Demo',
        location: '789 Server St, Palo Alto',
        time: 'Tomorrow, 09:30 AM - 11:00 AM',
        latitude: 37.4419,
        longitude: -122.1430),
  ];
  ScheduleItem? _currentVisit;
  DateTime? _checkInTime;
  DateTime? _checkOutTime;
  List<WorkReport> _pendingSyncReports = [];

  // Controllers
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  final TextEditingController _workSummaryController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  TextEditingController? _activeSpeechController;

  // Checklist state
  final Map<String, bool> _checklistItems = {};

  // Photo state
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _imageFiles = [];

  // --- Lifecycle Methods ---
  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _loadPendingReports();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _signatureController.dispose();
    _workSummaryController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  // --- Initialization and Data Persistence ---
  Future<void> _initConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    await _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    if (result == ConnectivityResult.none) {
      setState(() => _syncStatus = SyncStatus.offline);
    } else {
      if (_pendingSyncReports.isNotEmpty) {
        setState(() => _syncStatus = SyncStatus.pending);
        _syncPendingReports();
      } else {
        setState(() => _syncStatus = SyncStatus.online);
      }
    }
  }

  Future<void> _savePendingReports() async {
    final prefs = await SharedPreferences.getInstance();
    final reportsJson =
        _pendingSyncReports.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList('pendingReports', reportsJson);
  }

  Future<void> _loadPendingReports() async {
    final prefs = await SharedPreferences.getInstance();
    final reportsJson = prefs.getStringList('pendingReports');
    if (reportsJson != null) {
      setState(() {
        _pendingSyncReports =
            reportsJson.map((r) => WorkReport.fromJson(jsonDecode(r))).toList();
      });
    }
    _updateConnectionStatus(await Connectivity().checkConnectivity());
  }

  // --- Syncing Logic ---
  Future<void> _syncPendingReports() async {
    if (_pendingSyncReports.isEmpty) {
      return;
    }

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // In a real app, you would loop through reports and send them via HTTP
    // For now, we just clear the pending list
    for (var report in _pendingSyncReports) {
      // final response = await http.post(
      //   Uri.parse('https://your-api.com/reports'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode(report.toJson()),
      // );
      // if (response.statusCode == 201) {
      //   // Successfully synced
      // }
      debugPrint('Simulating sync for report ID: ${report.id}');
    }

    setState(() {
      _pendingSyncReports.clear();
      _syncStatus = SyncStatus.online;
    });
    await _savePendingReports();
    _showSnackBar('All pending reports have been synchronized.',
        isError: false);
  }

  // --- UI Building Methods ---
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Field Assist',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Inter', // Assuming 'Inter' font is added to pubspec.yaml
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4F46E5),
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: Scaffold(
        body: Column(
          children: [
            _buildSyncIndicator(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentView(),
              ),
            ),
          ],
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  double getAppBarPlusStatusBarHeight(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    const double appBarHeight = kToolbarHeight; // Default AppBar height
    return statusBarHeight + appBarHeight / 1.5;
  }

  Widget _buildSyncIndicator() {
    Color color;
    String text;
    IconData icon;
    bool isSpinning = false;

    switch (_syncStatus) {
      case SyncStatus.online:
        color = const Color(0xFF10B981);
        text = 'All data synced';
        icon = FontAwesomeIcons.solidCircleCheck;
        break;
      case SyncStatus.offline:
        color = const Color(0xFFEF4444);
        text = 'Offline mode (${_pendingSyncReports.length} pending)';
        icon = FontAwesomeIcons.wifi;
        break;
      case SyncStatus.pending:
        color = const Color(0xFFF59E0B);
        text = 'Syncing ${_pendingSyncReports.length} reports...';
        icon = FontAwesomeIcons.rotate;
        isSpinning = true;
        break;
    }

    return Container(
      height: getAppBarPlusStatusBarHeight(context),
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Positioned(
            right: 0,
            child: Container(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSpinning)
                    SpinningIcon(icon: icon)
                  else
                    FaIcon(icon, color: Colors.white, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
              child: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Text(
              'Close',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case AppView.schedule:
        return _buildScheduleView();
      case AppView.activeVisit:
        return _buildActiveVisitView();
      case AppView.checklist:
        return _buildChecklistView();
      case AppView.workReport:
        return _buildWorkReportView();
    }
  }

  // --- View: Schedule ---
  Widget _buildScheduleView() {
    return Column(
      key: const ValueKey('scheduleView'),
      children: [
        _buildHeader('Field Assist',
            'No visits scheduled. Tap "Add Visit" to get started.'),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _schedule.length,
            itemBuilder: (context, index) {
              final item = _schedule[index];
              return _buildScheduleCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleCard(ScheduleItem item) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(item.client,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                TextButton.icon(
                  icon: const FaIcon(FontAwesomeIcons.mapLocationDot, size: 14),
                  label: const Text('Navigate'),
                  onPressed: () => _navigateToSite(item),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('📍 ${item.location}',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text('Purpose: ${item.purpose}'),
            const SizedBox(height: 4),
            Text('Time: ${item.time}'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.solidCircleCheck, size: 16),
              label: const Text('Select Visit'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () => _selectVisit(item),
            ),
          ],
        ),
      ),
    );
  }

  // --- View: Active Visit ---
  Widget _buildActiveVisitView() {
    if (_currentVisit == null) {
      return const Center(child: Text('Error: No visit selected.'));
    }

    return Column(
      key: const ValueKey('activeVisitView'),
      children: [
        _buildHeader('Active Visit', _currentVisit!.client,
            showBackButton: true),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text('Purpose: ${_currentVisit!.purpose}',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              if (_checkInTime == null)
                ElevatedButton.icon(
                  icon: const FaIcon(FontAwesomeIcons.rightToBracket, size: 16),
                  label: const Text('Check-In'),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48)),
                  onPressed: _checkIn,
                ),
              if (_checkInTime != null)
                Column(
                  children: [
                    Text(
                        'Checked in at: ${DateFormat.yMd().add_jm().format(_checkInTime!)}'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const FaIcon(FontAwesomeIcons.rightFromBracket,
                          size: 16),
                      label: const Text('Check-Out'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        backgroundColor: Colors.red,
                      ),
                      onPressed: _checkOut,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  // --- View: Checklist ---
  Widget _buildChecklistView() {
    if (_currentVisit == null)
      return const Center(child: Text('Error: No visit selected.'));

    final checklist = _getChecklistForPurpose(_currentVisit!.purpose);
    final totalItems = checklist.length;
    final checkedItems = _checklistItems.values.where((v) => v).length;

    return Column(
      key: const ValueKey('checklistView'),
      children: [
        _buildHeader('Dynamic Checklist', _currentVisit!.purpose,
            showBackButton: true),
        if (_checkInTime != null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Center(
                child: Text(
                  'Status: On-site since ${DateFormat.yMd().add_jm().format(_checkInTime!)}',
                  style: TextStyle(
                      color: Colors.blue.shade800, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: checklist.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = checklist.entries.elementAt(index);
              final itemText = entry.key;
              final isMandatory = entry.value;

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _checklistItems[itemText] =
                          !(_checklistItems[itemText] ?? false);
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 12.0),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _checklistItems[itemText] ?? false,
                          onChanged: (bool? value) {
                            setState(() {
                              _checklistItems[itemText] = value!;
                            });
                          },
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: DefaultTextStyle.of(context)
                                  .style
                                  .copyWith(fontSize: 16),
                              children: [
                                TextSpan(text: itemText),
                                if (isMandatory)
                                  const TextSpan(
                                    text: ' *',
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Progress: $checkedItems / $totalItems items completed',
            style:
                TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            child: const Text('Proceed to Check-Out'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
            ),
            onPressed: _checkOut,
          ),
        ),
      ],
    );
  }

  // --- View: Work Report ---
  Widget _buildWorkReportView() {
    return GestureDetector(
      onTap: () =>
          FocusScope.of(context).unfocus(), // Dismiss keyboard on tap outside
      child: Column(
        key: const ValueKey('workReportView'),
        children: [
          _buildHeader('Work Report', _currentVisit?.client ?? 'N/A',
              showBackButton: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVoiceTextField(
                      'Work Done Summary & Feedback', _workSummaryController),
                  const SizedBox(height: 16),
                  _buildPhotoAttachmentSection(),
                  const SizedBox(height: 16),
                  _buildVoiceTextField('Market/Technical Remarks & Challenges',
                      _remarksController),
                  const SizedBox(height: 16),
                  _buildSignatureSection(),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const FaIcon(FontAwesomeIcons.paperPlane, size: 16),
                    label: const Text('Submit Work Report'),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48)),
                    onPressed: _submitWorkReport,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Component Widgets ---
  Widget _buildHeader(String title, String subtitle,
      {bool showBackButton = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF4F46E5),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showBackButton)
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _goHome,
              ),
            ),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.indigo[200], fontSize: 16)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
              onPressed: () {
                BaseBottomSheets().addNew(context);
              },
              icon: Icon(Icons.add),
              label: Text('Add new visit'))
        ],
      ),
    );
  }

  Widget _buildVoiceTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: FaIcon(_isListening && _activeSpeechController == controller
                  ? FontAwesomeIcons.stop
                  : FontAwesomeIcons.microphone),
              color: _isListening && _activeSpeechController == controller
                  ? Colors.red
                  : Colors.grey,
              onPressed: () => _listen(controller),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoAttachmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Attach Photo(s)',
            style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const FaIcon(FontAwesomeIcons.camera, size: 16),
          label: const Text('Add Photos'),
          onPressed: _pickImages,
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black87),
        ),
        const SizedBox(height: 8),
        if (_imageFiles.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _imageFiles.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Image.file(File(_imageFiles[index].path),
                      width: 100, height: 100, fit: BoxFit.cover),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSignatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Signature (Optional)',
            style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Signature(
            controller: _signatureController,
            height: 150,
            backgroundColor: Colors.grey[200]!,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            child: const Text('Clear Signature'),
            onPressed: () => _signatureController.clear(),
          ),
        ),
      ],
    );
  }

  // --- Action Handlers & Logic ---
  void _goHome() {
    setState(() {
      _currentView = AppView.schedule;
      _currentVisit = null;
      _checkInTime = null;
      _checkOutTime = null;
      _workSummaryController.clear();
      _remarksController.clear();
      _signatureController.clear();
      _imageFiles.clear();
      _checklistItems.clear();
    });
  }

  Future<void> _navigateToSite(ScheduleItem item) async {
    final uri = Uri.parse(
        'http://maps.google.com/?q=${item.latitude},${item.longitude}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showSnackBar('Could not open map.', isError: true);
    }
  }

  void _selectVisit(ScheduleItem item) {
    setState(() {
      _currentVisit = item;
      _currentView = AppView.activeVisit;
      _loadChecklistForPurpose(item.purpose);
    });
  }

  void _checkIn() {
    setState(() {
      _checkInTime = DateTime.now();
      _currentView = AppView.checklist;
    });
    _showSnackBar('Checked in successfully!', isError: false);
  }

  void _checkOut() {
    // Validate mandatory checklist items
    final mandatoryItems = _getChecklistForPurpose(_currentVisit!.purpose)
        .entries
        .where((e) => e.value)
        .map((e) => e.key);

    final allMandatoryChecked =
        mandatoryItems.every((item) => _checklistItems[item] == true);

    if (!allMandatoryChecked) {
      _showSnackBar('Please complete all mandatory checklist items (*).',
          isError: true);
      return;
    }

    setState(() {
      _checkOutTime = DateTime.now();
      _currentView = AppView.workReport;
    });
    _showSnackBar('Checklist complete. Please fill out the work report.',
        isError: false);
  }

  Future<void> _pickImages() async {
    final List<XFile> selectedImages = await _picker.pickMultiImage();
    if (selectedImages.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(selectedImages);
      });
    }
  }

  void _listen(TextEditingController controller) async {
    if (!_isListening) {
      final bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) => debugPrint('onError: $val'),
      );
      if (available) {
        setState(() {
          _isListening = true;
          _activeSpeechController = controller;
        });
        _speech.listen(
          onResult: (val) => setState(() {
            controller.text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() {
        _isListening = false;
        _activeSpeechController = null;
      });
      _speech.stop();
    }
  }

  void _loadChecklistForPurpose(String purpose) {
    _checklistItems.clear();
    final checklist = _getChecklistForPurpose(purpose);
    for (var item in checklist.keys) {
      _checklistItems[item] = false;
    }
  }

  Map<String, bool> _getChecklistForPurpose(String purpose) {
    const checklists = {
      'Installation': {
        'Verify site readiness': true,
        'Unpack and inspect equipment': true,
        'Connect power and network': true,
        'Perform initial configuration': true,
        'Run diagnostic tests': true,
        'Train client personnel (if applicable)': false,
        'Clean up work area': false,
      },
      'Routine Maintenance': {
        'Perform visual inspection': true,
        'Check system logs for errors': true,
        'Update software/firmware': false,
        'Clean filters/components': false,
        'Verify system functionality': true,
        'Document findings': true,
      },
      'Sales Demo': {
        'Confirm client availability': true,
        'Set up demo environment': true,
        'Present core features': true,
        'Address client questions': true,
        'Discuss next steps': true,
        'Collect feedback': false,
      },
    };
    return checklists[purpose] ?? {};
  }

  Future<void> _submitWorkReport() async {
    if (_workSummaryController.text.isEmpty) {
      _showSnackBar('Work summary cannot be empty.', isError: true);
      return;
    }

    final Uint8List? signatureBytes = await _signatureController.toPngBytes();
    final String? signatureBase64 =
        signatureBytes != null ? base64Encode(signatureBytes) : null;

    final report = WorkReport(
      id: DateTime.now().millisecondsSinceEpoch,
      client: _currentVisit?.client ?? 'N/A',
      purpose: _currentVisit?.purpose ?? 'N/A',
      checkIn: _checkInTime?.toIso8601String(),
      checkOut: _checkOutTime?.toIso8601String(),
      workSummary: _workSummaryController.text,
      remarks: _remarksController.text,
      photoPaths: _imageFiles.map((f) => f.path).toList(),
      signature: signatureBase64,
      timestamp: DateTime.now().toIso8601String(),
    );

    if (_syncStatus == SyncStatus.offline) {
      setState(() {
        _pendingSyncReports.add(report);
      });
      await _savePendingReports();
      _showSnackBar('Report saved offline. Will sync when connection returns.',
          isError: false);
    } else {
      // Simulate online submission
      debugPrint('Submitting report online: ${report.toJson()}');
      _showSnackBar('Work report submitted successfully!', isError: false);
    }

    _goHome();
  }

  // --- Utility Methods ---
  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }
}

// --- Helper Widget for Spinning Icon ---
class SpinningIcon extends StatefulWidget {
  const SpinningIcon({super.key, required this.icon});
  final IconData icon;

  @override
  State<SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<SpinningIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: FaIcon(widget.icon, color: Colors.white, size: 14),
    );
  }
}
