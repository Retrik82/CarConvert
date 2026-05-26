import axios from "axios";

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || "http://localhost:3001",
  timeout: 180000,
});

export async function editImage({ file, prompt, onUploadProgress }) {
  const formData = new FormData();
  formData.append("image", file);
  formData.append("prompt", prompt);

  const response = await api.post("/api/edit", formData, {
    headers: {
      "Content-Type": "multipart/form-data",
    },
    onUploadProgress,
  });

  return response.data;
}

export default api;
