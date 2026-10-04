import 'package:flutter/material.dart';
import '../models/gesture.dart';
import '../models/gesture_category.dart';
import '../utils/constants.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/esenyas_app_bar.dart';

/// Gesture guide data matching the React prototype.
const _gestureCategories = [
  GestureCategory(
    category: 'Basic Greetings',
    emoji: '👋',
    gestures: [
      Gesture(name: 'Kumusta', description: 'Pagbati sa kapwa; pagtanong kung kumusta ang lagay', tip: 'Gamitin ang kamay na nakaangat sa tainga, parang telepono', imageUrl: ''),
      Gesture(name: 'Magandang Umaga', description: 'Pagbati sa umaga; ginagamit mula 6AM hanggang 12NN', tip: 'Galawin ang kamay mula sa ibaba pataas, tulad ng sikat ng araw', imageUrl: ''),
      Gesture(name: 'Magandang Hapon', description: 'Pagbati sa hapon; ginagamit mula 12NN hanggang 6PM', tip: 'Kamay na pahalang sa itaas ng ulo, tulad ng init ng araw', imageUrl: ''),
      Gesture(name: 'Magandang Gabi', description: 'Pagbati sa gabi; ginagamit mula 6PM pataas', tip: 'Galawin ang kamay pababa, tulad ng paglubog ng araw', imageUrl: ''),
      Gesture(name: 'Paalam', description: 'Pagpapaalam sa kapwa; pagsasabi ng goodbye', tip: 'Kamay na kumakaway mula kanan pakaliwa', imageUrl: ''),
    ],
  ),
  GestureCategory(
    category: 'Common Expressions',
    emoji: '💬',
    gestures: [
      Gesture(name: 'Salamat', description: 'Pagpapakita ng pasasalamat at paggalang sa tulong o kabutihan', tip: 'Hawakan ang dibdib at ilipat ang kamay palapit sa taong kausap', imageUrl: ''),
      Gesture(name: 'Walang Anuman', description: 'Pagsagot sa pasasalamat; ibig sabihin ay "okay lang"', tip: 'Kamay na parang nagwawalis sa harap', imageUrl: ''),
      Gesture(name: 'Paumanhin', description: 'Paghingi ng tawad o pagpapakita ng pagsisisi', tip: 'Kamay na kumukusot sa dibdib, parang hinahaplos ang puso', imageUrl: ''),
      Gesture(name: 'Oo', description: 'Pagsang-ayon o pag-amin sa isang bagay', tip: 'Ulo na tumutango o kamay na umaangat at bumababa', imageUrl: ''),
      Gesture(name: 'Hindi', description: 'Pagtanggi o pagsalungat sa isang bagay', tip: 'Ulo na umiling o kamay na umalog mula kanan pakaliwa', imageUrl: ''),
      Gesture(name: 'Tulong', description: 'Paghiling ng saklolo o suporta sa kapwa', tip: 'Isang kamay na nakaangat, parang umabot sa kawalan', imageUrl: ''),
    ],
  ),
  GestureCategory(
    category: 'Daily Communication',
    emoji: '🗣️',
    gestures: [
      Gesture(name: 'Gutom', description: 'Nararamdamang pangangailangan ng pagkain', tip: 'Kamay na hawak sa tiyan at gumagalaw paikot', imageUrl: ''),
      Gesture(name: 'Kain', description: 'Aksyon ng pagkain o pag-imbita na kumain', tip: 'Kamay na parang kumuha ng pagkain at inilapit sa bibig', imageUrl: ''),
      Gesture(name: 'Inom', description: 'Aksyon ng pag-inom ng tubig o anumang inumin', tip: 'Kamay na parang may hawak na baso at uminom', imageUrl: ''),
      Gesture(name: 'Masakit', description: 'Nararamdamang sakit o kirot sa katawan', tip: 'Dalawang kamay na nagtuturo sa bahagi ng masakit', imageUrl: ''),
      Gesture(name: 'Ayos Lang', description: 'Pagpapahayag na wala namang problema o okay lang', tip: 'Hinlalaki na nakatayo, o kamay na parang okay sign', imageUrl: ''),
      Gesture(name: 'Saan', description: 'Pagtanong ng lokasyon o lugar', tip: 'Daliri na nagtuturo sa iba\'t ibang direksyon', imageUrl: ''),
      Gesture(name: 'Pangalan', description: 'Pagtanong o pagsasabi ng ngalan ng tao', tip: 'Dalawang daliri na nagsasalubong sa harap ng dibdib', imageUrl: ''),
      Gesture(name: 'Mahal Kita', description: 'Pagpapahayag ng pagmamahal sa isang tao', tip: 'Dalawang kamay na nag-cross sa dibdib', imageUrl: ''),
    ],
  ),
];

/// Gesture Guide screen with category chips, 2-column grid, and detail modal.
///
/// Recreates GestureGuideScreen.tsx.
class GestureGuideScreen extends StatefulWidget {
  const GestureGuideScreen({super.key});

  @override
  State<GestureGuideScreen> createState() => _GestureGuideScreenState();
}

class _GestureGuideScreenState extends State<GestureGuideScreen> {
  String? _activeCategory;
  Gesture? _selectedGesture;

  List<GestureCategory> get _filtered {
    return _gestureCategories
        .where((cat) => _activeCategory == null || cat.category == _activeCategory)
        .toList();
  }

