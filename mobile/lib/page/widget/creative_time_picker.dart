import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';

class CreativeTimePicker extends StatefulWidget {
  final DateTime? initialTime;
  final Function(DateTime time, String? name) onTimeSelected;
  final VoidCallback? onCancelled;

  const CreativeTimePicker({
    Key? key,
    this.initialTime,
    required this.onTimeSelected,
    this.onCancelled,
  }) : super(key: key);

  @override
  State<CreativeTimePicker> createState() => _CreativeTimePickerState();
}

class _CreativeTimePickerState extends State<CreativeTimePicker>
    with SingleTickerProviderStateMixin {
  late int _hour;
  late int _minute;
  late bool _isAm;
  String? _draggingType; // 'hour' | 'minute' | null
  bool _alarmSet = false;
  final TextEditingController _nameController = TextEditingController();
  bool _showNameInput = false;

  // Theme colors
  late List<Color> _bgColors;
  late Color _accentColor;
  late Color _knobColor;
  late IconData _themeIcon;
  late Color _themeIconColor;

  @override
  void initState() {
    super.initState();
    final initTime = widget.initialTime ?? DateTime.now();
    _hour = initTime.hour > 12
        ? initTime.hour - 12
        : (initTime.hour == 0 ? 12 : initTime.hour);
    _minute = initTime.minute;
    _isAm = initTime.hour < 12;
    _updateTheme();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateTheme() {
    int realHour = _isAm
        ? (_hour == 12 ? 0 : _hour)
        : (_hour == 12 ? 12 : _hour + 12);

    if (realHour >= 5 && realHour < 7) {
      // Dawn
      _bgColors = [
        const Color(0xFF312E81), // indigo-900
        const Color(0xFF6B21A8), // purple-800
        const Color(0xFFEC4899), // pink-500
      ];
      _accentColor = const Color(0xFFF9A8D4); // pink-300
      _knobColor = const Color(0xFFF472B6); // pink-400
      _themeIcon = Icons.wb_sunny;
      _themeIconColor = const Color(0xFFFBCFE8); // pink-200
    } else if (realHour >= 7 && realHour < 17) {
      // Day
      _bgColors = [
        const Color(0xFF60A5FA), // blue-400
        const Color(0xFF7DD3FC), // sky-300
        const Color(0xFFFEF08A), // yellow-200
      ];
      _accentColor = const Color(0xFF2563EB); // blue-600
      _knobColor = const Color(0xFFFACC15); // yellow-400
      _themeIcon = Icons.wb_sunny;
      _themeIconColor = const Color(0xFFEAB308); // yellow-500
    } else if (realHour >= 17 && realHour < 20) {
      // Dusk
      _bgColors = [
        const Color(0xFF1E293B), // slate-800
        const Color(0xFF581C87), // purple-900
        const Color(0xFFF97316), // orange-500
      ];
      _accentColor = const Color(0xFFFDBA74); // orange-300
      _knobColor = const Color(0xFFFB923C); // orange-400
      _themeIcon = Icons.nightlight_round;
      _themeIconColor = const Color(0xFFFED7AA); // orange-200
    } else {
      // Night
      _bgColors = [
        const Color(0xFF020617), // slate-950
        const Color(0xFF0F172A), // slate-900
        const Color(0xFF1E1B4B), // indigo-950
      ];
      _accentColor = const Color(0xFFA5B4FC); // indigo-300
      _knobColor = const Color(0xFF6366F1); // indigo-500
      _themeIcon = Icons.nightlight_round;
      _themeIconColor = const Color(0xFF818CF8); // indigo-400
    }
  }

  void _handlePan(DragUpdateDetails details, String type, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final touchPosition = details.localPosition;

    final dx = touchPosition.dx - center.dx;
    final dy = touchPosition.dy - center.dy;

    // atan2 returns angle in radians from -pi to pi
    // -pi/2 is 12 o'clock
    double angle = math.atan2(dy, dx) * (180 / math.pi);

    // Adjust so 12 o'clock is 0 degrees
    angle = angle + 90;
    if (angle < 0) angle += 360;

    setState(() {
      if (type == 'hour') {
        // 360 degrees / 12 hours = 30 degrees per hour
        int newHour = (angle / 30).round();
        if (newHour == 0) newHour = 12;
        _hour = newHour;
      } else if (type == 'minute') {
        // 360 degrees / 60 minutes = 6 degrees per minute
        int newMinute = (angle / 6).round();
        if (newMinute == 60) newMinute = 0;
        _minute = newMinute;
      }
      _updateTheme();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 1000),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _bgColors,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Background particles (simplified)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.25,
              left: MediaQuery.of(context).size.width * 0.25,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 50,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),

            // Title
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '设置闹钟',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 18,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),

            // Main Control Panel
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size =
                      math.min(constraints.maxWidth, constraints.maxHeight) *
                      0.85;
                  final center = Offset(size / 2, size / 2);

                  return SizedBox(
                    width: size,
                    height: size,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Container Background
                        Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),

                        // Minute Track (Outer)
                        Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ),

                        // Minute Ticks
                        ...List.generate(12, (index) {
                          final angle = index * 30 * (math.pi / 180);
                          return Transform.translate(
                            offset: Offset(
                              (size / 2 - 10) * math.sin(angle),
                              -(size / 2 - 10) * math.cos(angle),
                            ),
                            child: Transform.rotate(
                              angle: angle,
                              child: Container(
                                width: 2,
                                height: 8,
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                          );
                        }),

                        // Minute Knob & Interaction
                        GestureDetector(
                          onPanStart: (d) =>
                              setState(() => _draggingType = 'minute'),
                          onPanUpdate: (d) =>
                              _handlePan(d, 'minute', Size(size, size)),
                          onPanEnd: (d) => setState(() => _draggingType = null),
                          child: Container(
                            width: size,
                            height: size,
                            color: Colors.transparent, // Hit test
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Transform.rotate(
                                  angle: _minute * 6 * (math.pi / 180),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.white.withOpacity(
                                                0.6,
                                              ),
                                              blurRadius: 15,
                                            ),
                                          ],
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.5,
                                            ),
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Color(
                                                0xFF0F172A,
                                              ), // slate-900
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: size / 2 - 32,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.white.withOpacity(0.5),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Hour Track (Inner)
                        Container(
                          width: size * 0.65,
                          height: size * 0.65,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ),

                        // Hour Knob & Interaction
                        GestureDetector(
                          onPanStart: (d) =>
                              setState(() => _draggingType = 'hour'),
                          onPanUpdate: (d) => _handlePan(
                            d,
                            'hour',
                            Size(size * 0.65, size * 0.65),
                          ),
                          onPanEnd: (d) => setState(() => _draggingType = null),
                          child: Container(
                            width: size * 0.65,
                            height: size * 0.65,
                            color: Colors.transparent,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Transform.rotate(
                                  angle: _hour * 30 * (math.pi / 180),
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      margin: const EdgeInsets.only(
                                        top: 0,
                                      ), // Adjust if needed
                                      decoration: BoxDecoration(
                                        color: _knobColor,
                                        shape: BoxShape.circle,
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 8,
                                          ),
                                        ],
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.8),
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        _themeIcon,
                                        color: _themeIconColor,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Center Display
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                IgnorePointer(
                                  child: Text(
                                    '$_hour',
                                    style: TextStyle(
                                      fontSize: 64,
                                      fontWeight: FontWeight.bold,
                                      color: _draggingType == 'hour'
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.9),
                                      height: 1,
                                    ),
                                  ),
                                ),
                                IgnorePointer(
                                  child: Text(
                                    ':',
                                    style: TextStyle(
                                      fontSize: 32,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                  ),
                                ),
                                IgnorePointer(
                                  child: Text(
                                    _minute.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      fontSize: 64,
                                      fontWeight: FontWeight.bold,
                                      color: _draggingType == 'minute'
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.9),
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => setState(() {
                                _isAm = !_isAm;
                                _updateTheme();
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  _isAm ? 'AM' : 'PM',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Actions
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name Input (Toggleable)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _showNameInput ? 60 : 0,
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: TextField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: '输入快捷名称 (例如: 晨练)',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                            ),
                            border: InputBorder.none,
                            icon: Icon(
                              Icons.bookmark,
                              color: Colors.white.withOpacity(0.7),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Reset Button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _hour = 7;
                            _minute = 30;
                            _isAm = true;
                            _alarmSet = false;
                            _showNameInput = false;
                            _nameController.clear();
                            _updateTheme();
                          });
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Icon(
                            Icons.refresh,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Add Label Button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showNameInput = !_showNameInput;
                          });
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _showNameInput
                                ? Colors.white.withOpacity(0.2)
                                : Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Icon(
                            Icons.edit,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Confirm Button
                      GestureDetector(
                        onTap: () {
                          setState(() => _alarmSet = !_alarmSet);
                          // Calculate final DateTime
                          final now = DateTime.now();
                          int realHour = _isAm
                              ? (_hour == 12 ? 0 : _hour)
                              : (_hour == 12 ? 12 : _hour + 12);

                          final selectedTime = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            realHour,
                            _minute,
                          );

                          widget.onTimeSelected(
                            selectedTime,
                            _nameController.text.isNotEmpty
                                ? _nameController.text
                                : null,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          decoration: BoxDecoration(
                            color: _alarmSet
                                ? const Color(0xFF10B981)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _alarmSet ? Icons.check : Icons.alarm,
                                color: _alarmSet
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _alarmSet ? '已设定' : '定闹钟',
                                style: TextStyle(
                                  color: _alarmSet
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status Text
            Positioned(
              bottom: 120,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _alarmSet ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: Center(
                  child: Text(
                    '闹钟将于 ${_isAm ? '上午' : '下午'} $_hour:${_minute.toString().padLeft(2, '0')} 响起',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

            // Cancel Button (Top Left)
            Positioned(
              top: 50,
              left: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed:
                    widget.onCancelled ?? () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
