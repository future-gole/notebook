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
  late DateTime _selectedDate;
  late DateTime _calendarFocusedDay; // For the custom calendar view
  String? _draggingType; // 'hour' | 'minute' | null
  bool _alarmSet = false;
  final TextEditingController _nameController = TextEditingController();
  bool _showNameInput = false;
  bool _isDatePickerMode = false; // Toggle between Time and Date picker

  // Theme colors
  late List<Color> _bgColors;
  late Color _accentColor;
  late Color _knobColor;
  late IconData _themeIcon;
  late Color _themeIconColor;

  // Dynamic Glass Colors for visibility
  late Color _glassColor;
  late Color _glassBorderColor;
  late Color _textColor;

  @override
  void initState() {
    super.initState();
    final initTime = widget.initialTime ?? DateTime.now();
    _hour = initTime.hour > 12
        ? initTime.hour - 12
        : (initTime.hour == 0 ? 12 : initTime.hour);
    _minute = initTime.minute;
    _isAm = initTime.hour < 12;
    _selectedDate = DateTime(initTime.year, initTime.month, initTime.day);
    _calendarFocusedDay = _selectedDate;
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
      _glassColor = Colors.white.withOpacity(0.1);
      _glassBorderColor = Colors.white.withOpacity(0.1);
      _textColor = Colors.white;
    } else if (realHour >= 7 && realHour < 17) {
      // Day - Adjusted for better visibility
      _bgColors = [
        const Color(0xFF3B82F6), // blue-500 (Darker than before)
        const Color(0xFF0EA5E9), // sky-500
        const Color(0xFFF59E0B), // amber-500 (Darker yellow/orange)
      ];
      _accentColor = const Color(0xFF1D4ED8); // blue-700
      _knobColor = const Color(0xFFFDE047); // yellow-300
      _themeIcon = Icons.wb_sunny;
      _themeIconColor = const Color(0xFFFEF08A); // yellow-200

      // Make glass more visible on bright background
      _glassColor = Colors.white.withOpacity(0.25);
      _glassBorderColor = Colors.white.withOpacity(0.4);
      _textColor = Colors.white;
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
      _glassColor = Colors.white.withOpacity(0.1);
      _glassBorderColor = Colors.white.withOpacity(0.1);
      _textColor = Colors.white;
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
      _glassColor = Colors.white.withOpacity(0.05);
      _glassBorderColor = Colors.white.withOpacity(0.1);
      _textColor = Colors.white;
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

  Widget _buildClockView(double size) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Minute Track (Outer)
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _glassBorderColor.withOpacity(0.2)),
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
                color: _glassBorderColor.withOpacity(0.3),
              ),
            ),
          );
        }),

        // Minute Knob & Interaction
        GestureDetector(
          onPanStart: (d) => setState(() => _draggingType = 'minute'),
          onPanUpdate: (d) => _handlePan(d, 'minute', Size(size, size)),
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
                              color: Colors.white.withOpacity(0.6),
                              blurRadius: 15,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F172A), // slate-900
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
            border: Border.all(color: _glassBorderColor.withOpacity(0.2)),
          ),
        ),

        // Hour Knob & Interaction
        GestureDetector(
          onPanStart: (d) => setState(() => _draggingType = 'hour'),
          onPanUpdate: (d) =>
              _handlePan(d, 'hour', Size(size * 0.65, size * 0.65)),
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
                      margin: const EdgeInsets.only(top: 0), // Adjust if needed
                      decoration: BoxDecoration(
                        color: _knobColor,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 8),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.8),
                          width: 2,
                        ),
                      ),
                      child: Icon(_themeIcon, color: _themeIconColor, size: 20),
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
                          ? _textColor
                          : _textColor.withOpacity(0.9),
                      height: 1,
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Text(
                    ':',
                    style: TextStyle(
                      fontSize: 32,
                      color: _textColor.withOpacity(0.5),
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
                          ? _textColor
                          : _textColor.withOpacity(0.9),
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
                  color: _glassColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _glassBorderColor),
                ),
                child: Text(
                  _isAm ? 'AM' : 'PM',
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarView(double size) {
    final daysInMonth = DateUtils.getDaysInMonth(
      _calendarFocusedDay.year,
      _calendarFocusedDay.month,
    );
    final firstDayOfMonth = DateTime(
      _calendarFocusedDay.year,
      _calendarFocusedDay.month,
      1,
    );
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Header (Month Year)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: _textColor),
                onPressed: () {
                  setState(() {
                    _calendarFocusedDay = DateTime(
                      _calendarFocusedDay.year,
                      _calendarFocusedDay.month - 1,
                    );
                  });
                },
              ),
              Text(
                DateFormat('yyyy年 MM月').format(_calendarFocusedDay),
                style: TextStyle(
                  color: _textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: _textColor),
                onPressed: () {
                  setState(() {
                    _calendarFocusedDay = DateTime(
                      _calendarFocusedDay.year,
                      _calendarFocusedDay.month + 1,
                    );
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Weekday Headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['一', '二', '三', '四', '五', '六', '日']
                .map(
                  (d) => Text(
                    d,
                    style: TextStyle(
                      color: _textColor.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          // Days Grid
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: 42, // 6 rows * 7 cols
              itemBuilder: (context, index) {
                final dayOffset = index - (startingWeekday - 1);
                if (dayOffset < 0 || dayOffset >= daysInMonth) {
                  return const SizedBox();
                }
                final day = dayOffset + 1;
                final date = DateTime(
                  _calendarFocusedDay.year,
                  _calendarFocusedDay.month,
                  day,
                );
                final isSelected = DateUtils.isSameDay(date, _selectedDate);
                final isToday = DateUtils.isSameDay(date, DateTime.now());

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                      // Optional: Auto-switch back to clock?
                      // _isDatePickerMode = false;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _knobColor
                          : (isToday
                                ? _glassColor.withOpacity(0.3)
                                : Colors.transparent),
                      shape: BoxShape.circle,
                      border: isToday && !isSelected
                          ? Border.all(color: _glassBorderColor)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.black.withOpacity(0.8)
                              : _textColor,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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
                            color: _glassColor,
                            border: Border.all(color: _glassBorderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),

                        // Content Switcher (Time vs Date)
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: ScaleTransition(
                                scale: animation.drive(
                                  Tween(
                                    begin: 0.9,
                                    end: 1.0,
                                  ).chain(CurveTween(curve: Curves.easeOut)),
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: _isDatePickerMode
                              ? _buildCalendarView(size)
                              : _buildClockView(size),
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
                          color: _glassColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _glassBorderColor),
                        ),
                        child: TextField(
                          controller: _nameController,
                          style: TextStyle(color: _textColor),
                          decoration: InputDecoration(
                            hintText: '输入快捷名称 (例如: 晨练)',
                            hintStyle: TextStyle(
                              color: _textColor.withOpacity(0.5),
                            ),
                            border: InputBorder.none,
                            icon: Icon(
                              Icons.bookmark,
                              color: _textColor.withOpacity(0.7),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Date Selector Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDatePickerMode = !_isDatePickerMode;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _isDatePickerMode
                            ? _glassColor.withOpacity(0.3)
                            : _glassColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isDatePickerMode
                              ? _accentColor.withOpacity(0.5)
                              : _glassBorderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: _textColor.withOpacity(0.8),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('yyyy年MM月dd日').format(_selectedDate),
                            style: TextStyle(
                              color: _textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Reset Button
                      GestureDetector(
                        onTap: () {
                          final now = DateTime.now();
                          setState(() {
                            _hour = now.hour > 12
                                ? now.hour - 12
                                : (now.hour == 0 ? 12 : now.hour);
                            _minute = now.minute;
                            _isAm = now.hour < 12;
                            _selectedDate = DateTime(
                              now.year,
                              now.month,
                              now.day,
                            );
                            _calendarFocusedDay = _selectedDate;
                            _alarmSet = false;
                            _showNameInput = false;
                            _isDatePickerMode = false;
                            _nameController.clear();
                            _updateTheme();
                          });
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _glassColor.withOpacity(0.05),
                            shape: BoxShape.circle,
                            border: Border.all(color: _glassBorderColor),
                          ),
                          child: Icon(
                            Icons.refresh,
                            color: _textColor.withOpacity(0.7),
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
                                ? _glassColor.withOpacity(0.2)
                                : _glassColor.withOpacity(0.05),
                            shape: BoxShape.circle,
                            border: Border.all(color: _glassBorderColor),
                          ),
                          child: Icon(
                            Icons.edit,
                            color: _textColor.withOpacity(0.7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Confirm Button
                      GestureDetector(
                        onTap: () {
                          setState(() => _alarmSet = !_alarmSet);
                          // Calculate final DateTime
                          int realHour = _isAm
                              ? (_hour == 12 ? 0 : _hour)
                              : (_hour == 12 ? 12 : _hour + 12);

                          final selectedTime = DateTime(
                            _selectedDate.year,
                            _selectedDate.month,
                            _selectedDate.day,
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