  int get _totalGestures =>
      _gestureCategories.fold(0, (sum, c) => sum + c.gestures.length);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ESenyasAppBar(title: 'Gesture Guide'),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    color: ESenyasColors.surfaceBlueLight,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Gradient header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  ESenyasColors.primaryBlue,
                                  ESenyasColors.accentGreen,
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Filipino Sign Language Guide',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Matuto ng mga pangunahing FSL gestures para sa araw-araw na komunikasyon',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Category chips
                          Container(
                            color: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _CategoryChip(
                                    label: 'Lahat ($_totalGestures)',
                                    active: _activeCategory == null,
                                    onTap: () =>
                                        setState(() => _activeCategory = null),
                                  ),
                                  ..._gestureCategories.map((cat) =>
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 8),
                                        child: _CategoryChip(
                                          label: '${cat.emoji} ${cat.category}',
                                          active: _activeCategory ==
                                              cat.category,
                                          onTap: () => setState(() {
                                            _activeCategory =
                                                _activeCategory ==
                                                        cat.category
                                                    ? null
                                                    : cat.category;
                                          }),
                                        ),
                                      )),
                                ],
                              ),
                            ),
                          ),

                          // Gesture grid
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: _filtered.isNotEmpty
                                ? Column(
                                    children: _filtered.map((category) {
                                      return _CategorySection(
                                        category: category,
                                        onGestureTap: (g) => setState(
                                            () => _selectedGesture = g),
                                      );
                                    }).toList(),
                                  )
                                : _EmptyGuide(),
                          ),

                          // Learning tip
                          Container(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  ESenyasColors.primaryBlue,
                                  ESenyasColors.accentGreen,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                  ESenyasDimens.borderRadiusLg),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '💡 Tip sa Pag-aaral',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Magsanay nang regular. Gamitin ang camera sa Translate tab para makita kung tama ang iyong gesture!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Detail bottom sheet
                  if (_selectedGesture != null)
                    _GestureDetailSheet(
                      gesture: _selectedGesture!,
                      onClose: () =>
                          setState(() => _selectedGesture = null),
                    ),
                ],
              ),
            ),
            const ESenyasBottomNavBar(currentIndex: 1),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? ESenyasColors.primaryBlue : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: active ? Colors.white : ESenyasColors.gray600,
          ),
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final GestureCategory category;
  final ValueChanged<Gesture> onGestureTap;

  const _CategorySection({
    required this.category,
    required this.onGestureTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Text(category.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                category.category,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: ESenyasColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Divider(
                  color: ESenyasColors.primaryBlue.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2-column grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: category.gestures.length,
            itemBuilder: (context, index) {
              final gesture = category.gestures[index];
              return _GestureCard(
                gesture: gesture,
                onTap: () => onGestureTap(gesture),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GestureCard extends StatelessWidget {
  final Gesture gesture;
  final VoidCallback onTap;

  const _GestureCard({required this.gesture, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ESenyasDimens.borderRadiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder with gradient
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ESenyasColors.primaryBlue,
                      ESenyasColors.accentGreen,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(Icons.back_hand, size: 32, color: Colors.white54),
                    ),
                    // Gradient overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Name overlay
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Text(
                        gesture.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Description + tip
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gesture.description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: ESenyasColors.gray600,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (gesture.tip != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.info_outline,
                                size: 10, color: ESenyasColors.accentGreen),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              gesture.tip!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: ESenyasColors.accentGreen,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _EmptyGuide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ESenyasDimens.borderRadiusLg),
      ),
      child: Column(
        children: [
          const Icon(Icons.back_hand, size: 48, color: ESenyasColors.gray300),
          const SizedBox(height: 12),
          const Text(
            'Walang nahanap',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: ESenyasColors.gray500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Subukan ang ibang kategorya',
            style: TextStyle(fontSize: 12, color: ESenyasColors.gray400),
          ),
        ],
      ),
    );
  }
}

class _GestureDetailSheet extends StatelessWidget {
  final Gesture gesture;
  final VoidCallback onClose;

  const _GestureDetailSheet({
    required this.gesture,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping sheet
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFF5F5F5)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          gesture.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: ESenyasColors.primaryBlue,
                          ),
                        ),
                        GestureDetector(
                          onTap: onClose,
                          child: const Text(
                            '×',
                            style: TextStyle(
                              fontSize: 24,
                              color: ESenyasColors.gray400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image placeholder
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    ESenyasColors.primaryBlue,
                                    ESenyasColors.accentGreen,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                    ESenyasDimens.borderRadiusLg),
                              ),
                              child: const Center(
                                child: Icon(Icons.back_hand,
                                    size: 48, color: Colors.white54),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description
                          const Text(
                            'Kahulugan',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: ESenyasColors.gray900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            gesture.description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: ESenyasColors.gray600,
                              height: 1.6,
                            ),
                          ),

                          // Tip
                          if (gesture.tip != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: ESenyasColors.surfaceBlueLight,
                                borderRadius: BorderRadius.circular(
                                    ESenyasDimens.borderRadiusMd),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(Icons.info_outline,
                                        size: 16,
                                        color: ESenyasColors.primaryBlue),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Paano Gawin',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: ESenyasColors.primaryBlue,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          gesture.tip!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: ESenyasColors.gray700,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
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
}
