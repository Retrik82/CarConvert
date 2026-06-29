export default function GradientText({ text, highlight, className = "", as: Tag = "span" }) {
  if (!highlight || !text.includes(highlight)) {
    return <Tag className={className}>{text}</Tag>;
  }

  const [before, after] = text.split(highlight);

  return (
    <Tag className={className}>
      {before}
      <span className="gradient-text">{highlight}</span>
      {after}
    </Tag>
  );
}
