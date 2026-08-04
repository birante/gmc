const express = require("express");
const catchAsync = require("../utils/catchAsync");
const verifyToken = require("../middleware/verifyToken");
const tasks = require("../controllers/taskController");

const router = express.Router();

// Every task route requires a valid JWT — mount once.
router.use(verifyToken);

router.post  ("/",    catchAsync(tasks.create));
router.get   ("/",    catchAsync(tasks.list));
router.delete("/:id", catchAsync(tasks.remove));

module.exports = router;
