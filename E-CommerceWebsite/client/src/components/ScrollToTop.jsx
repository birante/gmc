import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';

export default function ScrollToTop() {
  const { pathname } = useLocation();
  useEffect(() => {
    if (typeof window.scrollTo === 'function') {
      try { window.scrollTo(0, 0); } catch { /* jsdom */ }
    }
  }, [pathname]);
  return null;
}
