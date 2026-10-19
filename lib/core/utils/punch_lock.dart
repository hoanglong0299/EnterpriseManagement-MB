// Tan làm 17:00; từ 22:00 trở đi khoá chấm công (vào và ra), khớp quy tắc ở backend (EffectiveDayCalculator.PunchLockFrom).
// Chỉ để tắt nút cho người dùng khỏi bấm vô ích; backend vẫn là nơi chặn thật.
const int punchLockHour = 22;

bool isPunchLocked(DateTime now) => now.hour >= punchLockHour;
