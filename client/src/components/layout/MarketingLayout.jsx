import { MarketingHeader } from "./AppChrome";
import MarketingFooter from "./MarketingFooter";

export default function MarketingLayout({ children }) {
  return (
    <div className="page-bg flex min-h-screen flex-col">
      <MarketingHeader />
      <main className="flex-1 page-enter">{children}</main>
      <MarketingFooter />
    </div>
  );
}
