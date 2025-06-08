import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../common/colo_extension.dart';
import '../../services/notification_service.dart';

class SetReminderDialog extends StatefulWidget {
  const SetReminderDialog({Key? key}) : super(key: key);

  @override
  State<SetReminderDialog> createState() => _SetReminderDialogState();
}

class _SetReminderDialogState extends State<SetReminderDialog> {
  bool _isDaily = false;
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime _selectedDate = DateTime.now();
  final NotificationService _notificationService = NotificationService();

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _setReminder() async {
    try {
      if (_isDaily) {
        await _notificationService.scheduleDailyReminder(
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
          title: 'Time to Check Your Blood Pressure',
          body: 'Don\'t forget to check your blood pressure today!',
        );
      } else {
        final scheduledDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
        await _notificationService.scheduleOneTimeReminder(
          scheduledDate: scheduledDate,
          title: 'Time to Check Your Blood Pressure',
          body: 'Don\'t forget to check your blood pressure!',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isDaily
                  ? 'Daily reminder set for ${_selectedTime.format(context)}'
                  : 'Reminder set for ${_selectedDate.toString().split(' ')[0]} at ${_selectedTime.format(context)}',
            ),
            backgroundColor: TColor.primaryColor1,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting reminder: $e'),
            backgroundColor: TColor.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Set Reminder',
              style: TextStyle(
                color: TColor.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: Text(
                'Daily Reminder',
                style: TextStyle(
                  color: TColor.textColor,
                  fontSize: 16,
                ),
              ),
              value: _isDaily,
              onChanged: (value) {
                setState(() {
                  _isDaily = value;
                });
              },
              activeColor: TColor.primaryColor1,
            ),
            ListTile(
              title: Text(
                'Time',
                style: TextStyle(
                  color: TColor.textColor,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                _selectedTime.format(context),
                style: TextStyle(
                  color: TColor.primaryColor1,
                  fontSize: 14,
                ),
              ),
              trailing: Icon(
                Icons.access_time,
                color: TColor.primaryColor1,
              ),
              onTap: () => _selectTime(context),
            ),
            if (!_isDaily)
              ListTile(
                title: Text(
                  'Date',
                  style: TextStyle(
                    color: TColor.textColor,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  _selectedDate.toString().split(' ')[0],
                  style: TextStyle(
                    color: TColor.primaryColor1,
                    fontSize: 14,
                  ),
                ),
                trailing: Icon(
                  Icons.calendar_today,
                  color: TColor.primaryColor1,
                ),
                onTap: () => _selectDate(context),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: TColor.subTextColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _setReminder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColor.primaryColor1,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Set Reminder'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 