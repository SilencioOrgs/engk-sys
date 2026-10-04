import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/history_entry.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/confidence_badge.dart';
import '../widgets/esenyas_app_bar.dart';
import '../widgets/section_header.dart';

/// Translation history list screen.
///
/// Recreates HistoryScreen.tsx with header band, history cards,
/// delete with confirmation, and clear‐all functionality.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _showClearConfirm = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final darkMode = provider.darkMode;
    final items = provider.historyItems;
    final headerBg =
        darkMode ? ESenyasColors.primaryBlueDark : ESenyasColors.primaryBlue;
    final bodyBg =
        darkMode ? ESenyasColors.backgroundDark : ESenyasColors.backgroundLight;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ESenyasAppBar(title: 'Kasaysayan ng Pagsasalin', showBack: false),
            Expanded(
              child: Container(
                color: bodyBg,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header band
                      Container(
                        color: headerBg,
                        width: double.infinity,
                        padding:
                            const EdgeInsets.fromLTRB(16, 12, 16, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kabuuan',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            Text(
                              '${items.length} ${items.length == 1 ? 'Talaan' : 'Mga Talaan'}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Rounded cutout
                      Container(
                        height: 20,
                        color: headerBg,
                        child: Container(
                          decoration: BoxDecoration(
                            color: bodyBg,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            // Section header
                            SectionHeader(
                              text: 'Mga Naisaling Pangungusap',
                              trailing: items.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () => setState(
                                          () => _showClearConfirm = true),
                                      child: Text(
                                        'Burahin Lahat',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: darkMode
                                              ? const Color(0xFFF87171)
                                              : ESenyasColors.destructiveRed,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 12),

                            // Clear confirmation
                            if (_showClearConfirm)
                              _ClearConfirmCard(
                                darkMode: darkMode,
                                onCancel: () =>
                                    setState(() => _showClearConfirm = false),
                                onConfirm: () {
                                  provider.clearHistory();
                                  setState(() => _showClearConfirm = false);
                                },
                              ),

                            // Empty state
                            if (items.isEmpty)
                              _EmptyState(darkMode: darkMode),

                            // History cards
                            ...items.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _HistoryCard(
                                    item: item,
                                    darkMode: darkMode,
                                    onDelete: () =>
                                        provider.deleteHistoryItem(item.id),
                                  ),
                                )),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const ESenyasBottomNavBar(currentIndex: 2),
          ],
        ),
      ),
    );
  }
}

class _ClearConfirmCard extends StatelessWidget {
  final bool darkMode;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const _ClearConfirmCard({
    required this.darkMode,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkMode
            ? const Color(0xFF7F1D1D).withValues(alpha: 0.2)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(ESenyasDimens.borderRadiusMd),
        border: Border.all(
          color: darkMode
              ? const Color(0xFF991B1B).withValues(alpha: 0.4)
              : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.warning_amber_rounded,
                size: 18, color: ESenyasColors.destructiveRed),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Burahin ang lahat ng kasaysayan?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: darkMode
                        ? const Color(0xFFFCA5A5)
                        : const Color(0xFFB91C1C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hindi na mababawi ang aksyon na ito.',
                  style: TextStyle(
                    fontSize: 12,
                    color: darkMode
                        ? const Color(0xFFF87171).withValues(alpha: 0.7)
                        : const Color(0xFFEF4444).withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _SmallButton(
                      label: 'Kanselahin',
                      onTap: onCancel,
                      darkMode: darkMode,
                      isDestructive: false,
                    ),
                    const SizedBox(width: 8),
                    _SmallButton(
                      label: 'Burahin Lahat',
                      onTap: onConfirm,
                      darkMode: darkMode,
                      isDestructive: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool darkMode;
  final bool isDestructive;

  const _SmallButton({
    required this.label,
    required this.onTap,
    required this.darkMode,
    required this.isDestructive,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDestructive
              ? ESenyasColors.destructiveRed
              : (darkMode ? ESenyasColors.gray700 : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: isDestructive
              ? null
              : Border.all(
                  color: darkMode
                      ? Colors.transparent
                      : const Color(0xFFE5E7EB),
                ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDestructive
                ? Colors.white
                : (darkMode ? const Color(0xFFD1D5DB) : ESenyasColors.gray600),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool darkMode;

  const _EmptyState({required this.darkMode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: darkMode ? ESenyasColors.cardDark : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history,
              size: 28,
              color: darkMode ? ESenyasColors.gray600 : ESenyasColors.gray300,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Walang Kasaysayan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: darkMode ? ESenyasColors.gray400 : ESenyasColors.gray500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ang mga naisaling senyas ay lilitaw dito',
            style: TextStyle(
              fontSize: 12,
              color: darkMode ? ESenyasColors.gray600 : ESenyasColors.gray400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatefulWidget {
  final HistoryEntry item;
  final bool darkMode;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.item,
    required this.darkMode,
    required this.onDelete,
  });

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _confirmDelete = false;

  String _formatTimestamp(DateTime dt) {
    return DateFormat('MMM d, y, h:mm a', 'en_US').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final dm = widget.darkMode;

    return Container(
      decoration: BoxDecoration(
        color: dm ? ESenyasColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(ESenyasDimens.borderRadiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        border: const Border(
          left: BorderSide(color: ESenyasColors.primaryBlue, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sentence + timestamp
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.translatedSentence,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: dm ? Colors.white : ESenyasColors.gray900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTimestamp(widget.item.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: dm ? ESenyasColors.gray500 : ESenyasColors.gray400,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: dm ? ESenyasColors.gray700 : const Color(0xFFF5F5F5),
          ),

          // Detected signs
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MGA NATUKOY NA SENYAS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.55,
                    color: dm
                        ? ESenyasColors.lightBlueText
                        : ESenyasColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 6),
                ...widget.item.detectedSigns.map(
                  (sign) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: ESenyasColors.accentGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sign.sign,
                            style: TextStyle(
                              fontSize: 13,
                              color: dm
                                  ? const Color(0xFFE5E7EB)
                                  : ESenyasColors.gray800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ConfidenceBadge(value: sign.confidence),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: dm ? ESenyasColors.gray700 : const Color(0xFFF5F5F5),
          ),

          // Delete action
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: _confirmDelete
                  ? [
                      Text(
                        'Tanggalin?',
                        style: TextStyle(
                          fontSize: 12,
                          color: dm
                              ? ESenyasColors.gray400
                              : ESenyasColors.gray500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SmallButton(
                        label: 'Hindi',
                        onTap: () =>
                            setState(() => _confirmDelete = false),
                        darkMode: dm,
                        isDestructive: false,
                      ),
                      const SizedBox(width: 8),
                      _SmallButton(
                        label: 'Oo, Tanggalin',
                        onTap: widget.onDelete,
                        darkMode: dm,
                        isDestructive: true,
                      ),
                    ]
                  : [
                      GestureDetector(
                        onTap: () =>
                            setState(() => _confirmDelete = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: dm
                                ? const Color(0xFF7F1D1D).withValues(alpha: 0.2)
                                : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 13,
                                color: dm
                                    ? const Color(0xFFF87171)
                                    : ESenyasColors.destructiveRed,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Tanggalin',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: dm
                                      ? const Color(0xFFF87171)
                                      : ESenyasColors.destructiveRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
            ),
          ),
        ],
      ),
    );
  }
}
