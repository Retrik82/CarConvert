/** Parsed WebSocket hint payload — mirrors mobile/lib/models/hint_response.dart */

export function parseHintResponse(json) {
  if (!json || json.type === "connected" || json.type === "error") return null;

  const scores = json.scores || {};
  const overlay = json.overlay || {};

  let confidence = json.confidence ?? 0.5;
  if (typeof confidence === "number" && confidence > 1) confidence /= 100;
  confidence = Math.max(0, Math.min(1, confidence));

  return {
    hint: json.hint || "align_car",
    message: json.message || "",
    confidence,
    scores: {
      centering: Number(scores.centering) || 0,
      distance: Number(scores.distance) || 0,
      angle: Number(scores.angle) || 0,
    },
    overlay: {
      arrow: overlay.arrow || "none",
      color: overlay.color || "yellow",
    },
    isPerfect: (json.hint || "") === "perfect_frame",
  };
}

export function lightingScore(hint) {
  if (!hint) return 0.5;
  if (hint.confidence < 0.35) return 0.35;
  return Math.min(1, 0.55 + hint.confidence * 0.35);
}

export function framingScore(hint) {
  if (!hint) return 0;
  const { centering, distance, angle } = hint.scores;
  return (centering + distance + angle) / 3;
}

export function focusScore(hint) {
  if (!hint) return 0.5;
  return hint.confidence;
}
