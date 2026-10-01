import { useEffect, useRef, useState } from 'react';

const TYPING_IDLE = 2000;

export default function MessageInput({ onSend, onTyping, disabled }) {
  const [text, setText] = useState('');
  const [error, setError] = useState('');
  const [sending, setSending] = useState(false);
  const typingRef = useRef(false);
  const timer = useRef(null);

  const stopTyping = () => {
    clearTimeout(timer.current);
    if (typingRef.current) {
      typingRef.current = false;
      onTyping?.(false);
    }
  };

  useEffect(() => () => stopTyping(), []); // eslint-disable-line react-hooks/exhaustive-deps

  const handleChange = (e) => {
    setText(e.target.value);
    setError('');
    if (!typingRef.current && e.target.value.trim()) {
      typingRef.current = true;
      onTyping?.(true);
    }
    clearTimeout(timer.current);
    timer.current = setTimeout(stopTyping, TYPING_IDLE);
    if (!e.target.value.trim()) stopTyping();
  };

  const submit = async (e) => {
    e.preventDefault();
    const value = text.trim();
    if (!value || sending) return;
    stopTyping();
    setSending(true);
    try {
      await onSend(value);
      setText('');
    } catch (err) {
      setError(err.message || "Échec de l'envoi");
    } finally {
      setSending(false);
    }
  };

  const onKeyDown = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) submit(e);
  };

  return (
    <form className="composer" onSubmit={submit}>
      {error && <div className="composer-error" role="alert">{error}</div>}
      <textarea
        rows={1}
        value={text}
        onChange={handleChange}
        onKeyDown={onKeyDown}
        placeholder={disabled ? 'Connexion en cours…' : 'Écrire un message…'}
        aria-label="Message"
        maxLength={2000}
        disabled={disabled}
      />
      <button type="submit" className="btn btn-primary send" disabled={disabled || sending || !text.trim()} aria-label="Envoyer">
        <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true"><path fill="currentColor" d="M3.4 20.4 21 12 3.4 3.6 3.4 10l12.6 2-12.6 2z" /></svg>
      </button>
    </form>
  );
}
