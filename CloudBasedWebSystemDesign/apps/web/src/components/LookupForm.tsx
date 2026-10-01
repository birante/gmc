import { useState, type FormEvent } from 'react';

interface Props {
  onSubmit: (referenceCode: string, phoneLast4: string) => void | Promise<void>;
  busy?: boolean;
}

/** Caregiver form: card number + last 4 digits of the phone number registered at the clinic. */
export function LookupForm({ onSubmit, busy }: Props) {
  const [code, setCode] = useState('');
  const [last4, setLast4] = useState('');
  const [error, setError] = useState<string | null>(null);

  const handle = (e: FormEvent) => {
    e.preventDefault();
    if (code.trim().length < 6) return setError('Enter the card number printed on the vaccination card.');
    if (!/^\d{4}$/.test(last4)) return setError('Enter exactly 4 digits.');
    setError(null);
    void onSubmit(code.trim().toUpperCase(), last4);
  };

  return (
    <form onSubmit={handle} className="space-y-4" noValidate>
      <div>
        <label htmlFor="code" className="label">Card number</label>
        <input id="code" className="input uppercase" placeholder="VX-XXXX-XXXX" value={code} onChange={(e) => setCode(e.target.value)} />
      </div>
      <div>
        <label htmlFor="last4" className="label">Last 4 digits of the guardian&apos;s phone</label>
        <input id="last4" className="input" inputMode="numeric" maxLength={4} placeholder="1234" value={last4} onChange={(e) => setLast4(e.target.value)} />
      </div>
      {error && <p className="text-sm text-red-600" role="alert">{error}</p>}
      <button type="submit" className="btn-primary w-full" disabled={busy}>
        {busy ? 'Searching...' : 'See vaccination schedule'}
      </button>
    </form>
  );
}
