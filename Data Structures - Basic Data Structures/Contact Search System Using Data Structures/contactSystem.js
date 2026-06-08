const readline = require("readline");

class Contact {
	constructor(name, phone) {
		this.name = name;
		this.phone = phone;
	}
}

class Node {
	constructor(contact) {
		this.contact = contact;
		this.prev = null;
		this.next = null;
	}
}

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

class ContactManager {
	constructor() {
		this.list = new DoublyLinkedList();
		this.table = new Map();
	}

	add(name, phone) {
		if (this.table.has(name)) {
			console.log(`A contact named "${name}" already exists.`);
			return;
		}
		const contact = new Contact(name, phone);
		this.list.append(contact);
		this.table.set(name, contact);
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
