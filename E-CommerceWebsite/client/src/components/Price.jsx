import { formatPrice } from '../utils/format.js';

export default function Price({ value, className = '' }) {
  return <span className={`price ${className}`}>{formatPrice(value)}</span>;
}
