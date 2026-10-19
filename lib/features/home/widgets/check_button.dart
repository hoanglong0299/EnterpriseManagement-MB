import 'package:flutter/material.dart';

import '../../../app/theme.dart';

// Nút chấm công tròn lớn với các vòng sáng lan toả. Chưa chấm công vào thì là "Chấm công vào", đã vào thì "Chấm công ra".
class CheckButton extends StatefulWidget {
  final bool checkedIn;
  final bool loading;
  final VoidCallback onPressed;
  // Quá giờ khoá chấm công (18:00): nút xám, không bấm được, không còn vòng sáng.
  final bool locked;

  const CheckButton({super.key, required this.checkedIn, required this.loading, required this.onPressed, this.locked = false});

  @override
  State<CheckButton> createState() => _CheckButtonState();
}

class _CheckButtonState extends State<CheckButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.locked ? 'Đã khoá' : (widget.checkedIn ? 'Chấm công ra' : 'Chấm công vào');

    // Thu nhỏ cả cụm nút khi chỗ chứa hẹp hơn 230.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 230,
        height: 230,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                // Hai vòng lan ra lệch pha nhau, mờ dần khi đi xa.
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!widget.locked)
                      for (final phase in const [0.0, 0.5]) _ring((_pulse.value + phase) % 1.0),
                  ],
                );
              },
            ),
            Container(
              width: 152,
              height: 152,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.tint,
                border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.25), width: 2),
              ),
            ),
            GestureDetector(
              onTap: (widget.loading || widget.locked) ? null : widget.onPressed,
              child: Container(
                width: 116,
                height: 116,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: widget.locked
                      ? const LinearGradient(colors: [Color(0xFFB8B5C7), Color(0xFF8E8AA3)])
                      : AppColors.buttonGradient,
                  boxShadow: widget.locked
                      ? null
                      : [BoxShadow(color: AppColors.primary.withValues(alpha: 0.45), blurRadius: 24, offset: const Offset(0, 10))],
                ),
                alignment: Alignment.center,
                child: widget.loading
                    ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(widget.locked ? Icons.lock_outline_rounded : (widget.checkedIn ? Icons.logout_rounded : Icons.fingerprint_rounded), color: Colors.white, size: 30),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            // Nhãn co lại vừa nút tròn khi chữ hệ thống phóng to.
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ring(double t) {
    final size = 152 + t * 78;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryLight.withValues(alpha: 0.12 * (1 - t)),
      ),
    );
  }
}
