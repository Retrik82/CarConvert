import { useEffect, useRef, useState } from "react";
import { fetchAuthenticatedBlob } from "../api/httpClient";

export default function AuthenticatedImage({ src, alt = "", className = "", fallback = null }) {
  const [blobUrl, setBlobUrl] = useState(null);
  const [failed, setFailed] = useState(false);
  const urlRef = useRef(null);

  useEffect(() => {
    if (!src) return undefined;
    let cancelled = false;

    (async () => {
      try {
        const path = src.replace(/^https?:\/\/[^/]+/, "");
        const url = await fetchAuthenticatedBlob(path);
        if (cancelled) {
          URL.revokeObjectURL(url);
          return;
        }
        if (urlRef.current) URL.revokeObjectURL(urlRef.current);
        urlRef.current = url;
        setBlobUrl(url);
        setFailed(false);
      } catch {
        if (!cancelled) setFailed(true);
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [src]);

  useEffect(
    () => () => {
      if (urlRef.current) URL.revokeObjectURL(urlRef.current);
    },
    [],
  );

  if (failed) return fallback;
  if (!blobUrl) {
    return <div className={`animate-pulse bg-surface-muted ${className}`} />;
  }

  return <img src={blobUrl} alt={alt} className={className} loading="lazy" />;
}
