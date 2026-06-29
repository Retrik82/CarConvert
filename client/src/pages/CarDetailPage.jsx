import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { deleteRender, fetchMyCars, updateRenderName } from "../api/myCarsApi";
import { useStrings } from "../contexts/SettingsContext";
import { formatDateTime } from "../utils/format";
import AuthenticatedImage from "../components/AuthenticatedImage";
import Button from "../components/ui/Button";
import Input from "../components/ui/Input";
import Modal, { ConfirmModal } from "../components/ui/Modal";
import { PageHeader, Spinner } from "../components/layout/AppChrome";
import Toast from "../components/ui/Toast";

export default function CarDetailPage() {
  const { carId } = useParams();
  const s = useStrings();
  const navigate = useNavigate();
  const [car, setCar] = useState(null);
  const [loading, setLoading] = useState(true);
  const [selectedRender, setSelectedRender] = useState(null);
  const [renameTarget, setRenameTarget] = useState(null);
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [nameInput, setNameInput] = useState("");
  const [error, setError] = useState("");

  const load = async () => {
    setLoading(true);
    try {
      const cars = await fetchMyCars();
      const found = cars.find((c) => c.id === carId);
      setCar(found || null);
    } catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, [carId]);

  const handleRename = async () => {
    if (!renameTarget || !nameInput.trim()) return;
    await updateRenderName(carId, renameTarget.id, nameInput.trim());
    setRenameTarget(null);
    load();
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    await deleteRender(carId, deleteTarget.id);
    setDeleteTarget(null);
    setSelectedRender(null);
    load();
  };

  if (loading) {
    return (
      <div className="flex justify-center py-16">
        <Spinner />
      </div>
    );
  }

  if (!car) {
    return <p className="text-ink-secondary">{s.errorGeneric}</p>;
  }

  const active = selectedRender || car.renders?.[0];

  return (
    <div>
      <PageHeader
        title={car.name}
        subtitle={s.renderHistory}
        action={
          <Link to={`/app/capture?mode=gallery&carId=${car.id}`}>
            <Button>+ {s.addRender}</Button>
          </Link>
        }
      />

      {active ? (
        <div className="mb-8">
          <div className="mb-4 grid gap-3 sm:grid-cols-2">
            <div className="overflow-hidden rounded-2xl bg-surface-muted">
              <p className="px-3 py-2 text-xs font-medium text-ink-secondary">{s.beforeLabel}</p>
              {active.original_url ? (
                <AuthenticatedImage
                  src={active.original_url}
                  alt="Original"
                  className="aspect-[4/3] w-full object-cover"
                />
              ) : (
                <div className="flex aspect-[4/3] items-center justify-center text-3xl">📷</div>
              )}
            </div>
            <div className="overflow-hidden rounded-2xl bg-surface-muted">
              <p className="px-3 py-2 text-xs font-medium text-ink-secondary">{s.afterLabel}</p>
              {active.rendered_url ? (
                <AuthenticatedImage
                  src={active.rendered_url}
                  alt="Rendered"
                  className="aspect-[4/3] w-full object-cover"
                />
              ) : (
                <div className="flex aspect-[4/3] items-center justify-center text-3xl">✨</div>
              )}
            </div>
          </div>
          <div className="flex flex-wrap gap-2">
            <Button
              size="sm"
              variant="secondary"
              onClick={() => {
                setRenameTarget(active);
                setNameInput(active.name || "");
              }}
            >
              {s.renameRender}
            </Button>
            <Button size="sm" variant="danger" onClick={() => setDeleteTarget(active)}>
              {s.deleteRender}
            </Button>
          </div>
        </div>
      ) : null}

      <div className="grid gap-3 sm:grid-cols-3">
        {car.renders?.map((render) => (
          <button
            key={render.id}
            type="button"
            onClick={() => setSelectedRender(render)}
            className={[
              "overflow-hidden rounded-2xl border text-left transition",
              active?.id === render.id ? "border-brand-500 ring-2 ring-brand-200" : "border-[var(--border)] hover:border-slate-300",
            ].join(" ")}
          >
            <div className="aspect-[4/3] bg-surface-muted">
              {render.rendered_url ? (
                <AuthenticatedImage
                  src={render.rendered_url}
                  alt={render.name || "Render"}
                  className="h-full w-full object-cover"
                />
              ) : (
                <div className="flex h-full items-center justify-center text-3xl">🖼️</div>
              )}
            </div>
            <div className="p-3">
              <p className="truncate text-sm font-medium text-ink">{render.name || "Render"}</p>
              <p className="text-xs text-ink-tertiary">{formatDateTime(render.created_at)}</p>
            </div>
          </button>
        ))}
      </div>

      <Button variant="ghost" className="mt-6" onClick={() => navigate("/app/cars")}>
        ← {s.navCars}
      </Button>

      <Modal
        open={Boolean(renameTarget)}
        title={s.renameRender}
        onClose={() => setRenameTarget(null)}
        footer={
          <>
            <Button variant="ghost" onClick={() => setRenameTarget(null)}>
              {s.cancel}
            </Button>
            <Button onClick={handleRename}>{s.confirm}</Button>
          </>
        }
      >
        <Input label={s.renderName} value={nameInput} onChange={(e) => setNameInput(e.target.value)} />
      </Modal>

      <ConfirmModal
        open={Boolean(deleteTarget)}
        title={s.deleteRender}
        body="This action cannot be undone."
        confirmLabel={s.deleteRender}
        cancelLabel={s.cancel}
        danger
        onConfirm={handleDelete}
        onClose={() => setDeleteTarget(null)}
      />

      <Toast message={error} onClose={() => setError("")} />
    </div>
  );
}
