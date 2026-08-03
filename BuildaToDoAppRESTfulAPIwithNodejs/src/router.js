// Dispatches an incoming request to the right store operation based on
// its method and URL path. All responses go through the small helpers
// in http.js so status codes and content types stay consistent.

import {
  createTodo, listTodos, findTodo, updateTodo, deleteTodo,
} from "./store.js";
import {
  readJsonBody, sendJson, sendError, sendNoContent,
} from "./http.js";

// pathname -> { GET, POST, ... } handler map
export async function route(req, res) {
  const url = new URL(req.url, `http://${req.headers.host ?? "localhost"}`);
  const path = url.pathname.replace(/\/+$/, "") || "/";
  const method = req.method;

  // GET /                  -> friendly root
  if (path === "/" && method === "GET") {
    sendJson(res, 200, {
      name: "todo-restful-api",
      endpoints: [
        "GET    /todos",
        "POST   /todos",
        "GET    /todos/:id",
        "PATCH  /todos/:id",
        "DELETE /todos/:id",
      ],
    });
    return;
  }

  // /todos
  if (path === "/todos") {
    if (method === "GET")  return handleList(res);
    if (method === "POST") return handleCreate(req, res);
    return sendError(res, 405, `Method ${method} not allowed on /todos`);
  }

  // /todos/:id
  const match = path.match(/^\/todos\/([^/]+)$/);
  if (match) {
    const id = match[1];
    if (method === "GET")    return handleGet(id, res);
    if (method === "PATCH")  return handleUpdate(id, req, res);
    if (method === "PUT")    return handleUpdate(id, req, res);   // permissive
    if (method === "DELETE") return handleDelete(id, res);
    return sendError(res, 405, `Method ${method} not allowed on /todos/:id`);
  }

  sendError(res, 404, `No such route: ${method} ${path}`);
}

// --- handlers -------------------------------------------------------------

function handleList(res) {
  sendJson(res, 200, listTodos());
}

async function handleCreate(req, res) {
  let body;
  try { body = await readJsonBody(req); }
  catch (e) { return handleBodyError(e, res); }

  if (!body || typeof body !== "object") {
    return sendError(res, 400, "Body must be a JSON object");
  }
  if (typeof body.title !== "string" || body.title.trim() === "") {
    return sendError(res, 400, "Field 'title' is required and must be a non-empty string");
  }
  if (body.completed !== undefined && typeof body.completed !== "boolean") {
    return sendError(res, 400, "Field 'completed' must be a boolean when provided");
  }
  const todo = createTodo({ title: body.title.trim(), completed: body.completed });
  sendJson(res, 201, todo);
}

function handleGet(id, res) {
  const todo = findTodo(id);
  if (!todo) return sendError(res, 404, `No todo with id '${id}'`);
  sendJson(res, 200, todo);
}

async function handleUpdate(id, req, res) {
  let body;
  try { body = await readJsonBody(req); }
  catch (e) { return handleBodyError(e, res); }

  if (!body || typeof body !== "object") {
    return sendError(res, 400, "Body must be a JSON object");
  }
  if (body.title !== undefined && (typeof body.title !== "string" || body.title.trim() === "")) {
    return sendError(res, 400, "Field 'title' must be a non-empty string when provided");
  }
  if (body.completed !== undefined && typeof body.completed !== "boolean") {
    return sendError(res, 400, "Field 'completed' must be a boolean when provided");
  }
  const patch = {};
  if (body.title !== undefined)     patch.title = body.title.trim();
  if (body.completed !== undefined) patch.completed = body.completed;

  const updated = updateTodo(id, patch);
  if (!updated) return sendError(res, 404, `No todo with id '${id}'`);
  sendJson(res, 200, updated);
}

function handleDelete(id, res) {
  const ok = deleteTodo(id);
  if (!ok) return sendError(res, 404, `No todo with id '${id}'`);
  sendNoContent(res);
}

function handleBodyError(err, res) {
  if (err.code === "PAYLOAD_TOO_LARGE") return sendError(res, 413, err.message);
  if (err.code === "BAD_JSON")          return sendError(res, 400, err.message);
  return sendError(res, 500, "Unexpected error while reading request body");
}
