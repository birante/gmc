# Checkpoint: Sorting and Searching Algorithms

## Objective
Implement Insertion Sort using JavaScript.

Insertion sort works like sorting cards in your hand:
each new card is inserted in the correct position among already sorted cards.

## Requirement Focus

- Use 2 counters.
- At step `i`, only the first `i - 1` elements are considered sorted.
- Pick `arr[i]` and insert it into the sorted part `arr[0 ... i-1]`.

## JavaScript Implementation

```js
function insertionSort(arr) {
	// Counter 1: i moves from left to right through the array.
	for (let i = 1; i < arr.length; i++) {
		const key = arr[i];

		// Counter 2: j scans the sorted part from right to left.
		let j = i - 1;

		while (j >= 0 && arr[j] > key) {
			arr[j + 1] = arr[j];
			j--;
		}

		arr[j + 1] = key;
	}

	return arr;
}

// Example
const data = [5, 2, 4, 6, 1, 3];
console.log(insertionSort(data)); // [1, 2, 3, 4, 5, 6]
```

## Why This Matches the Instructions

1. The sorted section is built progressively: before each insertion, `arr[0 ... i-1]` is sorted.
2. The current element `arr[i]` is stored in `key` and inserted at the right place.
3. Exactly two loop counters are used:
	 - `i` for the main pass
	 - `j` for backward comparison and shifting

## Complexity

- Time: `O(n^2)` in the average and worst cases
- Best case (already sorted): `O(n)`
- Space: `O(1)` (in-place sort)

