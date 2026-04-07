// =============================
// String Manipulation Functions
// =============================

function reverseString(str) {
  return str.split("").reverse().join("");
}

function countCharacters(str) {
  return str.length;
}

function capitalizeWords(sentence) {
  return sentence
    .split(" ")
    .map((word) => {
      if (word.length === 0) return "";
      return word[0].toUpperCase() + word.slice(1).toLowerCase();
    })
    .join(" ");
}

// ===============
// Array Functions
// ===============

function findMax(numbers) {
  if (numbers.length === 0) return null;
  return Math.max(...numbers);
}

function findMin(numbers) {
  if (numbers.length === 0) return null;
  return Math.min(...numbers);
}

function sumArray(numbers) {
  return numbers.reduce((sum, current) => sum + current, 0);
}

function filterArray(array, condition) {
  return array.filter(condition);
}

// ======================
// Mathematical Functions
// ======================

function factorial(n) {
  if (n < 0 || !Number.isInteger(n)) {
    return null;
  }

  let result = 1;
  for (let i = 2; i <= n; i += 1) {
    result *= i;
  }
  return result;
}

function isPrime(number) {
  if (number <= 1 || !Number.isInteger(number)) return false;
  if (number === 2) return true;
  if (number % 2 === 0) return false;

  for (let i = 3; i <= Math.sqrt(number); i += 2) {
    if (number % i === 0) {
      return false;
    }
  }

  return true;
}

function fibonacciSequence(terms) {
  if (terms <= 0 || !Number.isInteger(terms)) return [];
  if (terms === 1) return [0];

  const sequence = [0, 1];

  while (sequence.length < terms) {
    const nextValue = sequence[sequence.length - 1] + sequence[sequence.length - 2];
    sequence.push(nextValue);
  }

  return sequence;
}

// ======================
// Example Test Executions
// ======================

console.log("Reverse:", reverseString("bonjour"));
console.log("Character count:", countCharacters("GoMyCode"));
console.log("Capitalize:", capitalizeWords("hello world from javascript"));

const nums = [5, 12, -3, 8, 0, 21];
console.log("Max:", findMax(nums));
console.log("Min:", findMin(nums));
console.log("Sum:", sumArray(nums));
console.log("Filtered (>= 8):", filterArray(nums, (n) => n >= 8));

console.log("Factorial 5:", factorial(5));
console.log("Is 17 prime?:", isPrime(17));
console.log("Fibonacci (10 terms):", fibonacciSequence(10));
