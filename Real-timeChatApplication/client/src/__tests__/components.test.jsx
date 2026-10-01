import { describe, expect, it, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import Avatar from '../components/Avatar.jsx';
import MessageItem from '../components/MessageItem.jsx';
import TypingIndicator from '../components/TypingIndicator.jsx';
import MessageInput from '../components/MessageInput.jsx';
import RoomList from '../components/RoomList.jsx';
import OnlineUsers from '../components/OnlineUsers.jsx';

const awa = { id: 'u1', username: 'awa', avatarColor: 'rgb(231, 111, 81)' };

describe('Avatar', () => {
  it('affiche les initiales sur la couleur de l’utilisateur', () => {
    render(<Avatar user={awa} />);
    const el = screen.getByRole('img', { name: 'Avatar de awa' });
    expect(el).toHaveTextContent('AW');
    expect(el).toHaveStyle({ background: 'rgb(231, 111, 81)' });
  });
});

describe('MessageItem', () => {
  it("affiche l'auteur, le texte et l'heure", () => {
    const createdAt = new Date(2026, 9, 1, 14, 5).toISOString();
    render(<ul><MessageItem message={{ id: 'm1', text: 'Salut !', createdAt, user: awa }} /></ul>);
    expect(screen.getByText('awa')).toBeInTheDocument();
    expect(screen.getByText('Salut !')).toBeInTheDocument();
    expect(screen.getByText('14:05')).toBeInTheDocument();
  });

  it('affiche « Vous » pour mes messages', () => {
    render(<ul><MessageItem mine message={{ id: 'm1', text: 'Moi', createdAt: new Date().toISOString(), user: awa }} /></ul>);
    expect(screen.getByText('Vous')).toBeInTheDocument();
  });
});

describe('TypingIndicator', () => {
  it('affiche qui écrit', () => {
    render(<TypingIndicator names={['Moussa']} />);
    expect(screen.getByText("Moussa est en train d'écrire…")).toBeInTheDocument();
  });
  it("n'affiche rien sans saisie", () => {
    const { container } = render(<TypingIndicator names={[]} />);
    expect(container.textContent).toBe('');
  });
});

describe('MessageInput', () => {
  it('envoie le message avec Entrée et signale la saisie', async () => {
    const onSend = vi.fn().mockResolvedValue();
    const onTyping = vi.fn();
    render(<MessageInput onSend={onSend} onTyping={onTyping} />);
    const box = screen.getByLabelText('Message');
    await userEvent.type(box, 'Bonjour{Enter}');
    expect(onTyping).toHaveBeenCalledWith(true);
    expect(onSend).toHaveBeenCalledWith('Bonjour');
    expect(onTyping).toHaveBeenLastCalledWith(false);
    expect(box).toHaveValue('');
  });

  it("affiche l'erreur si l'envoi échoue", async () => {
    const onSend = vi.fn().mockRejectedValue(new Error('Le message est vide'));
    render(<MessageInput onSend={onSend} />);
    await userEvent.type(screen.getByLabelText('Message'), 'x');
    await userEvent.click(screen.getByRole('button', { name: 'Envoyer' }));
    expect(await screen.findByRole('alert')).toHaveTextContent('Le message est vide');
  });
});

describe('RoomList', () => {
  it('sépare mes salons des salons à découvrir et sélectionne', async () => {
    const onSelect = vi.fn();
    const rooms = [
      { id: 'r1', name: 'Général', memberCount: 2, isMember: true },
      { id: 'r2', name: 'Tech', memberCount: 1, isMember: false },
    ];
    render(<RoomList rooms={rooms} activeId="r1" onSelect={onSelect} />);
    expect(screen.getByText('Mes salons')).toBeInTheDocument();
    expect(screen.getByText('À découvrir')).toBeInTheDocument();
    await userEvent.click(screen.getByText('Tech'));
    expect(onSelect).toHaveBeenCalledWith('r2');
  });
});

describe('OnlineUsers', () => {
  it('liste les membres en ligne et hors ligne', () => {
    const moussa = { id: 'u2', username: 'moussa', avatarColor: '#3a86ff' };
    render(<OnlineUsers users={[awa]} members={[awa, moussa]} currentUserId="u1" />);
    expect(screen.getByText('En ligne — 1')).toBeInTheDocument();
    expect(screen.getByText('Hors ligne — 1')).toBeInTheDocument();
    expect(screen.getByText('moussa')).toBeInTheDocument();
  });
});
