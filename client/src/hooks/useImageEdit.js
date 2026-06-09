import { useCallback, useState } from "react";

import { mapEditImageError } from "../models/imageEdit.js";
import { imageEditRepository } from "../repositories/imageEditRepository.js";

export function useImageEdit() {
  const [loading, setLoading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState("");
  const [resultBase64, setResultBase64] = useState("");
  const [resultMime, setResultMime] = useState("image/png");

  const clearResult = useCallback(() => {
    setResultBase64("");
    setResultMime("image/png");
  }, []);

  const reset = useCallback(() => {
    clearResult();
    setLoading(false);
    setProgress(0);
    setError("");
  }, [clearResult]);

  const generate = useCallback(async ({ file, prompt }) => {
    if (!file) {
      setError("Please upload an image first.");
      return;
    }
    if (prompt.trim().length < 3) {
      setError("Prompt must be at least 3 characters.");
      return;
    }

    setLoading(true);
    setProgress(4);
    setError("");

    try {
      const result = await imageEditRepository.editImage({
        file,
        prompt,
        onUploadProgress: (event) => {
          if (!event.total) return;
          const uploadPercent = (event.loaded / event.total) * 65;
          setProgress(Math.max(8, uploadPercent));
        },
      });

      setResultBase64(result.imageBase64);
      setResultMime(result.mimeType);
      setProgress(100);
    } catch (err) {
      setError(mapEditImageError(err));
    } finally {
      setTimeout(() => {
        setLoading(false);
        setProgress(0);
      }, 350);
    }
  }, []);

  return {
    loading,
    progress,
    error,
    resultBase64,
    resultMime,
    setError,
    clearResult,
    reset,
    generate,
  };
}
