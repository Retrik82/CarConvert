export function downloadBase64Image(base64, mimeType = "image/png", filename = "autocut-render.png") {
  const link = document.createElement("a");
  link.href = `data:${mimeType};base64,${base64}`;
  link.download = filename;
  link.click();
}

export function downloadBlob(blob, filename = "autocut-render.png") {
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  link.click();
  URL.revokeObjectURL(url);
}

export function fileToBase64(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      const result = reader.result;
      const base64 = result.split(",")[1];
      resolve(base64);
    };
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
}
