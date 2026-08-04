// UserList.js — fetches the user list from JSONPlaceholder with axios
// inside a useEffect hook, stores it in listOfUser via useState, and
// maps it to render one card per user.

import { useEffect, useState } from "react";
import axios from "axios";

const API_URL = "https://jsonplaceholder.typicode.com/users";

export default function UserList() {
  const [listOfUser, setListOfUser] = useState([]);
  const [loading, setLoading]       = useState(true);
  const [error, setError]           = useState(null);

  useEffect(() => {
    // AbortController lets us cancel the request if the component
    // unmounts before the response arrives — avoids setting state on
    // an unmounted component (React 18 StrictMode double-mount in dev).
    const controller = new AbortController();

    axios
      .get(API_URL, { signal: controller.signal })
      .then(response => {
        setListOfUser(response.data);
        setError(null);
      })
      .catch(err => {
        if (axios.isCancel(err) || err.name === "CanceledError") return;
        setError(err.message || "Failed to load users");
      })
      .finally(() => setLoading(false));

    return () => controller.abort();
  }, []);

  if (loading) return <p className="status">Loading users…</p>;
  if (error)   return <p className="status status--error">{error}</p>;

  return (
    <ul className="user-list">
      {listOfUser.map(user => (
        <li key={user.id} className="user-card">
          <div className="user-card__avatar" aria-hidden="true">
            {user.name.split(" ").map(w => w[0]).slice(0, 2).join("")}
          </div>
          <div className="user-card__body">
            <h2 className="user-card__name">{user.name}</h2>
            <p className="user-card__meta">@{user.username}</p>
            <dl className="user-card__details">
              <div><dt>Email</dt>   <dd><a href={`mailto:${user.email}`}>{user.email}</a></dd></div>
              <div><dt>Phone</dt>   <dd>{user.phone}</dd></div>
              <div><dt>Company</dt> <dd>{user.company?.name}</dd></div>
              <div><dt>Website</dt> <dd><a href={`https://${user.website}`} target="_blank" rel="noopener">{user.website}</a></dd></div>
              <div><dt>City</dt>    <dd>{user.address?.city}</dd></div>
            </dl>
          </div>
        </li>
      ))}
    </ul>
  );
}
