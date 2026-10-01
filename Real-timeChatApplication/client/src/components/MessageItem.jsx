import Avatar from './Avatar.jsx';
import { formatTime } from '../utils/format.js';

export default function MessageItem({ message, mine = false, grouped = false }) {
  return (
    <li className={`msg ${mine ? 'msg-mine' : ''} ${grouped ? 'msg-grouped' : ''}`}>
      <div className="msg-avatar">{!grouped && !mine && <Avatar user={message.user} size={34} />}</div>
      <div className="msg-body">
        {!grouped && (
          <div className="msg-meta">
            <span className="msg-author" style={{ color: mine ? undefined : message.user?.avatarColor }}>
              {mine ? 'Vous' : message.user?.username}
            </span>
          </div>
        )}
        <div className="msg-bubble">
          <p>{message.text}</p>
          <time dateTime={new Date(message.createdAt).toISOString()} className="msg-time">
            {formatTime(message.createdAt)}
          </time>
        </div>
      </div>
    </li>
  );
}
