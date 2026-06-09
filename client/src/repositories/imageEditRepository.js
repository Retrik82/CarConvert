import httpClient from "../api/httpClient.js";
import { mapEditImageResponse } from "../models/imageEdit.js";

class ImageEditRepository {
  async editImage({ file, prompt, onUploadProgress }) {
    const formData = new FormData();
    formData.append("image", file);
    formData.append("prompt", prompt);

    const response = await httpClient.post("/api/edit", formData, {
      headers: {
        "Content-Type": "multipart/form-data",
      },
      onUploadProgress,
    });

    return mapEditImageResponse(response.data);
  }
}

export const imageEditRepository = new ImageEditRepository();
