export default function Rating({ value = 0 }) {
  const full = Math.round(value);
  return (
    <span className="rating" aria-label={`Note : ${value} sur 5`} title={`${value} / 5`}>
      {'★'.repeat(full)}
      <span className="rating-off">{'★'.repeat(5 - full)}</span>
      <span className="rating-num">{Number(value).toFixed(1)}</span>
    </span>
  );
}
