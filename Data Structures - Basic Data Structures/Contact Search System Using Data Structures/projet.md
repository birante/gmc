# Checkpoint: Contact Search System Using Data Structures

## Objective
Build a simple contact management system in JavaScript that combines:

- A **doubly linked list** to store contacts (forward / backward traversal).
- A **hash table** (`Map`) for O(1) exact lookup by name.
- A **naive substring search** to find contacts by keyword.
- A **text menu** to interact with the system in the terminal.

## Idea

1. Define a `Contact` class with `name` and `phone`.
2. Wrap each contact in a `Node` with `prev` and `next` pointers.
3. Maintain:
   - A `DoublyLinkedList` (head / tail) for ordered storage.
   - A `Map` (`name → contact`) for fast exact-name lookup.
4. Both structures reference the **same** `Contact` object, so adding once
   keeps them synchronized.
5. The menu loops with `readline` and dispatches on the chosen option.

## JavaScript Implementation

```js
// contactSystem.js
const readline = require("readline");

// 1. Contact class
class Contact {
	constructor(name, phone) {
		this.name = name;
		this.phone = phone;
	}
}

// 2. Doubly linked list node
class Node {
	constructor(contact) {
		this.contact = contact;
		this.prev = null;
		this.next = null;
	}
}

// 3. Doubly linked list
class DoublyLinkedList {
	constructor() {
		this.head = null;
		this.tail = null;
	}

	append(contact) {
		const node = new Node(contact);
		if (!this.head) {
			this.head = node;
			this.tail = node;
		} else {
			node.prev = this.tail;
			this.tail.next = node;
			this.tail = node;
		}
	}

	forEachForward(callback) {
		let current = this.head;
		while (current) {
			callback(current.contact);
			current = current.next;
		}
	}

	forEachBackward(callback) {
		let current = this.tail;
		while (current) {
			callback(current.contact);
			current = current.prev;
		}
	}
}

// 4. Naive substring search
function naiveSearch(text, pattern) {
	if (pattern.length === 0) return true;
	const t = text.toLowerCase();
	const p = pattern.toLowerCase();
	for (let i = 0; i <= t.length - p.length; i++) {
		let j = 0;
		while (j < p.length && t[i + j] === p[j]) j++;
		if (j === p.length) return true;
	}
	return false;
}

// 5. Contact manager: list + hash table
class ContactManager {
	constructor() {
		this.list = new DoublyLinkedList();
		this.table = new Map(); // name -> Contact
	}

	add(name, phone) {
		if (this.table.has(name)) {
			console.log(`A contact named "${name}" already exists.`);
			return;
		}
		const contact = new Contact(name, phone);
		this.list.append(contact);    // same reference...
		this.table.set(name, contact); // ...stored in the hash table
		console.log("Contact added.");
	}

	searchByKeyword(keyword) {
		const matches = [];
		this.list.forEachForward((c) => {
			if (naiveSearch(c.name, keyword)) matches.push(c);
		});
		if (matches.length === 0) {
			console.log("No match.");
		} else {
			matches.forEach((c) =>
				console.log(`Match found: ${c.name} - ${c.phone}`)
			);
		}
	}

	searchByName(name) {
		const c = this.table.get(name);
		if (c) console.log(`Found: ${c.name} - ${c.phone}`);
		else console.log("Contact not found.");
	}

	displayForward() {
		console.log("--- Forward ---");
		this.list.forEachForward((c) =>
			console.log(`${c.name} - ${c.phone}`)
		);
	}

	displayBackward() {
		console.log("--- Backward ---");
		this.list.forEachBackward((c) =>
			console.log(`${c.name} - ${c.phone}`)
		);
	}
}

// 6. Text menu
const rl = readline.createInterface({
	input: process.stdin,
	output: process.stdout,
});

const ask = (q) => new Promise((resolve) => rl.question(q, resolve));

async function main() {
	const manager = new ContactManager();

	while (true) {
		console.log(`
1. Add Contact
2. Search by Keyword
3. Search by Exact Name
4. View All (Forward)
5. View All (Backward)
6. Exit
`);
		const option = (await ask("Enter option: ")).trim();

		if (option === "1") {
			const name = (await ask("Name: ")).trim();
			const phone = (await ask("Phone: ")).trim();
			manager.add(name, phone);
		} else if (option === "2") {
			const keyword = (await ask("Search keyword: ")).trim();
			manager.searchByKeyword(keyword);
		} else if (option === "3") {
			const name = (await ask("Exact name: ")).trim();
			manager.searchByName(name);
		} else if (option === "4") {
			manager.displayForward();
		} else if (option === "5") {
			manager.displayBackward();
		} else if (option === "6") {
			rl.close();
			break;
		} else {
			console.log("Invalid option.");
		}
	}
}

main();
```

## How to Run

```bash
node contactSystem.js
```

## Example Session

```text
1. Add Contact
2. Search by Keyword
3. Search by Exact Name
4. View All (Forward)
5. View All (Backward)
6. Exit

Enter option: 1
Name: Alice
Phone: 1234567890
Contact added.

Enter option: 2
Search keyword: Al
Match found: Alice - 1234567890
```

## Why This Matches the Instructions

1. **Contact class** with `name` and `phone` — defined.
2. **Doubly linked list** with `prev` / `next` pointers powers forward and
   backward display.
3. **Hash table** (`Map`) stores contacts by name for O(1) exact lookup.
4. **Naive substring search** scans each name character by character.
5. **Same reference** is stored in both the list and the hash table, so the
   two structures never drift apart.
6. **Text menu** exposes every required operation.

## Complexity

| Operation              | Structure used        | Time   |
|------------------------|-----------------------|--------|
| Add contact            | Linked list + Map     | O(1)   |
| Search by exact name   | Hash table            | O(1)   |
| Search by keyword      | Naive substring scan  | O(n·m) |
| Display forward / back | Doubly linked list    | O(n)   |

Where `n` is the number of contacts and `m` the average name length.
