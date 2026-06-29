export default function BeforeAfterPreview({ beforeUrl, afterUrl }) {
  return (
    <div className="grid gap-4 md:grid-cols-2">
      <div className="rounded-2xl border border-slate-700/70 bg-slate-900/45 p-3">
        <p className="mb-2 text-xs uppercase tracking-wider text-ink-tertiary">Before</p>
        {beforeUrl ? (
          <img src={beforeUrl} alt="Original car" className="h-64 w-full rounded-xl object-cover md:h-80" />
        ) : (
          <div className="flex h-64 items-center justify-center rounded-xl bg-slate-900/60 text-sm text-ink-secondary md:h-80">
            Upload source image
          </div>
        )}
      </div>
      <div className="rounded-2xl border border-slate-700/70 bg-slate-900/45 p-3">
        <p className="mb-2 text-xs uppercase tracking-wider text-ink-tertiary">After</p>
        {afterUrl ? (
          <img src={afterUrl} alt="Generated background" className="h-64 w-full rounded-xl object-cover md:h-80" />
        ) : (
          <div className="flex h-64 items-center justify-center rounded-xl bg-slate-900/60 text-sm text-ink-secondary md:h-80">
            Generated result appears here
          </div>
        )}
      </div>
    </div>
  );
}
