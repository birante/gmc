// Express server for the routing checkpoint.
//   * three pages: /, /services, /contact
//   * shared nav bar and CSS
//   * custom working-hours middleware gates every page

const express = require("express");
const path    = require("path");
const { workingHoursMiddleware } = require("./middleware/workingHours");

const app  = express();
const PORT = Number(process.env.PORT) || 3000;

// View engine
app.set("view engine", "ejs");
app.set("views", path.join(__dirname, "views"));

// Static assets (CSS)
app.use(express.static(path.join(__dirname, "public")));

// The working-hours gate applies to every page-request below.
app.use(workingHoursMiddleware());

app.get("/", (req, res) => {
  res.render("home", { title: "Home", active: "home" });
});

app.get("/services", (req, res) => {
  res.render("services", { title: "Our Services", active: "services" });
});

app.get("/contact", (req, res) => {
  res.render("contact", { title: "Contact Us", active: "contact" });
});

// 404 fallback (still respects the working-hours gate — if we got here,
// the middleware already let the request through).
app.use((req, res) => {
  res.status(404).render("closed", { title: "Not Found", currentTime: "" });
});

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Express app listening on http://localhost:${PORT}`);
  });
}

module.exports = app;
