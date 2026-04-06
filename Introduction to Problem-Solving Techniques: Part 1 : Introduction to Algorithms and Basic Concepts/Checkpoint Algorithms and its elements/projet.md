# Checkpoint: Algorithm and Its Elements

## Objective
Write an algorithm that reads a sentence character by character (the sentence ends with a point `.`), then determines:

1. The length of the sentence (number of characters).
2. The number of words (words are separated by a single space).
3. The number of vowels.

## Idea
Use three counters:

- `lengthCounter` for the number of characters.
- `wordCounter` for the number of words.
- `vowelCounter` for the number of vowels.

Since the sentence ends with `.` and words are separated by one space:

- Count every read character (including spaces and the final point) in `lengthCounter`.
- Count spaces to detect words, then add 1 at the end if the sentence is not empty.
- Count vowels (`a, e, i, o, u, y` in lowercase and uppercase).

## Algorithm (pseudocode)

```text
Algorithm SentenceStats
Variables:
	c: character
	lengthCounter, wordCounter, vowelCounter: integer

Begin
	lengthCounter <- 0
	wordCounter <- 0
	vowelCounter <- 0

	Read(c)

	While c <> '.' do
		lengthCounter <- lengthCounter + 1

		If c = ' ' then
			wordCounter <- wordCounter + 1
		EndIf

		If c in ['a','e','i','o','u','y','A','E','I','O','U','Y'] then
			vowelCounter <- vowelCounter + 1
		EndIf

		Read(c)
	EndWhile

	// Count the final point as a character
	lengthCounter <- lengthCounter + 1

	// If sentence contains at least one character before '.', number of words = spaces + 1
	If lengthCounter > 1 then
		wordCounter <- wordCounter + 1
	EndIf

	Write("Length: ", lengthCounter)
	Write("Words: ", wordCounter)
	Write("Vowels: ", vowelCounter)
End
```

## Example
Sentence: `I love algorithms.`

- Length = 18
- Words = 3
- Vowels = 6
