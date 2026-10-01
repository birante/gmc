import { initials } from '../utils/format.js';

export default function Avatar({ user, size = 36, online = false }) {
  const name = user?.username || '?';
  return (
    <span
      className="avatar"
      style={{ background: user?.avatarColor || '#64748b', width: size, height: size, fontSize: size * 0.4 }}
      title={name}
      aria-label={`Avatar de ${name}`}
      role="img"
    >
      {initials(name)}
      {online && <span className="avatar-dot" aria-hidden="true" />}
    </span>
  );
}
