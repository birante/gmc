# VisuAlgo — Checkpoint Self-Assessment

**Profil :** Développeur Full-Stack — Angular (Frontend) · Ruby on Rails (Backend)  
**Source :** [https://visualgo.net/en](https://visualgo.net/en)  
**Date :** April 2026

---

## Objective

Explore the interactive visualizations on VisuAlgo for each data structure and sorting algorithm, identify which ones are not yet mastered, and explain why.

---

## Data Structures & Algorithms I Am Familiar With

| Topic | Category | Reason |
|---|---|---|
| Array | Data Structure | Used daily in Angular (lists, loops, pipes) and Ruby (`.map`, `.select`, `.each`) |
| Linked List (Stack / Queue) | Data Structure | Understood conceptually; used implicitly in Rails callbacks and middleware chains |
| Hash Table | Data Structure | Core of Ruby — hashes are everywhere in Rails (params, options, configs) |
| Bubble Sort | Sorting | Covered in academic fundamentals |
| Selection Sort | Sorting | Covered in academic fundamentals |
| Insertion Sort | Sorting | Covered in academic fundamentals |

---

## Data Structures & Algorithms I Have Not Yet Mastered

### Data Structures

#### 1. Binary Heap (Priority Queue)
> **Why not mastered:** I have never needed a priority queue in web development. The concept of a complete binary tree stored as an array, with heapify-up and heapify-down operations, is not intuitive to me yet without more practice.

#### 2. Binary Search Tree (BST) + AVL Tree
> **Why not mastered:** I understand the basic idea of BST insertion and search, but self-balancing (AVL rotations — left, right, left-right, right-left) is still unclear to me. The recursive logic behind rebalancing is hard to visualize mentally.

#### 3. Graph Structures (Adjacency List / Matrix)
> **Why not mastered:** Rails and Angular work with flat data (JSON, REST). I have rarely had to model data as a graph. The difference between directed/undirected and weighted/unweighted graphs is clear, but I need practice building and traversing them in code.

#### 4. Union-Find (Disjoint Set)
> **Why not mastered:** This data structure is completely new to me. Path compression and union by rank are concepts I have only read about once without practicing.

#### 5. Fenwick Tree (Binary Indexed Tree)
> **Why not mastered:** I had never heard of this before VisuAlgo. The idea of using bit manipulation to answer range sum queries efficiently is very abstract to me and requires significant dedicated study.

#### 6. Segment Tree
> **Why not mastered:** Similar to Fenwick Tree — the concept of lazy propagation and range queries on a tree is advanced and outside my current comfort zone. I need to practice recursive tree construction first.

#### 7. Suffix Tree
> **Why not mastered:** String algorithms are rarely needed in web development. The construction of a suffix tree (especially Ukkonen's algorithm) is one of the most complex topics on VisuAlgo and I have no experience with it.

#### 8. Suffix Array + LCP
> **Why not mastered:** Related to suffix trees, this requires understanding of string comparison and lexicographic sorting. I lack both the theory and the practice for this topic.

---

### 🔷 Sorting Algorithms

#### 9. Merge Sort
> **Why not mastered:** I know the divide-and-conquer concept at a high level, but implementing it correctly — especially the merge step — is still something I struggle to do from memory without referencing material.

#### 10. Quick Sort
> **Why not mastered:** The pivot selection strategy and partition logic are clear conceptually, but the in-place partitioning and worst-case analysis (O(n²)) are things I need more practice to fully internalize.

#### 11. Counting Sort
> **Why not mastered:** I understand it works on integers within a range, but implementing the cumulative count step and writing it correctly end-to-end is not yet automatic for me.

#### 12. Radix Sort
> **Why not mastered:** I understand it sorts digit by digit using a stable sub-sort, but I have never implemented it and the relationship between radix, base, and passes is not yet clear in my mind.

---

### Graph Algorithms

#### 13. DFS / BFS (Graph Traversal)
> **Why not mastered:** I understand the high-level idea (stack vs queue, visited set), but implementing iterative DFS or detecting SCC (Strongly Connected Components) and articulation points is beyond my current skill level.

#### 14. Minimum Spanning Tree (Prim's & Kruskal's)
> **Why not mastered:** Both algorithms are new to me. Kruskal's makes intuitive sense with Union-Find, but since I haven't mastered Union-Find yet, this is also blocked.

#### 15. Single-Source Shortest Path — Dijkstra
> **Why not mastered:** I understand the greedy approach conceptually but have never implemented it with a priority queue. The update logic (relaxation) needs more practice.

#### 16. Single-Source Shortest Path — Bellman-Ford
> **Why not mastered:** The concept of relaxing all edges V-1 times is clear, but detecting negative weight cycles and understanding when to use it over Dijkstra needs reinforcement.

#### 17. Cycle Finding (Floyd's Tortoise & Hare)
> **Why not mastered:** I know the algorithm exists and the metaphor, but proving why the two pointers meet at the cycle entrance requires mathematical reasoning I haven't worked through yet.

#### 18. Network Flow (Ford-Fulkerson, Dinic's)
> **Why not mastered:** Max flow / min cut problems are a completely new category for me. The concept of residual graphs and augmenting paths requires dedicated study and is rarely encountered in web development.

#### 19. Graph Matching (Bipartite Augmenting Path)
> **Why not mastered:** Bipartite matching is something I have seen referenced in job interview prep but never studied in depth. The augmenting path algorithm is not intuitive without first mastering BFS/DFS well.

#### 20. Min Vertex Cover
> **Why not mastered:** This is an NP-hard problem and I have no background in approximation algorithms or NP complexity theory beyond the definition.

---

### Advanced / Competitive Topics

#### 21. Bitmask
> **Why not mastered:** I rarely use bitwise operators in Angular or Rails. Representing subsets as integers and performing bit operations to solve combinatorial problems is a mental model I need to build from scratch.

#### 22. Recursion / DAG Visualization
> **Why not mastered:** I can write simple recursive functions, but visualizing overlapping subproblems and understanding when to apply dynamic programming (memoization vs tabulation) is still unclear.

#### 23. Computational Geometry (Polygon)
> **Why not mastered:** I have never needed convex/concave polygon algorithms, winding numbers, or polygon clipping in my professional work. This is an entirely new domain.

#### 24. Convex Hull (Graham Scan, Jarvis March)
> **Why not mastered:** Same as above — computational geometry is outside my domain. The algorithms are conceptually interesting on VisuAlgo but require significant mathematical background.

#### 25. Steiner Tree
> **Why not mastered:** NP-hard problem, completely outside my current knowledge. I do not yet have the foundations (MST, graph theory) to approach this topic.

#### 26. Traveling Salesperson Problem (TSP)
> **Why not mastered:** I know what TSP is conceptually but the DP-based exact solution (bitmask DP) combines two areas I haven't mastered yet: bitmask and dynamic programming.

#### 27. NP-complete Reductions
> **Why not mastered:** My background in theoretical computer science and complexity theory (P vs NP, reductions) is very limited. I need to study these foundations before tackling this module.

---

## Summary

| | Count |
|---|---|
| Topics mastered | 6 |
| Topics to master | 21 |
| Total topics on VisuAlgo | 27 |

**Root causes for gaps:**

- My professional context (Angular + Rails) focuses on CRUD operations, REST APIs, and UI logic — not algorithm-heavy problems.
- I have solid practical skills but limited exposure to computer science theory (trees, graphs, complexity).
- Recursive thinking and pointer-based data structures require deliberate practice that I haven't done systematically yet.
- Topics like Fenwick Tree, Suffix structures, and Network Flow are entirely new and will require starting from first principles.

---
