import { Link } from "react-router-dom";
import { useStrings } from "../contexts/SettingsContext";
import MarketingLayout from "../components/layout/MarketingLayout";
import BeforeAfterSlider from "../components/BeforeAfterSlider";
import Button from "../components/ui/Button";
import Card from "../components/ui/Card";
import Reveal from "../components/ui/Reveal";
import GradientText from "../components/ui/GradientText";
import Accordion from "../components/ui/Accordion";
import { IconCheck } from "../components/ui/Icons";

function FeatureCard({ image, title, body, delay = 0 }) {
  return (
    <Reveal delay={delay}>
      <Card className="group h-full overflow-hidden p-0" elevated>
        <div className="aspect-[16/10] overflow-hidden">
          <img
            src={image}
            alt=""
            className="h-full w-full object-cover transition duration-500 group-hover:scale-105"
            loading="lazy"
            decoding="async"
            sizes="(max-width: 768px) 100vw, 33vw"
          />
        </div>
        <div className="p-5 sm:p-6">
          <h3 className="text-lg font-semibold text-ink">{title}</h3>
          <p className="mt-2 text-sm leading-relaxed text-ink-secondary">{body}</p>
        </div>
      </Card>
    </Reveal>
  );
}

function StepCard({ number, title, body, delay = 0 }) {
  return (
    <Reveal delay={delay}>
      <div className="relative rounded-card border border-[var(--border)]/80 bg-surface p-5 shadow-card transition hover:-translate-y-1 hover:shadow-elevated sm:p-6">
        <div className="mb-4 flex h-10 w-10 items-center justify-center rounded-full bg-gradient-primary text-sm font-bold text-white shadow-button">
          {number}
        </div>
        <h3 className="font-semibold text-ink">{title}</h3>
        <p className="mt-2 text-sm leading-relaxed text-ink-secondary">{body}</p>
      </div>
    </Reveal>
  );
}

