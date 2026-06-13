import 'app_strings.dart';
import '../../models/hint_response.dart';

class HintLocalizer {
  const HintLocalizer(this.strings);

  final AppStrings strings;

  String message({HintResponse? hint, required String status}) {
    if (hint == null) {
      if (status.isNotEmpty && status != 'Initializing...') return status;
      return strings.advisorPointCamera;
    }

    return switch (hint.hint) {
      'move_left' => strings.advisorMoveLeft,
      'move_right' => strings.advisorMoveRight,
      'move_back' => strings.advisorMoveBack,
      'move_closer' => strings.advisorMoveCloser,
      'align_car' => strings.advisorAlignCar,
      'no_car_detected' => strings.advisorAlignCar,
      'perfect_frame' => strings.advisorPerfectFrame,
      _ => hint.confidence < 0.45 ? strings.advisorImproveFocus : hint.message,
    };
  }

  String statusOrConnecting(String status) {
    if (status == 'Initializing...') return strings.advisorConnecting;
    return status;
  }
}
