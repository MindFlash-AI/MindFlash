import 'dart:ui'; // Required for ImageFilter (BackdropFilter)
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/deck_model.dart';
import '../services/ad_helper.dart';
import '../services/energy_service.dart';
import '../services/pro_service.dart'; // Added to check Pro status
import '../screens/settings/manage_subscription_screen.dart'; // For the Pro Upgrade routing
import 'pro_paywall_sheet.dart'; // The Universal Paywall Widget

class UpdateDeckAIDialog extends StatefulWidget {
  final List<Deck> decks;
  final Future<String> Function(Deck deck, String topic) onGenerate;

  const UpdateDeckAIDialog({
    super.key,
    required this.decks,
    required this.onGenerate,
  });

  @override
  State<UpdateDeckAIDialog> createState() => _UpdateDeckAIDialogState();
}

class _UpdateDeckAIDialogState extends State<UpdateDeckAIDialog> {
  final _formKey = GlobalKey<FormState>();
  Deck? _selectedDeck;
  final TextEditingController _topicController = TextEditingController();
  bool _isSubmitting = false;

  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
    if (widget.decks.isNotEmpty) {
      _selectedDeck = widget.decks.first;
    }
    _topicController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _topicController.dispose();
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

  // 🛡️ BUG FIX: Robust routing to prevent infinite loading screens
  void _showLoadingOverlay({bool isRefilling = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      routeSettings: const RouteSettings(name: 'loading_overlay'), 
      builder: (ctx) => PopScope(
        canPop: false, 
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.85),
              width: double.infinity,
              height: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      color: Color(0xFFE940A3),
                      strokeWidth: 4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isRefilling ? "Refilling Energy..." : "Updating Deck...",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isRefilling 
                        ? "Please wait a moment ⚡" 
                        : "Adding new flashcards with AI ☕",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
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

  // 🛡️ BUG FIX: Safely hunts down and destroys ONLY the loading overlay
  void _closeLoadingOverlay() {
    bool foundOverlay = false;
    Navigator.of(context).popUntil((route) {
      if (route.settings.name == 'loading_overlay') {
        foundOverlay = true;
        return true;
      }
      if (route.isFirst) {
        return true; 
      }
      return false; 
    });
    
    if (foundOverlay) {
      Navigator.of(context).pop();
    }
  }

  void _submitUpdate() async {
    if (_formKey.currentState!.validate() && _selectedDeck != null) {
      setState(() {
        _isSubmitting = true;
      });

      _showLoadingOverlay();

      final topic = _topicController.text.trim();

      try {
        final successMessage = await widget.onGenerate(_selectedDeck!, topic);
        if (mounted) {
          _closeLoadingOverlay(); 
          
          // 🌟 POST-SUCCESS PAYWALL TRIGGER
          if (!ProService().isPro) {
            await ProPaywallSheet.show(
              context,
              title: "Deck Updated! 🎉",
              subtitle: "Want to do this twice as much? Upgrade to Pro for double the daily AI limits and zero ads.",
            );
          }

          if (mounted) {
            Navigator.of(context).pop(successMessage); 
          }
        }
      } catch (e) {
        if (mounted) {
          _closeLoadingOverlay(); 
          setState(() {
            _isSubmitting = false;
          });

          final errorStr = e.toString();
          if (errorStr.toLowerCase().contains('energy') || errorStr.contains('INSUFFICIENT_ENERGY')) {
            _showEnergyAdDialog();
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
    }
  }

  // 🛡️ BUG FIX: Changed AlertDialog to a Dialog to fix full-width buttons layout
  void _showEnergyAdDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (ctx) => Dialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: Colors.orange, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    "Out of Energy", 
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "Updating a deck costs 3 energy. Watch a quick ad to refill your energy, or upgrade to MindFlash Pro for double the daily limit and no ads!",
                style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showRewardedAd();
                },
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: const Text("Watch Ad to Refill", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE940A3),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManageSubscriptionScreen()),
                  );
                },
                icon: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF8B4EFF)),
                label: const Text("Upgrade to Pro", style: TextStyle(color: Color(0xFF8B4EFF), fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B4EFF).withOpacity(0.1),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 8),
              
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
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
                const SnackBar(content: Text("Failed to show ad. Please try again.")),
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
          const SnackBar(content: Text("Ad system error. Please try again.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ad is still loading, please try again in a moment.")),
      );
      _loadRewardedAd();
    }
  }

  Future<void> _refillAndSubmit() async {
    setState(() => _isSubmitting = true);
    
    _showLoadingOverlay(isRefilling: true);

    try {
      final energyService = EnergyService();
      await energyService.refillEnergy();
      
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (mounted) {
        _closeLoadingOverlay(); 
        setState(() => _isSubmitting = false);
        _submitUpdate(); 
      }
    } catch (e) {
      if (mounted) {
        _closeLoadingOverlay(); 
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
    
    if (widget.decks.isEmpty) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.layers_clear, size: 48, color: isDark ? Colors.white38 : Colors.grey),
              const SizedBox(height: 16),
              Text(
                "No Decks Available",
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please create a deck first before generating AI cards.",
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  "Close",
                  style: TextStyle(color: Color(0xFFE940A3)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Stack(
            children: [
              // Main Form Layer
              SafeArea(
                top: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 32.0,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE940A3).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.auto_awesome,
                                        color: Color(0xFFE940A3),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        "Update with AI",
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  if (!_isSubmitting) Navigator.of(context).pop();
                                },
                                icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.grey),
                                tooltip: 'Close',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Select an existing deck and tell MindFlash what new flashcards you want to add to it.",
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.grey[600],
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),

                          Text(
                            "SELECT DECK",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<Deck>(
                            value: _selectedDeck,
                            isExpanded: true,
                            dropdownColor: Theme.of(context).cardColor,
                            items: widget.decks.map((deck) {
                              return DropdownMenuItem<Deck>(
                                value: deck,
                                child: Text(
                                  deck.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                                ),
                              );
                            }).toList(),
                            onChanged: _isSubmitting
                                ? null
                                : (Deck? newValue) {
                                    setState(() {
                                      _selectedDeck = newValue;
                                    });
                                  },
                            validator: (value) =>
                                value == null ? 'Please select a deck' : null,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E1533) : const Color(0xFFF5F5F5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE940A3),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey,
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            "WHAT SHOULD WE ADD?",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _topicController,
                            autofocus: true,
                            textInputAction: TextInputAction.send,
                            enabled: !_isSubmitting,
                            onFieldSubmitted: (_) => _submitUpdate(),
                            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a topic to add';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: "e.g., More about widgets...",
                              hintStyle: TextStyle(
                                color: isDark ? Colors.white38 : Colors.grey[500],
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF1E1533) : const Color(0xFFF5F5F5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE940A3),
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 1,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              suffixIcon:
                                  _topicController.text.isNotEmpty && !_isSubmitting
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.cancel,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                      onPressed: () => _topicController.clear(),
                                    )
                                  : null,
                            ),
                            maxLines: 2,
                            minLines: 1,
                          ),

                          const SizedBox(height: 30),

                          Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isSubmitting
                                    ? [Colors.grey.shade400, Colors.grey.shade400]
                                    : [
                                        const Color(0xFFE940A3),
                                        const Color(0xFFFF5DAD),
                                      ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: _isSubmitting
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: const Color(0xFFE940A3).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isSubmitting ? null : _submitUpdate,
                                borderRadius: BorderRadius.circular(16),
                                child: Center(
                                  child: _isSubmitting
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
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
                                                "Crafting cards...",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Text(
                                          "Generate New Cards",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
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
            ],
          ),
        ),
      ),
    );
  }
}