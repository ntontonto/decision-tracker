import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../data/local/database.dart';
import '../../domain/models/enums.dart';
import '../../domain/providers/app_providers.dart';
import '../../domain/providers/declaration_providers.dart';
import '../theme/app_design.dart';

class CalendarItem {
  final String id;
  final String title;
  final DateTime date;
  final Color color;
  final bool isPending;
  final dynamic originalData;
  final bool isDeclaration;

  CalendarItem({
    required this.id,
    required this.title,
    required this.date,
    required this.color,
    required this.isPending,
    required this.originalData,
    required this.isDeclaration,
  });
}

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<CalendarItem> _getEventsForDay(DateTime day, List<CalendarItem> allItems) {
    return allItems.where((item) => isSameDay(item.date, day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final decisionsAsync = ref.watch(allDecisionsStreamProvider);
    final declarationsAsync = ref.watch(actionGoalsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('カレンダー（β）', style: AppDesign.titleStyle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: (decisionsAsync.hasValue && declarationsAsync.hasValue)
          ? _buildCalendar(decisionsAsync.value!, declarationsAsync.value!)
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  Widget _buildCalendar(List<Decision> decisions, List<Declaration> declarations) {
    final allItems = [
      ...decisions.map((d) => CalendarItem(
            id: d.id,
            title: d.textContent,
            date: d.createdAt,
            color: Colors.blue.shade400,
            isPending: d.status == DecisionStatus.pending,
            originalData: d,
            isDeclaration: false,
          )),
      ...declarations.map((d) => CalendarItem(
            id: d.id.toString(),
            title: d.declarationText,
            date: d.createdAt,
            color: Colors.teal.shade300,
            isPending: d.status == DeclarationStatus.active,
            originalData: d,
            isDeclaration: true,
          )),
    ];

    return Column(
      children: [
        TableCalendar<CalendarItem>(
          firstDay: DateTime.utc(2023, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          startingDayOfWeek: StartingDayOfWeek.monday,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            _showDayDetails(selectedDay, allItems);
          },
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          eventLoader: (day) => _getEventsForDay(day, allItems),
          calendarStyle: CalendarStyle(
            defaultTextStyle: const TextStyle(color: Colors.white),
            weekendTextStyle: const TextStyle(color: Colors.white70),
            outsideTextStyle: const TextStyle(color: Colors.white24),
            todayDecoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: Colors.transparent,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
            rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: Colors.white60, fontSize: 12),
            weekendStyle: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return null;
              return Container(
                margin: const EdgeInsets.only(top: 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: events.take(3).map((event) {
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: event.color.withValues(alpha: event.isPending ? 0.3 : 1.0),
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList(),
                ),
              );
            },
            defaultBuilder: (context, day, focusedDay) {
              final events = _getEventsForDay(day, allItems);
              return _buildDayCell(day, events, isSelected: false, isToday: isSameDay(day, DateTime.now()));
            },
            selectedBuilder: (context, day, focusedDay) {
              final events = _getEventsForDay(day, allItems);
              return _buildDayCell(day, events, isSelected: true, isToday: isSameDay(day, DateTime.now()));
            },
            todayBuilder: (context, day, focusedDay) {
              final events = _getEventsForDay(day, allItems);
              return _buildDayCell(day, events, isSelected: false, isToday: true);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayCell(DateTime day, List<CalendarItem> events, {required bool isSelected, required bool isToday}) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isToday ? Border.all(color: Colors.white24, width: 1) : null,
      ),
      child: Column(
        children: [
          const SizedBox(height: 4),
          Text(
            '${day.day}',
            style: TextStyle(
              color: isToday ? Colors.white : (day.month == _focusedDay.month ? Colors.white70 : Colors.white24),
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          if (events.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 2, right: 2),
              child: Wrap(
                spacing: 2,
                runSpacing: 2,
                alignment: WrapAlignment.center,
                children: events.take(4).map((e) => _buildEventBar(e)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventBar(CalendarItem event) {
    return Container(
      width: 12,
      height: 4,
      decoration: BoxDecoration(
        color: event.color.withValues(alpha: event.isPending ? 0.3 : 1.0),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  void _showDayDetails(DateTime day, List<CalendarItem> allItems) {
    final dayEvents = _getEventsForDay(day, allItems);
    if (dayEvents.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white12),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${day.year}年${day.month}月${day.day}日',
                    style: AppDesign.titleStyle.copyWith(fontSize: 20),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: dayEvents.length,
                  itemBuilder: (context, index) {
                    final event = dayEvents[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: AppDesign.cardDecoration(),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: event.color.withValues(alpha: event.isPending ? 0.3 : 1.0),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.isDeclaration ? '行動宣言' : '判断の記録',
                                  style: AppDesign.subtitleStyle,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  event.title,
                                  style: AppDesign.bodyStyle,
                                ),
                              ],
                            ),
                          ),
                          if (event.isPending)
                            const Icon(Icons.pending_actions, color: Colors.white24, size: 20),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
