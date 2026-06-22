# Simulating a Print Queue

This is a module/checkpoint folder.
It stores files used for this part of the repository.

## Overview
A JavaScript simulation of a shared office printer driven by a FIFO queue.
A generic `Queue` class supports `enqueue`, `dequeue`, `peek`, `isEmpty`,
`size`, and `toArray`. A `PrinterQueue` wrapper adds the domain methods
`addJob`, `processJob`, `processAll`, and `printQueue`. The test
scenario submits five jobs, processes two, slips a sixth job in
mid-queue, then drains the rest — followed by lightweight `console.assert`
checks that prove the Queue contract.

## Contents
- printerQueue.js — runnable JavaScript implementation, demo scenario, self-checks.
- projet.md — full description, class walkthrough, sample output.

## How to Run
```bash
node printerQueue.js
```

## Notes
Keep this folder aligned with project naming and structure rules.
