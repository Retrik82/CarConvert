export function mapEditImageResponse(data) {
  if (!data?.success || !data?.image_base64) {
    throw new Error(data?.error || "Failed to generate image.");
  }

  return {
    imageBase64: data.image_base64,
    mimeType: data.mime_type || "image/png",
  };
}

export function mapEditImageError(error) {
  return error?.response?.data?.error || error?.message || "Unexpected error.";
}
