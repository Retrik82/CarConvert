import { useInView } from "../../hooks/useInView";

export default function Reveal({
  children,
  className = "",
  delay = 0,
  as: Tag = "div",
}) {
  const [ref, inView] = useInView();

  return (
    <Tag
      ref={ref}
      className={`${inView ? "reveal-visible" : "reveal-hidden"} ${className}`}
      style={{ transitionDelay: `${delay}ms` }}
    >
      {children}
    </Tag>
  );
}
