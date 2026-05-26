export function downloadBase64Image(base64Data, mimeType = "image/png") {
  const dataUrl = `data:${mimeType};base64,${base64Data}`;
  const link = document.createElement("a");
  const extension = mimeType.split("/")[1] || "png";
  link.href = dataUrl;
  link.download = `car-background-edited.${extension}`;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}
