import 'dart:io';
import 'dart:convert';
import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_helper.dart';
import '../services/energy_service.dart';
import '../services/pro_service.dart'; 
import '../screens/settings/manage_subscription_screen.dart'; 
import 'pro_paywall_sheet.dart'; 
import 'ai_loading_overlay.dart';
import 'energy_empty_dialog.dart';

Future<String> _extractFileContentInBackground(
  Map<String, dynamic> data,
) async {
  Uint8List bytes = data['bytes'];
  String extension = data['extension'];
  String fileContent = '';

  if (extension == 'pdf') {
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    fileContent = PdfTextExtractor(document).extractText();
    document.dispose();
  } else if (extension == 'txt') {
    fileContent = utf8.decode(bytes, allowMalformed: true);
  } else if (['jpg', 'jpeg', 'png'].contains(extension)) {
    fileContent = "data:image/$extension;base64,${base64Encode(bytes)}";
  }
  return fileContent;
}

class CreateDeckAIDialog extends StatefulWidget {
  final String? initialFileName;
  final String? initialFileText;
  final Future<String> Function(
    String topic,
    String? fileText,
    String? fileName,
  )
  onGenerate;

  const CreateDeckAIDialog({
    super.key, 
    this.initialFileName,
    this.initialFileText,
    required this.onGenerate,
  });

  @override
  State<CreateDeckAIDialog> createState() => _CreateDeckAIDialogState();
}

