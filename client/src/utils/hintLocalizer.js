/** Localized capture advisor messages — mirrors mobile hint_localizer.dart */

export function hintMessage(strings, hint, status) {
  if (!hint) {
    if (status && status !== "Initializing...") return status;
    return strings.advisorPointCamera;
  }

  const lowConfidence = hint.confidence < 0.45;

  switch (hint.hint) {
    case "move_left":
      return strings.advisorMoveLeft;
    case "move_right":
      return strings.advisorMoveRight;
    case "move_back":
      return strings.advisorMoveBack;
    case "move_closer":
      return strings.advisorMoveCloser;
    case "align_car":
    case "no_car_detected":
      return strings.advisorAlignCar;
    case "perfect_frame":
      return strings.advisorPerfectFrame;
    default:
      return lowConfidence ? strings.advisorImproveFocus : hint.message;
  }
}

export function statusOrConnecting(strings, status) {
  if (status === "Initializing...") return strings.advisorConnecting;
  return status;
}

export function resolveHintMessage(strings, hint, status) {
  const isPerfect = hint?.isPerfect ?? false;
  const lighting = hint ? (hint.confidence < 0.35 ? 0.35 : Math.min(1, 0.55 + hint.confidence * 0.35)) : 0.5;
  const lowLight = lighting < 0.5;

  if (lowLight && !isPerfect) return strings.advisorLowLight;
  return hintMessage(strings, hint, statusOrConnecting(strings, status));
}
