import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../check_in/providers/check_in_provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  final List<String> _weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  void _changeMonth(int offset) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + offset, 1);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000), 
      lastDate: DateTime(2100),  
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2A5CAA), 
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _focusedMonth = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CheckInProvider>();
    
    int daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    int firstDayOffset = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday % 7;
    
    bool isTodaySelected = _selectedDate.year == DateTime.now().year && 
                           _selectedDate.month == DateTime.now().month && 
                           _selectedDate.day == DateTime.now().day;

    // Kiểm tra xem ngày đang được chọn có phải là Chủ nhật không
    bool isSelectedSunday = _selectedDate.weekday == DateTime.sunday;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 1. Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Calendar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.calendar_month, color: Color(0xFF2A5CAA)), 
                      onPressed: () => _selectDate(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Bộ chọn Tháng / Năm
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left, color: Color(0xFF2A5CAA)), onPressed: () => _changeMonth(-1)),
                Text(
                  DateFormat('MMMM yyyy').format(_focusedMonth),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                IconButton(icon: const Icon(Icons.chevron_right, color: Color(0xFF2A5CAA)), onPressed: () => _changeMonth(1)),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3. Thứ trong tuần (Sun -> Sat)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _weekDays.map((day) => Expanded(
                child: Center(
                  child: Text(
                    day, 
                    style: TextStyle(
                      color: day == 'Sun' ? Colors.red.shade300 : Colors.grey, // Chữ Sun màu đỏ nhạt
                      fontSize: 13,
                      fontWeight: day == 'Sun' ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // 4. Lưới Ngày trong tháng
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cellWidth = (constraints.maxWidth - (6 * 8)) / 7;
                  final cellHeight = (constraints.maxHeight - (5 * 8)) / 6;
                  final aspectRatio = cellHeight > 0 ? (cellWidth / cellHeight) : 1.0;

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 42,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: aspectRatio,
                    ),
                    itemBuilder: (context, index) {
                      if (index < firstDayOffset || index >= firstDayOffset + daysInMonth) {
                        return const SizedBox.shrink();
                      }
                      
                      int day = index - firstDayOffset + 1;
                      DateTime currentDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);
                      
                      bool isSelected = _selectedDate.year == currentDate.year && 
                                        _selectedDate.month == currentDate.month && 
                                        _selectedDate.day == currentDate.day;
                                        
                      bool isSunday = currentDate.weekday == DateTime.sunday;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = currentDate;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // Nếu được chọn -> Màu xanh. Nếu là CN chưa chọn -> Nền xám mờ. Còn lại -> Trong suốt
                            color: isSelected 
                                ? const Color(0xFF2A5CAA) 
                                : (isSunday ? Colors.grey.shade200 : Colors.transparent),
                          ),
                          child: Center(
                            child: Text(
                              day.toString(),
                              style: TextStyle(
                                fontSize: 15,
                                // Chọn -> Trắng. Chủ nhật -> Đỏ nhạt. Bình thường -> Đen
                                color: isSelected 
                                    ? Colors.white 
                                    : (isSunday ? Colors.red.shade400 : Colors.black87),
                                fontWeight: isSelected || isSunday ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              ),
            ),
          ),
          
          // 5. Chi tiết Lịch sử bên dưới
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.black12, width: 1)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy (EEE)').format(_selectedDate),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    
                    // XỬ LÝ LOGIC HIỂN THỊ NỘI DUNG NGÀY
                    if (isSelectedSunday)
                      const Row(
                        children: [
                          Icon(Icons.weekend, size: 20, color: Colors.orange), // Icon nghỉ ngơi
                          SizedBox(width: 12),
                          Text(
                            'DAY-OFF', 
                            style: TextStyle(
                              fontSize: 15, 
                              color: Colors.black87, 
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      )
                    else if (isTodaySelected && provider.historyRecords.isNotEmpty)
                      ...provider.historyRecords.map((record) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 8, color: Colors.lightBlueAccent),
                            const SizedBox(width: 12),
                            Text(record, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                          ],
                        ),
                      ))
                    else
                      const Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.lightBlueAccent),
                          SizedBox(width: 12),
                          Text('S0900_1800 - 09:00 to 18:00', style: TextStyle(fontSize: 14, color: Colors.black87)),
                        ],
                      )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}