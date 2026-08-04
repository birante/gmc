import UserList from "./UserList.js";

export default function App() {
  return (
    <div className="app">
      <header className="app__header">
        <h1>Users</h1>
        <p className="app__subtitle">
          Data fetched with axios from
          {" "}
          <a href="https://jsonplaceholder.typicode.com/users" target="_blank" rel="noopener">
            jsonplaceholder.typicode.com/users
          </a>
        </p>
      </header>
      <UserList />
    </div>
  );
}
