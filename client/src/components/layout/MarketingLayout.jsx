import { useEffect } from "react";
import { useLocation } from "react-router-dom";
import { MarketingHeader } from "./AppChrome";
import MarketingFooter from "./MarketingFooter";

function useScrollToHash() {
  const { pathname, hash } = useLocation();

  useEffect(() => {
    if (!hash) return;
    const id = hash.replace("#", "");
    const el = document.getElementById(id);
    if (!el) return;
    requestAnimationFrame(() => {
      el.scrollIntoView({ behavior: "smooth", block: "start" });
    });
  }, [pathname, hash]);
}

export default function MarketingLayout({ children }) {
  useScrollToHash();

  return (
    <div className="page-bg flex min-h-screen flex-col">
      <MarketingHeader />
      <main className="flex-1 page-enter">{children}</main>
      <MarketingFooter />
    </div>
  );
}
