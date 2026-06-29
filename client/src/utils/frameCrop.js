/** Frame crop specs — must match mobile/lib/utils/frame_crop.dart and backend image_utils. */

export const portraitFrameCrop = {
  left: 0.08,
  top: 0.22,
  width: 0.84,
  height: 0.48,
};

export const landscapeFrameCrop = {
  left: 0.1,
  top: 0.15,
  width: 0.8,
  height: 0.7,
};

export function frameCropForSize(width, height) {
  return width > height ? landscapeFrameCrop : portraitFrameCrop;
}

export function frameCropForViewport() {
  if (typeof window === "undefined") return portraitFrameCrop;
  return frameCropForSize(window.innerWidth, window.innerHeight);
}

function loadImageFromFile(file) {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file);
    const img = new Image();
    img.onload = () => {
      URL.revokeObjectURL(url);
      resolve(img);
    };
    img.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error("Failed to decode image"));
    };
    img.src = url;
  });
}

/**
 * Crop image to frame guide region (canvas). Returns JPEG File.
 * Ported from mobile cropToFrameGuide.
 */
export async function cropToFrameGuide(source, crop, quality = 0.92) {
  const img =
    source instanceof HTMLVideoElement
      ? source
      : source instanceof HTMLImageElement
        ? source
        : await loadImageFromFile(source);

  const spec = crop || frameCropForSize(img.videoWidth || img.naturalWidth, img.videoHeight || img.naturalHeight);
  const w = img.videoWidth || img.naturalWidth;
  const h = img.videoHeight || img.naturalHeight;

  const left = Math.round(w * spec.left);
  const top = Math.round(h * spec.top);
  const width = Math.max(1, Math.min(Math.round(w * spec.width), w - left));
  const height = Math.max(1, Math.min(Math.round(h * spec.height), h - top));

  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;
  canvas.getContext("2d").drawImage(img, left, top, width, height, 0, 0, width, height);

  const blob = await new Promise((resolve) => canvas.toBlob(resolve, "image/jpeg", quality));
  if (!blob) throw new Error("Crop failed");
  return new File([blob], `capture-${Date.now()}.jpg`, { type: "image/jpeg" });
}
