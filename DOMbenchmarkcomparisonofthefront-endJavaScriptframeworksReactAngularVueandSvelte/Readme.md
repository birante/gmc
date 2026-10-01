What You're Aiming For
Objective

The objective of this exercise is for students to benchmark and compare the performance of popular front-end JavaScript frameworks (React, Angular, Vue, and Svelte) in handling DOM manipulations. Through hands-on coding, students will explore how these frameworks handle common DOM operations, such as rendering, updating, and deleting elements, and analyze their efficiency in different scenarios.

You will build a simple web application in each framework and perform a series of DOM operations while measuring performance metrics, such as time to render, time to update, and memory usage.

Part 1: Implementing the DOM Operations

Implement a basic to-do list application in each of the following frameworks: React, Angular, Vue, and Svelte, with the following functionality:

Add tasks to the to-do list (task name and priority).
View all tasks with their priority levels.
Update tasks (edit task name or priority).
Remove tasks from the list.
Use the core features of each framework to manage the DOM efficiently:

React: Use components and state management to update the DOM.
Angular: Use Angular’s directives (ngFor, ngIf) and two-way data binding to manage DOM changes.
Vue: Leverage Vue’s reactive system and directives to render and update the DOM.
Svelte: Utilize Svelte’s compile-time DOM updates to minimize runtime overhead.
Example Behavior:

The to-do list should handle adding, updating, and removing tasks efficiently, even with a large number of tasks.
Performance metrics such as initial render time and update time should be recorded.
Part 2: Benchmark and Analyze Performance

Now, benchmark the performance of each framework for the following operations:

Initial Rendering: Measure the time taken to render 100, 500, and 1000 tasks.
DOM Updates: Measure the time taken to update 50 tasks.
DOM Deletion: Measure the time taken to delete 50 tasks.
Use appropriate tools such as Chrome DevTools or third-party libraries to measure the performance of each operation.


Instructions
Deliverables

Submit a GitHub link with:

Application Code: Submit the to-do list application implementation for React, Angular, Vue, and Svelte.
Benchmark Results: Submit a comparison of performance metrics for each framework in a table or chart format.
Short Reflection Report (200–300 words):
What challenges did you face in optimizing DOM operations for each framework?
How did each framework’s approach to DOM updates affect performance?
Which framework demonstrated the best performance in which scenarios, and why?


