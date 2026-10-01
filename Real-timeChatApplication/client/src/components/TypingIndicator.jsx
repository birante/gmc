import { typingText } from '../utils/format.js';

export default function TypingIndicator({ names }) {
  const text = typingText(names);
  return (
    <div className="typing" aria-live="polite">
      {text && (
        <>
          <span className="typing-dots" aria-hidden="true"><i /><i /><i /></span>
          <span>{text}</span>
        </>
      )}
    </div>
  );
}
