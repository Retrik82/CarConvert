import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { createCar, deleteCar, fetchMyCars, updateCarName } from "../api/myCarsApi";
import { useStrings } from "../contexts/SettingsContext";
import { formatDate } from "../utils/format";
import AuthenticatedImage from "../components/AuthenticatedImage";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import Input from "../components/ui/Input";
import Modal, { ConfirmModal } from "../components/ui/Modal";
import { EmptyState, PageHeader, Spinner } from "../components/layout/AppChrome";
import Toast from "../components/ui/Toast";
import { IconCar, IconImage } from "../components/ui/Icons";

export default function MyCarsPage() {
  const s = useStrings();
  const [cars, setCars] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [createOpen, setCreateOpen] = useState(false);
  const [renameTarget, setRenameTarget] = useState(null);
  const [deleteTarget, setDeleteTarget] = useState(null);
  const [nameInput, setNameInput] = useState("");

  const load = async () => {
    setLoading(true);
    try {
      setCars(await fetchMyCars());
    } catch (e) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const handleCreate = async () => {
    if (!nameInput.trim()) return;
    await createCar(nameInput.trim());
    setCreateOpen(false);
    setNameInput("");
    load();
  };

  const handleRename = async () => {
    if (!renameTarget || !nameInput.trim()) return;
    await updateCarName(renameTarget.id, nameInput.trim());
    setRenameTarget(null);
    setNameInput("");
    load();
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    await deleteCar(deleteTarget.id);
    setDeleteTarget(null);
    load();
  };

  return (
    <div>
      <PageHeader
        title={s.navCars}
        action={
          <Button
            onClick={() => {
              setNameInput("");
              setCreateOpen(true);
            }}
          >
            + {s.createCar}
          </Button>
        }
      />

      {loading ? (
        <div className="flex justify-center py-16">
          <Spinner />
        </div>
      ) : cars.length === 0 ? (
        <EmptyState
          icon={<IconCar />}
          title={s.emptyCars}
          subtitle={s.emptyCarsSubtitle}
          action={
            <Link to="/app/capture?mode=gallery">
              <Button>{s.takePhoto}</Button>
            </Link>
          }
        />
      ) : (
        <div className="grid gap-4 sm:grid-cols-2">
          {cars.map((car) => {
            const coverRender = car.renders?.at(-1);
            const coverUrl = coverRender?.rendered_url || coverRender?.original_url;

            return (
            <Link key={car.id} to={`/app/cars/${car.id}`}>
              <Card elevated className="h-full">
                <div className="mb-4 aspect-[16/10] overflow-hidden rounded-input bg-surface-muted">
                  {coverUrl ? (
                    <AuthenticatedImage
                      src={coverUrl}
                      alt={car.name}
                      className="h-full w-full object-cover"
                      fallback={
                        <div className="flex h-full items-center justify-center text-brand-600">
                          <IconImage className="h-12 w-12 opacity-60" />
                        </div>
                      }
                    />
                  ) : (
                    <div className="flex h-full items-center justify-center text-brand-600">
                      <IconImage className="h-12 w-12 opacity-60" />
                    </div>
                  )}
                </div>
                <h3 className="text-lg font-semibold text-ink">{car.name}</h3>
                <p className="mt-1 text-sm text-ink-secondary">
                  {car.renders?.length || 0} renders · {formatDate(car.created_at)}
                </p>
                <div className="mt-4 flex gap-2" onClick={(e) => e.preventDefault()}>
                  <Button
                    size="sm"
                    variant="secondary"
                    onClick={(e) => {
                      e.preventDefault();
                      setRenameTarget(car);
                      setNameInput(car.name);
                    }}
                  >
                    {s.renameCar}
                  </Button>
                  <Button
                    size="sm"
                    variant="danger"
                    onClick={(e) => {
                      e.preventDefault();
                      setDeleteTarget(car);
                    }}
                  >
                    {s.deleteCar}
                  </Button>
                </div>
              </Card>
            </Link>
            );
          })}
        </div>
      )}

      <Modal
        open={createOpen || Boolean(renameTarget)}
        title={renameTarget ? s.renameCar : s.createCar}
        onClose={() => {
          setCreateOpen(false);
          setRenameTarget(null);
        }}
        footer={
          <>
            <Button
              variant="ghost"
              onClick={() => {
                setCreateOpen(false);
                setRenameTarget(null);
              }}
            >
              {s.cancel}
            </Button>
            <Button onClick={renameTarget ? handleRename : handleCreate}>{s.confirm}</Button>
          </>
        }
      >
        <Input
          label={s.carName}
          placeholder={s.carNameHint}
          value={nameInput}
          onChange={(e) => setNameInput(e.target.value)}
        />
      </Modal>

      <ConfirmModal
        open={Boolean(deleteTarget)}
        title={s.deleteCar}
        body={`Delete "${deleteTarget?.name}" and all renders?`}
        confirmLabel={s.deleteCar}
        cancelLabel={s.cancel}
        danger
        onConfirm={handleDelete}
        onClose={() => setDeleteTarget(null)}
      />

      <Toast message={error} onClose={() => setError("")} />
    </div>
  );
}
