import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import EventCard from '../components/EventCard.jsx';

const event = {
  id: 'abc123',
  title: 'Meetup JavaScript Dakar',
  date: new Date(Date.now() + 86400000 * 3).toISOString(),
  location: 'Impact Hub, Dakar',
  category: 'Tech',
  capacity: 50,
  seatsLeft: 30,
  isPast: false,
  isRegistered: true,
  imageUrl: 'https://picsum.photos/seed/x/800/400',
  organizer: { name: 'Aminata Diop' },
};

describe('EventCard', () => {
  it("affiche les informations principales et un lien vers le détail", () => {
    render(
      <MemoryRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <EventCard event={event} />
      </MemoryRouter>
    );
    expect(screen.getByRole('heading', { name: 'Meetup JavaScript Dakar' })).toBeInTheDocument();
    expect(screen.getByText(/Impact Hub, Dakar/)).toBeInTheDocument();
    expect(screen.getByText('30 places restantes')).toBeInTheDocument();
    expect(screen.getByText('✓ Inscrit')).toBeInTheDocument();
    expect(screen.getByText('par Aminata Diop')).toBeInTheDocument();
    expect(screen.getByRole('link')).toHaveAttribute('href', '/events/abc123');
  });
});
