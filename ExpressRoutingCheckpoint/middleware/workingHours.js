// Custom middleware — only allows requests during working hours.
// Working hours: Monday to Friday, 09:00 to 17:00 (server local time).
//
// The middleware factory accepts a `nowProvider` so tests can substitute
// a fixed clock. In addition, TEST_DAY / TEST_HOUR env vars can override
// the current day-of-week / hour without touching the system clock —
// handy to demonstrate the closed page locally.

const WORK_DAY_START = 1;   // Monday   (getDay: Sun=0, Mon=1, …, Sat=6)
const WORK_DAY_END   = 5;   // Friday
const WORK_HOUR_START = 9;  // inclusive
const WORK_HOUR_END   = 17; // exclusive — closes AT 17:00

function isWithinWorkingHours(date) {
  const day  = process.env.TEST_DAY  !== undefined ? Number(process.env.TEST_DAY)  : date.getDay();
  const hour = process.env.TEST_HOUR !== undefined ? Number(process.env.TEST_HOUR) : date.getHours();

  return (
    day  >= WORK_DAY_START  && day  <= WORK_DAY_END &&
    hour >= WORK_HOUR_START && hour <  WORK_HOUR_END
  );
}

function workingHoursMiddleware({ nowProvider = () => new Date() } = {}) {
  return function checkWorkingHours(req, res, next) {
    const now = nowProvider();
    if (isWithinWorkingHours(now)) {
      res.locals.openNow = true;
      return next();
    }
    // Not within hours — render the closed page with a 503 status.
    res.status(503).render("closed", {
      title: "We are closed",
      currentTime: now.toString(),
    });
  };
}

module.exports = { workingHoursMiddleware, isWithinWorkingHours };
