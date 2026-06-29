export function Skeleton({ className = "", rounded = "input" }) {
  const radius = {
    input: "rounded-input",
    card: "rounded-card",
    full: "rounded-full",
  };

  return <div className={`skeleton ${radius[rounded] || radius.input} ${className}`} aria-hidden="true" />;
}

export function CardSkeleton() {
  return (
    <div className="rounded-card border border-[var(--border)]/60 bg-surface p-6 shadow-card">
      <Skeleton className="mb-4 h-12 w-12" rounded="input" />
      <Skeleton className="mb-2 h-5 w-2/3" />
      <Skeleton className="h-4 w-full" />
      <Skeleton className="mt-2 h-4 w-4/5" />
    </div>
  );
}

export function PageSkeleton() {
  return (
    <div className="space-y-6 animate-fade-in">
      <Skeleton className="h-10 w-1/3" />
      <Skeleton className="h-4 w-1/2" />
      <Skeleton className="aspect-[16/10] w-full" rounded="card" />
      <div className="grid gap-4 sm:grid-cols-2">
        <CardSkeleton />
        <CardSkeleton />
      </div>
    </div>
  );
}
