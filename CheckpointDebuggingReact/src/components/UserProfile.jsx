// FIX #2 (wrong prop name):
//   Buggy version received `{ userInfo }` but the parent passed `user`.
//   In React DevTools this shows up immediately: click <UserProfile>
//   in the Components tab, and the right panel shows the actual prop
//   name (`user`) — but the code was reading `userInfo`, giving
//   `undefined` and a blank profile.

export default function UserProfile({ user }) {
  return (
    <section className="profile">
      <img
        className="avatar"
        src={user.avatar}
        alt={`${user.name} avatar`}
        width={64}
        height={64}
      />
      <div>
        <h2 className="profile-name">{user.name}</h2>
        <p className="profile-email">{user.email}</p>
      </div>
    </section>
  );
}
