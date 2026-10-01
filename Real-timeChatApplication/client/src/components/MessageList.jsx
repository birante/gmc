import { Fragment, useEffect, useLayoutEffect, useRef } from 'react';
import MessageItem from './MessageItem.jsx';
import { formatDay, sameDay } from '../utils/format.js';

const GROUP_WINDOW = 5 * 60 * 1000;

export default function MessageList({ messages, currentUserId, hasMore, loadingOlder, onLoadOlder }) {
  const ref = useRef(null);
  const prevHeight = useRef(0);
  const prevFirstId = useRef(null);
  const prevLastId = useRef(null);

  useLayoutEffect(() => {
    const el = ref.current;
    if (!el) return;
    const firstId = messages[0]?.id;
    const lastId = messages[messages.length - 1]?.id;
    if (prevFirstId.current && firstId !== prevFirstId.current && lastId === prevLastId.current) {
      // Messages plus anciens ajoutés en haut : on conserve la position.
      el.scrollTop = el.scrollHeight - prevHeight.current;
    } else if (lastId !== prevLastId.current) {
      const nearBottom = el.scrollHeight - el.scrollTop - el.clientHeight < 160;
      const lastMine = messages[messages.length - 1]?.user?.id === currentUserId;
      if (!prevLastId.current || nearBottom || lastMine) el.scrollTop = el.scrollHeight;
    }
    prevHeight.current = el.scrollHeight;
    prevFirstId.current = firstId;
    prevLastId.current = lastId;
  }, [messages, currentUserId]);

  useEffect(() => {
    prevHeight.current = ref.current?.scrollHeight || 0;
  });

  return (
    <div className="messages" ref={ref}>
      {hasMore && (
        <div className="messages-more">
          <button type="button" className="btn btn-ghost btn-sm" onClick={onLoadOlder} disabled={loadingOlder}>
            {loadingOlder ? 'Chargement…' : 'Charger les messages précédents'}
          </button>
        </div>
      )}
      {messages.length === 0 ? (
        <div className="messages-empty">Aucun message pour l'instant. Lancez la conversation 👋</div>
      ) : (
        <ul className="msg-list">
          {messages.map((m, i) => {
            const prev = messages[i - 1];
            const newDay = !prev || !sameDay(prev.createdAt, m.createdAt);
            const grouped =
              !newDay && prev.user?.id === m.user?.id && new Date(m.createdAt) - new Date(prev.createdAt) < GROUP_WINDOW;
            return (
              <Fragment key={m.id}>
                {newDay && (
                  <li className="day-sep" role="separator">
                    <span>{formatDay(m.createdAt)}</span>
                  </li>
                )}
                <MessageItem message={m} mine={m.user?.id === currentUserId} grouped={grouped} />
              </Fragment>
            );
          })}
        </ul>
      )}
    </div>
  );
}