class _CreateDeckAIDialogState extends State<CreateDeckAIDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _deckNameController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _topicFocus = FocusNode();
  final FocusNode _promptFocus = FocusNode();

  double _numCards = 10;
  bool _isSubmitting = false;

  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  String? _selectedFileName;
  String? _extractedFileText;
  bool _isFileProcessing = false;

  final LinearGradient _brandGradient = const LinearGradient(
    colors: [Color(0xFF8B4EFF), Color(0xFFE841A1)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  void initState() {
    super.initState();
    _selectedFileName = widget.initialFileName;
    _extractedFileText = widget.initialFileText;
    _loadRewardedAd();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });

    _deckNameController.addListener(() => setState(() {}));
    _topicController.addListener(() => setState(() {}));
    _promptController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _deckNameController.dispose();
    _topicController.dispose();
    _promptController.dispose();
    _nameFocus.dispose();
    _topicFocus.dispose();
    _promptFocus.dispose();
    super.dispose();
  }

  void _loadRewardedAd() {
    if (kIsWeb) return; 

    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
        },
        onAdFailedToLoad: (err) {
          debugPrint('Failed to load a rewarded ad: ${err.message}');
          _rewardedAd = null;
          _isRewardedAdLoaded = false;
        },
      ),
    );
  }

  Future<void> _handleFileUpload() async {
    if (_isSubmitting || _isFileProcessing) return; // 🛡️ Strict lock
    
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'jpg', 'jpeg', 'png'],
        withData: true, 
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _isFileProcessing = true;
        });

        await Future.delayed(const Duration(milliseconds: 50));

        final platformFile = result.files.first;
        String fileName = platformFile.name;
        String extension = platformFile.extension?.toLowerCase() ?? '';

        // 🛡️ SECURITY FIX: Enforce a strict 5MB file size limit to prevent OOM crashes and payload limits
        final int fileSizeInBytes = platformFile.size;
        if (fileSizeInBytes > 5 * 1024 * 1024) {
          throw Exception("File is too large. Please select a file under 5MB.");
        }

        Uint8List? fileBytes = platformFile.bytes;

        if (fileBytes == null && !kIsWeb && platformFile.path != null) {
          fileBytes = await File(platformFile.path!).readAsBytes();
        }

        if (fileBytes != null) {
          String fileContent = await compute(_extractFileContentInBackground, {
            'bytes': fileBytes,
            'extension': extension,
          });

          if (mounted) {
            setState(() {
              _selectedFileName = fileName;
              _extractedFileText = fileContent;
              _isFileProcessing = false;
            });
            HapticFeedback.mediumImpact();
          }
        } else {
           throw Exception("Could not retrieve file data.");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFileProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error reading file: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  IconData _getFileIcon() {
    if (_selectedFileName == null) return Icons.upload_file_rounded;
    final ext = _selectedFileName!.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png'].contains(ext)) return Icons.image_rounded;
    if (ext == 'pdf') return Icons.picture_as_pdf_rounded;
    if (ext == 'txt') return Icons.text_snippet_rounded;
    return Icons.description_rounded;
  }

  void _submitTopic() async {
    if (_isSubmitting) return; // 🛡️ SECURITY FIX: Prevents multi-tap energy drains
    
    if (_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();

      final deckName = _deckNameController.text.trim();
      final topic = _topicController.text.trim();
      final prompt = _promptController.text.trim();
      final numCards = _numCards.toInt();

      String engineeredPrompt =
          "Create a flashcard deck named '$deckName'. Generate exactly $numCards cards.";

      if (topic.isNotEmpty) {
        engineeredPrompt += " Topic: $topic.";
      }
      if (prompt.isNotEmpty) {
        engineeredPrompt += " Additional instructions: $prompt.";
      }

      setState(() {
        _isSubmitting = true;
      });
      AILoadingOverlay.show(context, title: "Crafting Deck...", subtitle: "Generating your flashcards with AI ☕");

      try {
        final successMessage = await widget.onGenerate(
          engineeredPrompt,
          _extractedFileText,
          _selectedFileName,
        );

        if (mounted) {
          AILoadingOverlay.close(context);

          if (!ProService().isPro) {
            await ProPaywallSheet.show(
              context,
              title: "Deck Created! 🎉",
              subtitle: "Want to do this twice as much? Upgrade to Pro for double the daily AI limits and zero ads.",
            );
          }

          if (mounted) {
            Navigator.of(context).pop(successMessage);
          }
        }
      } catch (e) {
        if (mounted) {
          AILoadingOverlay.close(context);
          setState(() {
            _isSubmitting = false;
          });

          final errorStr = e.toString();
          if (errorStr.toLowerCase().contains('energy') || errorStr.contains('INSUFFICIENT_ENERGY')) {
            EnergyEmptyDialog.show(context, actionText: "Generating a deck", onWatchAd: _showRewardedAd);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorStr.replaceAll('Exception: ', '')),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      }
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  void _showRewardedAd() {
    if (kIsWeb) {
      _refillAndSubmit();
      return;
    }

    if (_isRewardedAdLoaded && _rewardedAd != null) {
      try {
        _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _rewardedAd = null;
            _isRewardedAdLoaded = false;
            _loadRewardedAd(); 
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _rewardedAd = null;
            _isRewardedAdLoaded = false;
            _loadRewardedAd();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Oh no, the ad couldn't be played. Please try again later! 🎬")),
              );
            }
          },
        );

        _rewardedAd!.show(
          onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
            await _refillAndSubmit();
          },
        );
      } catch (e) {
        _rewardedAd = null;
        _isRewardedAdLoaded = false;
        _loadRewardedAd();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Oops! The ad system hit a snag. You might have reached your daily limit. Please check back tomorrow! 🌟")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("We couldn't find an ad right now. You may have reached your daily limit (5/day) to keep the AI healthy! Please try again tomorrow. 🌟")),
      );
      _loadRewardedAd();
    }
  }

  Future<void> _refillAndSubmit() async {
    setState(() => _isSubmitting = true);
    AILoadingOverlay.show(context, title: "Refilling Energy...", subtitle: "Please wait a moment ⚡");

    try {
      final energyService = EnergyService();
      await energyService.refillEnergy();
      
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (mounted) {
        AILoadingOverlay.close(context);
        setState(() => _isSubmitting = false);
        _submitTopic(); 
      }
    } catch (e) {
      if (mounted) {
        AILoadingOverlay.close(context);
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to refill energy. Please try again.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      // 🚀 HCI OPTIMIZATION: Constrain width on Web/Desktop so bottom sheets aren't excessively wide
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: Stack(
                children: [
                  // Main Form Layer
                  SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 32.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 5,
                                  margin: const EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
    
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF8B4EFF).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.auto_awesome_rounded,
                                            color: Color(0xFF8B4EFF),
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Flexible(
                                          child: Text(
                                            "AI Generation",
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                              color: Theme.of(context).textTheme.bodyLarge?.color,
                                              letterSpacing: -0.5,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      if (!_isSubmitting) {
                                        HapticFeedback.selectionClick();
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    icon: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white12 : Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close_rounded,
                                        color: isDark ? Colors.white54 : Colors.black54,
                                        size: 20,
                                      ),
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Let MindFlash build a complete flashcard deck for you in seconds. Tell us what you want to learn or attach your notes.",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? Colors.white70 : Colors.grey[600],
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 28),
    
                              _buildInputLabel("Deck Name", Icons.style_rounded),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _deckNameController,
                                maxLength: 60,
                                focusNode: _nameFocus,
                                enabled: !_isSubmitting,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) =>
                                    FocusScope.of(context).requestFocus(_topicFocus),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter a deck name';
                                  }
                                  return null;
                                },
                                decoration: _buildInputDecoration(
                                  "e.g., CMSC 156 Midterms",
                                  _deckNameController,
                                ),
                              ),
                              const SizedBox(height: 20),
    
                              _buildInputLabel("Topic", Icons.bookmark_border_rounded),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _topicController,
                                maxLength: 200,
                                focusNode: _topicFocus,
                                enabled: !_isSubmitting,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) =>
                                    FocusScope.of(context).requestFocus(_promptFocus),
                                validator: (value) {
                                  if ((value == null || value.trim().isEmpty) &&
                                      _selectedFileName == null) {
                                    return 'Please enter a topic or attach a file';
                                  }
                                  return null;
                                },
                                decoration: _buildInputDecoration(
                                  "e.g., Core Flutter Skills...",
                                  _topicController,
                                ),
                              ),
                              const SizedBox(height: 20),
    
                              _buildInputLabel(
                                "Attach File or Photo (Optional)",
                                Icons.attach_file_rounded,
                              ),
                              const SizedBox(height: 8),
    
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isSubmitting || _isFileProcessing
                                      ? null
                                      : _handleFileUpload,
                                  borderRadius: BorderRadius.circular(16),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isFileProcessing
                                          ? const Color(0xFF8B4EFF).withValues(alpha: 0.08)
                                          : (_selectedFileName != null
                                              ? const Color(0xFF8B4EFF).withValues(alpha: 0.05)
                                              : (isDark ? const Color(0xFF1E1533) : const Color(0xFFF8F9FA))),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _isFileProcessing
                                            ? const Color(0xFF8B4EFF).withValues(alpha: 0.4)
                                            : (_selectedFileName != null
                                                ? const Color(0xFF8B4EFF)
                                                : Colors.transparent),
                                        width: 2,
                                      ),
                                    ),
                                    child: AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 200),
                                      child: _isFileProcessing
                                          ? Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              key: const ValueKey("processing"),
                                              children: [
                                                const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    color: Color(0xFF8B4EFF),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Shimmer.fromColors(
                                                  baseColor: const Color(0xFF8B4EFF),
                                                  highlightColor: const Color(0xFFE841A1),
                                                  child: const Text(
                                                    "Reading file contents...",
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Row(
                                              key: const ValueKey("idle"),
                                              children: [
                                                Icon(
                                                  _getFileIcon(),
                                                  color: _selectedFileName != null
                                                      ? const Color(0xFF8B4EFF)
                                                      : Colors.grey.shade500,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    _selectedFileName ??
                                                        "Upload PDF, TXT, or Image",
                                                    style: TextStyle(
                                                      color: _selectedFileName != null
                                                          ? Theme.of(context).textTheme.bodyLarge?.color
                                                          : Colors.grey.shade500,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          _selectedFileName != null
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (_selectedFileName != null &&
                                                    !_isSubmitting)
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.check_circle_rounded,
                                                        color: Colors.green,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.cancel,
                                                          color: Colors.grey,
                                                          size: 20,
                                                        ),
                                                        onPressed: () {
                                                          HapticFeedback.selectionClick();
                                                          setState(() {
                                                            _selectedFileName = null;
                                                            _extractedFileText = null;
                                                          });
                                                        },
                                                        padding: EdgeInsets.zero,
                                                        constraints:
                                                            const BoxConstraints(),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
    
                              _buildInputLabel(
                                "Specific Instructions (Optional)",
                                Icons.tune_rounded,
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _promptController,
                                maxLength: 500,
                                focusNode: _promptFocus,
                                enabled: !_isSubmitting,
                                textCapitalization: TextCapitalization.sentences,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submitTopic(),
                                decoration: _buildInputDecoration(
                                  "e.g., Focus only on definitions...",
                                  _promptController,
                                ),
                                maxLines: 2,
                                minLines: 1,
                              ),
                              const SizedBox(height: 28),
    
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: _buildInputLabel(
                                      "Number of Cards",
                                      Icons.layers_rounded,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8B4EFF).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "${_numCards.toInt()} Cards",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF8B4EFF),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 6.0,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 12.0,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 24.0,
                                  ),
                                  activeTickMarkColor: Colors.transparent,
                                  inactiveTickMarkColor: Colors.transparent,
                                ),
                                child: Slider(
                                  value: _numCards,
                                  min: 5,
                                  max: 50,
                                  divisions: 9,
                                  activeColor: const Color(0xFF8B4EFF),
                                  inactiveColor: const Color(0xFF8B4EFF).withValues(alpha: 0.2),
                                  onChanged: _isSubmitting
                                      ? null
                                      : (value) {
                                          if (value != _numCards) {
                                            HapticFeedback.selectionClick();
                                          }
                                          setState(() {
                                            _numCards = value;
                                          });
                                        },
                                ),
                              ),
    
                              const SizedBox(height: 32),
    
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: _isSubmitting
                                      ? LinearGradient(
                                          colors: [
                                            Colors.grey.shade400,
                                            Colors.grey.shade400,
                                          ],
                                        )
                                      : _brandGradient,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: _isSubmitting
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: const Color(0xFF8B4EFF).withValues(alpha: 0.3),
                                            blurRadius: 15,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  clipBehavior: Clip.antiAlias,
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    onTap: _isSubmitting ? null : _submitTopic,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: _isSubmitting
                                          ? const [
                                              SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2.5,
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Flexible(
                                                child: Text(
                                                  "Generating...",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    letterSpacing: 0.5,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ]
                                          : const [
                                              Icon(
                                                Icons.auto_awesome_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  "Start Generating",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                    letterSpacing: 0.5,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF8B4EFF)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(
    String hint,
    TextEditingController controller,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 15),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E1533) : const Color(0xFFF8F9FA),
      suffixIcon: controller.text.isNotEmpty && !_isSubmitting
          ? IconButton(
              icon: const Icon(Icons.cancel, color: Colors.grey, size: 20),
              onPressed: () {
                controller.clear();
                HapticFeedback.selectionClick();
              },
            )
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF8B4EFF), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }
}