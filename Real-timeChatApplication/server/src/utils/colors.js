export const AVATAR_COLORS = [
  '#e76f51', '#f4a261', '#2a9d8f', '#264653', '#8e44ad',
  '#3a86ff', '#ff006e', '#fb5607', '#06a77d', '#d62828',
];

export function randomAvatarColor() {
  return AVATAR_COLORS[Math.floor(Math.random() * AVATAR_COLORS.length)];
}
