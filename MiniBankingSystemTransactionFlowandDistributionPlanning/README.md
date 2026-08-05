# Mini Banking System — Transaction Flow and Distribution Planning

Two-part analysis:

| Part | Topic                                    | Key result |
| ---- | ---------------------------------------- | ---------- |
| 1    | Transaction management (concurrency)     | Lost-update on shared-account transfers; row-level 2PL exclusive locks; pessimistic locking chosen. |
| 2    | Distributed database planning            | Horizontal fragmentation of `Customers` by `branch`; vertical split of login credentials; static allocation for transaction history. |

Full analysis in **[`analysis.md`](./analysis.md)**.