export default function OnboardingPage() {
  const s = useStrings();

  return (
    <MarketingLayout>
      <section className="section-container pb-12 pt-6 sm:pb-16 sm:pt-8 md:pb-24 md:pt-12">
        <div className="grid items-center gap-8 sm:gap-12 lg:grid-cols-2 lg:gap-16">
          <Reveal>
            <p className="mb-3 text-sm font-semibold uppercase tracking-wider text-brand-600 sm:mb-4">{s.heroEyebrow}</p>
            <h1 className="text-3xl font-bold tracking-tight text-ink sm:text-4xl lg:text-5xl lg:leading-[1.1]">
              <GradientText text={s.welcomeTitle} highlight={s.appName} />
            </h1>
            <p className="mt-4 max-w-lg text-base leading-relaxed text-ink-secondary sm:mt-5 sm:text-lg">{s.welcomeSubtitle}</p>
            <p className="mt-2 text-sm text-ink-tertiary">{s.appTagline}</p>

            <div className="mt-6 flex flex-col gap-3 sm:mt-8 sm:flex-row sm:items-center">
              <Link to="/register" className="w-full sm:w-auto">
                <Button size="lg" className="w-full sm:w-auto">
                  {s.heroCta}
                </Button>
              </Link>
              <Link to="/login" className="w-full sm:w-auto">
                <Button variant="secondary" size="lg" className="w-full sm:w-auto">
                  {s.login}
                </Button>
              </Link>
              <a href="#how-it-works" className="w-full sm:w-auto">
                <Button variant="ghost" size="lg" className="w-full sm:w-auto">
                  {s.heroSecondaryCta}
                </Button>
              </a>
            </div>

            <ul className="mt-8 grid gap-3 sm:mt-10 sm:grid-cols-3">
              {s.downloadAppFeatures.map((feature) => (
                <li
                  key={feature}
                  className="flex items-start gap-2 rounded-input border border-[var(--border)]/60 bg-surface-muted/50 px-3 py-2.5 text-xs text-ink-secondary"
                >
                  <IconCheck className="mt-0.5 h-4 w-4 shrink-0 text-brand-600" />
                  {feature}
                </li>
              ))}
            </ul>
          </Reveal>

          <Reveal delay={150}>
            <div className="relative min-w-0">
              <div className="absolute -inset-4 rounded-card bg-gradient-to-br from-brand-600/10 to-violet-600/10 blur-2xl" aria-hidden="true" />
              <BeforeAfterSlider
                beforeUrl="/images/before-street.jpg"
                afterUrl="/images/after-showroom.jpg"
                className="relative shadow-elevated"
              />
            </div>
          </Reveal>
        </div>
      </section>

      <section className="relative overflow-hidden bg-surface" aria-hidden="true">
        <div className="hero-car-bleed">
          <img
            src="/images/hero-car.jpg"
            alt=""
            className="hero-car-image"
            loading="lazy"
            decoding="async"
            sizes="100vw"
          />
        </div>
      </section>

      <section id="features" className="section-container scroll-mt-20 py-16 sm:scroll-mt-24 sm:py-20">
        <Reveal className="mx-auto max-w-2xl text-center">
          <h2 className="text-3xl font-bold tracking-tight text-ink sm:text-4xl">{s.featuresTitle}</h2>
          <p className="mt-4 text-ink-secondary">{s.featuresSubtitle}</p>
        </Reveal>

        <div className="mt-10 grid gap-6 sm:mt-12 md:grid-cols-3">
          <FeatureCard image="/images/before-street.jpg" title={s.featureAiTitle} body={s.featureAiBody} />
          <FeatureCard image="/images/feature-workshop.jpg" title={s.featureCaptureTitle} body={s.featureCaptureBody} delay={100} />
          <FeatureCard image="/images/feature-showroom.jpg" title={s.featureGarageTitle} body={s.featureGarageBody} delay={200} />
        </div>
      </section>

      <section id="how-it-works" className="section-container scroll-mt-20 py-16 sm:scroll-mt-24 sm:py-20">
        <Reveal className="mx-auto max-w-2xl text-center">
          <h2 className="text-3xl font-bold tracking-tight text-ink sm:text-4xl">{s.howItWorksTitle}</h2>
          <p className="mt-4 text-ink-secondary">{s.howItWorksSubtitle}</p>
        </Reveal>

        <div className="mt-10 grid gap-6 sm:mt-12 md:grid-cols-3">
          <StepCard number="1" title={s.step1Title} body={s.step1Body} />
          <StepCard number="2" title={s.step2Title} body={s.step2Body} delay={100} />
          <StepCard number="3" title={s.step3Title} body={s.step3Body} delay={200} />
        </div>
      </section>

      <section id="faq" className="section-container scroll-mt-20 py-16 sm:scroll-mt-24 sm:py-20">
        <Reveal className="mx-auto max-w-2xl text-center">
          <h2 className="text-3xl font-bold tracking-tight text-ink sm:text-4xl">{s.faqTitle}</h2>
        </Reveal>
        <Reveal delay={100} className="mx-auto mt-8 max-w-2xl sm:mt-10">
          <Accordion items={s.faqItems} />
        </Reveal>
      </section>

      <section className="section-container pb-16 sm:pb-20">
        <Reveal>
          <div className="relative overflow-hidden rounded-card bg-gradient-primary p-6 text-center text-white shadow-elevated sm:p-12">
            <div
              className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_30%_20%,rgba(255,255,255,0.15),transparent_50%)]"
              aria-hidden="true"
            />
            <h2 className="relative text-2xl font-bold sm:text-3xl">{s.ctaBannerTitle}</h2>
            <p className="relative mx-auto mt-3 max-w-lg text-white/85">{s.ctaBannerBody}</p>
            <div className="relative mt-6 flex flex-col justify-center gap-3 sm:mt-8 sm:flex-row">
              <Link to="/register" className="w-full sm:w-auto">
                <Button size="lg" className="w-full min-w-[200px] sm:w-auto">
                  {s.heroCta}
                </Button>
              </Link>
              <Link to="/login" className="w-full sm:w-auto">
                <Button variant="secondary" size="lg" className="w-full min-w-[200px] sm:w-auto">
                  {s.login}
                </Button>
              </Link>
            </div>
          </div>
        </Reveal>
      </section>
    </MarketingLayout>
  );
}
