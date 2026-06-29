import { useEffect, useMemo, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { fetchMyCars, saveRender } from "../api/myCarsApi";
import { useStrings } from "../contexts/SettingsContext";
import { downloadBase64Image, shareBase64Image } from "../utils/download";
import { formatDateTime } from "../utils/format";
import BeforeAfterSlider from "../components/BeforeAfterSlider";
import { FullscreenImageModal } from "../components/ZoomableImage";
import Button from "../components/ui/Button";
import Input from "../components/ui/Input";
import Modal from "../components/ui/Modal";
import { PageHeader } from "../components/layout/AppChrome";
import Toast from "../components/ui/Toast";

export default function ResultPage() {
  const s = useStrings();
  const navigate = useNavigate();
  const location = useLocation();
  const { result, file, carId: initialCarId, previewUrl } = location.state || {};

  const [saved, setSaved] = useState(false);
  const [saving, setSaving] = useState(false);
  const [saveOpen, setSaveOpen] = useState(false);
  const [cars, setCars] = useState([]);
  const [selectedCarId, setSelectedCarId] = useState(initialCarId || "");
  const [renderName, setRenderName] = useState(() => formatDateTime(new Date()));
  const [error, setError] = useState("");
  const [fullscreenSrc, setFullscreenSrc] = useState(null);

  useEffect(() => {
    if (!result) navigate("/app", { replace: true });
  }, [result, navigate]);

  const afterUrl = useMemo(() => {
    if (!result?.image_base64) return "";
    return `data:${result.mime_type || "image/png"};base64,${result.image_base64}`;
  }, [result]);

  const beforeUrl = previewUrl || (file ? URL.createObjectURL(file) : "");

  useEffect(() => {
    fetchMyCars().then(setCars).catch(() => {});
  }, []);

  const handleSave = async () => {
    if (!selectedCarId) {
      setError(s.selectCar);
      return;
    }
    setSaving(true);
    setError("");
    try {
      await saveRender(selectedCarId, { jobId: result.job_id, name: renderName });
      setSaved(true);
      setSaveOpen(false);
    } catch (e) {
      setError(e.message);
    } finally {
      setSaving(false);
    }
  };

  const handleShare = async () => {
    const shared = await shareBase64Image(
      result.image_base64,
      result.mime_type || "image/png",
      s.renderResultTitle,
    );
    if (!shared) {
      downloadBase64Image(result.image_base64, result.mime_type || "image/png", "autocut-render.png");
    }
  };

  if (!result) return null;

  return (
    <div>
      <PageHeader title={s.renderResultTitle} />

      <button type="button" onClick={() => setFullscreenSrc(afterUrl)} className="mb-8 block w-full">
        <BeforeAfterSlider beforeUrl={beforeUrl} afterUrl={afterUrl} className="pointer-events-none" />
      </button>

      <div className="flex flex-wrap gap-3">
        <Button
          onClick={() =>
            downloadBase64Image(result.image_base64, result.mime_type || "image/png", "autocut-render.png")
          }
        >
          {s.downloadPhoto}
        </Button>
        <Button variant="secondary" onClick={handleShare}>
          {s.sharePhoto}
        </Button>
        <Button variant="secondary" disabled={saved} onClick={() => setSaveOpen(true)}>
          {saved ? s.savedToMyCars : s.saveToMyCars}
        </Button>
        <Button variant="ghost" onClick={() => navigate("/app/capture?mode=gallery")}>
          {s.addRender}
        </Button>
      </div>

      <Modal
        open={saveOpen}
        title={s.saveToMyCars}
        onClose={() => setSaveOpen(false)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setSaveOpen(false)}>
              {s.cancel}
            </Button>
            <Button onClick={handleSave} disabled={saving}>
              {saving ? s.loading : s.confirm}
            </Button>
          </>
        }
      >
        <div className="space-y-4">
          <label className="block text-sm font-medium text-ink">{s.selectCar}</label>
          <select
            className="w-full rounded-2xl border border-[var(--border)] px-4 py-3 text-sm"
            value={selectedCarId}
            onChange={(e) => setSelectedCarId(e.target.value)}
          >
            <option value="">—</option>
            {cars.map((car) => (
              <option key={car.id} value={car.id}>
                {car.name}
              </option>
            ))}
          </select>
          <Input label={s.renderName} value={renderName} onChange={(e) => setRenderName(e.target.value)} />
        </div>
      </Modal>

      <FullscreenImageModal open={Boolean(fullscreenSrc)} src={fullscreenSrc} onClose={() => setFullscreenSrc(null)} />

      <Toast message={error} onClose={() => setError("")} />
    </div>
  );
}
