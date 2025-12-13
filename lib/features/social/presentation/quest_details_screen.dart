import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:travel_hackathon/core/theme/premium_theme.dart';
import 'package:travel_hackathon/features/social/domain/quest_model.dart';
import 'package:travel_hackathon/features/social/presentation/social_providers.dart';
import 'package:travel_hackathon/features/auth/presentation/auth_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';

class QuestDetailsScreen extends ConsumerWidget {
  final String city;

  const QuestDetailsScreen({required this.city, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questAsync = ref.watch(questForCityProvider(city));

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.grey[100],
      body: questAsync.when(
        data: (quest) {
          if (quest == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.explore_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text("Quest not found for $city", style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }
          return _QuestContent(quest: quest);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _QuestContent extends ConsumerStatefulWidget {
  final Quest quest;

  const _QuestContent({required this.quest});

  @override
  ConsumerState<_QuestContent> createState() => _QuestContentState();
}

class _QuestContentState extends ConsumerState<_QuestContent> {
  String? _selectedStepId;
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  bool _isExpanded = false;
  
  // Quest progress state
  bool _isJoined = false;
  bool _isCompleted = false;
  Set<String> _completedStepIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final userId = ref.read(currentUserProvider);
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final repo = ref.read(socialRepositoryProvider);
      debugPrint('Loading progress for userId: $userId, questId: ${widget.quest.id}');
      final progress = await repo.getQuestProgress(userId, widget.quest.id);
      debugPrint('Progress response: $progress');
      setState(() {
        _isJoined = progress['isJoined'] == true;
        _isCompleted = progress['isCompleted'] == true;
        final completedSteps = progress['completedSteps'] as List? ?? [];
        debugPrint('Completed steps from backend: $completedSteps');
        _completedStepIds = completedSteps.map((e) => e['stepId'] as String).toSet();
        debugPrint('Parsed step IDs: $_completedStepIds');
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading progress: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinQuest() async {
    final userId = ref.read(currentUserProvider);
    if (userId == null) return;
    
    setState(() => _isLoading = true);
    try {
      await ref.read(socialRepositoryProvider).joinQuest(userId, widget.quest.id);
      setState(() {
        _isJoined = true;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🎉 Quest joined! Start exploring!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _quitQuest() async {
    final userId = ref.read(currentUserProvider);
    if (userId == null) return;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quit Quest?'),
        content: const Text('Your progress will be reset. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() => _isLoading = true);
    try {
      await ref.read(socialRepositoryProvider).quitQuest(userId, widget.quest.id);
      setState(() {
        _isJoined = false;
        _completedStepIds.clear();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeStep(QuestStep step) async {
    final userId = ref.read(currentUserProvider);
    if (userId == null || !_isJoined) return;
    
    // Don't allow re-checking already completed steps
    if (_completedStepIds.contains(step.id)) return;
    
    try {
      final result = await ref.read(socialRepositoryProvider).completeStep(
        userId, widget.quest.id, step.id
      );
      
      setState(() {
        _completedStepIds.add(step.id);
      });
      
      // Check completion from backend response or local count
      final isComplete = result['isQuestComplete'] == true || 
                         _completedStepIds.length >= widget.quest.steps.length;
      
      debugPrint('Step completed: ${step.title}, isQuestComplete: ${result['isQuestComplete']}, local: ${_completedStepIds.length}/${widget.quest.steps.length}');
      
      if (isComplete) {
        _showCompletionCelebration();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ ${step.title} completed! +${step.points} XP'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      debugPrint('Error completing step: $e');
    }
  }

  void _showCompletionCelebration() {
    setState(() => _isCompleted = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.amber, Colors.orange]),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emoji_events, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                '🎉 Quest Complete!',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'You explored ${widget.quest.city} and earned',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  widget.quest.reward,
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Continue Exploring', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Type-based colors
  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'food': return const Color(0xFFFF6B6B);
      case 'history': return const Color(0xFF4ECDC4);
      case 'culture': return const Color(0xFFFFD93D);
      case 'nature': return const Color(0xFF6BCB77);
      default: return PremiumTheme.primary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'food': return Icons.restaurant;
      case 'history': return Icons.account_balance;
      case 'culture': return Icons.theater_comedy;
      case 'nature': return Icons.park;
      default: return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.quest.steps;
    if (steps.isEmpty) {
      return const Center(child: Text("No steps in this quest."));
    }

    final center = LatLng(steps.first.latitude, steps.first.longitude);

    return Stack(
      children: [
        // 1. Full Screen Map with Custom Style
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 12.5,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          ),
          children: [
            // Light themed map
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.example.travel_hackathon',
            ),
            // Polyline connecting steps
            PolylineLayer(
              polylines: [
                Polyline(
                  points: steps.map((s) => LatLng(s.latitude, s.longitude)).toList(),
                  color: PremiumTheme.primary.withOpacity(0.5),
                  strokeWidth: 3,
                ),
              ],
            ),
            // Markers
            MarkerLayer(
              markers: steps.asMap().entries.map((entry) {
                final index = entry.key;
                final step = entry.value;
                final isSelected = _selectedStepId == step.id;
                final color = _getTypeColor(step.type);

                return Marker(
                  point: LatLng(step.latitude, step.longitude),
                  width: isSelected ? 56 : 44,
                  height: isSelected ? 56 : 44,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedStepId = step.id);
                      _showStepDetails(context, step, index + 1);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: isSelected ? 4 : 3),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: isSelected ? 16 : 8,
                            spreadRadius: isSelected ? 2 : 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: isSelected
                            ? Icon(_getTypeIcon(step.type), color: Colors.white, size: 24)
                            : Text(
                                '${index + 1}',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ).animate(target: isSelected ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
                );
              }).toList(),
            ),
          ],
        ),

        // 2. Back Button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),

        // 3. Title Header Card
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          left: 70,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.quest.title,
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${steps.length} stops • ${widget.quest.city}',
                            style: GoogleFonts.dmSans(fontSize: 12, color: Colors.grey[600]),
                          ),
                          if (_isCompleted) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('✓ Complete', style: GoogleFonts.outfit(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                else if (!_isJoined)
                  GestureDetector(
                    onTap: _joinQuest,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Join', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(widget.quest.reward, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _quitQuest,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, color: Colors.red.shade400, size: 16),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        // 4. Quest Info Sheet
        DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: 0.40,
          minChildSize: 0.15,
          maxChildSize: 0.95,
          snap: true,
          snapSizes: const [0.15, 0.40, 0.95],
          builder: (context, scrollController) {
            final completedCount = steps.where((s) => s.isCompleted).length;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, -5))],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 80),
                children: [
                  // Expand/Collapse Handle
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() => _isExpanded = !_isExpanded);
                      _sheetController.animateTo(
                        _isExpanded ? 0.95 : 0.40,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: PremiumTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                                size: 18,
                                color: PremiumTheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isExpanded ? "Collapse" : "Expand",
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: PremiumTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Title & City
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.quest.title,
                              style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text(widget.quest.city, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // XP Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.white, size: 18),
                            const SizedBox(width: 4),
                            Text(widget.quest.reward, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    widget.quest.description,
                    style: GoogleFonts.dmSans(color: Colors.grey[600], height: 1.6, fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  // Progress Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Progress", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                            Text("${_completedStepIds.length} / ${steps.length}", style: GoogleFonts.outfit(color: PremiumTheme.primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: steps.isNotEmpty ? _completedStepIds.length / steps.length : 0,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation(PremiumTheme.primary),
                            minHeight: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Steps Header
                  Row(
                    children: [
                      Icon(Icons.route, color: PremiumTheme.primary),
                      const SizedBox(width: 8),
                      Text("Your Journey", style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Step Cards
                  ...steps.asMap().entries.map((entry) => _buildStepCard(entry.key, entry.value)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStepCard(int index, QuestStep step) {
    final isSelected = _selectedStepId == step.id;
    final color = _getTypeColor(step.type);
    final isStepCompleted = _completedStepIds.contains(step.id);

    return GestureDetector(
      onTap: () {
        setState(() => _selectedStepId = step.id);
        _mapController.move(LatLng(step.latitude, step.longitude), 15);
        // Auto-collapse sheet to show map
        if (_isExpanded) {
          setState(() => _isExpanded = false);
          _sheetController.animateTo(
            0.30,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isStepCompleted 
              ? Colors.green.shade50 
              : (isSelected ? color.withOpacity(0.08) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isStepCompleted ? Colors.green : (isSelected ? color : Colors.grey[200]!), 
            width: isSelected ? 2 : 1
          ),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8)] : null,
        ),
        child: Row(
          children: [
            // Number Badge
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: isStepCompleted 
                    ? LinearGradient(colors: [Colors.green, Colors.green.shade400])
                    : LinearGradient(colors: [color, color.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: isStepCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 22)
                    : Text(
                        '${index + 1}',
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title, 
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600, 
                      fontSize: 15,
                      decoration: isStepCompleted ? TextDecoration.lineThrough : null,
                      color: isStepCompleted ? Colors.grey[600] : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(_getTypeIcon(step.type), size: 14, color: isStepCompleted ? Colors.grey : color),
                      const SizedBox(width: 4),
                      Text(
                        step.type.toUpperCase(),
                        style: GoogleFonts.dmSans(fontSize: 11, color: isStepCompleted ? Colors.grey : color, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      const Spacer(),
                      if (isStepCompleted)
                        Text("✓ Done", style: GoogleFonts.outfit(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold))
                      else
                        Text("+${step.points} XP", style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Action Button or Status
            if (!isStepCompleted && _isJoined)
              GestureDetector(
                onTap: () => _completeStep(step),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Check In',
                    style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              )
            else if (isStepCompleted)
              Icon(Icons.check_circle, color: Colors.green, size: 28)
            else
              Icon(Icons.circle_outlined, color: Colors.grey[300]),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 50)).slideX(begin: 0.1);
  }

  void _showStepDetails(BuildContext context, QuestStep step, int stepNumber) {
    final color = _getTypeColor(step.type);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with color
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(2))),
                      // Close Button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                        child: Text("STEP $stepNumber", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            Icon(_getTypeIcon(step.type), color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(step.type.toUpperCase(), style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(step.title, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.description, style: GoogleFonts.dmSans(fontSize: 15, height: 1.6, color: Colors.grey[700])),
                    const SizedBox(height: 20),

                    // Clue Card
                    _buildInfoCard(
                      icon: Icons.lightbulb_outline,
                      title: "Clue",
                      content: step.clue,
                      bgColor: Colors.amber[50]!,
                      iconColor: Colors.amber[700]!,
                      borderColor: Colors.amber[200]!,
                    ),
                    const SizedBox(height: 12),

                    // Must Try Card
                    if (step.mustTry.isNotEmpty)
                      _buildInfoCard(
                        icon: Icons.favorite_outline,
                        title: "Must Try",
                        content: step.mustTry,
                        bgColor: Colors.pink[50]!,
                        iconColor: Colors.pink[400]!,
                        borderColor: Colors.pink[200]!,
                      ),
                  ],
                ),
              ),
            ),

            // Check In Button
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).padding.bottom + 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 8),
                            Text("Checked in at ${step.title}!"),
                          ],
                        ),
                        backgroundColor: color,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on),
                      const SizedBox(width: 8),
                      Text("Check In Here", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color bgColor,
    required Color iconColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: iconColor)),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: GoogleFonts.dmSans(color: Colors.grey[800], height: 1.5)),
        ],
      ),
    );
  }
}
