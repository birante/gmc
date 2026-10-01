What You're Aiming For
Objective

The objective of this exercise is for students to practice designing NoSQL databases while considering multiple requirement views, such as scalability, consistency, availability, and specific use case queries. Through hands-on exercises, students will explore how different data models in NoSQL (e.g., document, key-value, wide-column, and graph) can be applied to fit various real-world scenarios.

You will first design a database schema based on a set of requirements and then adapt the schema to meet new requirements, such as handling high-velocity data or supporting analytical queries.

Part 1: Initial Design Based on Requirements

Implement a NoSQL database design for an e-commerce application with the following requirements:

Users should be able to browse and search for products.
Orders must be stored and include details such as customer information, items purchased, and delivery status.
The system must support thousands of transactions per second.
Use the following steps to guide your design process:

Identify key entities (e.g., users, products, orders).
Choose an appropriate NoSQL model (e.g., document-based, key-value) to store the data.
Define relationships and indexes based on the query patterns.
Consider scalability and consistency requirements when defining your schema.
Example Behavior:

The product catalog is frequently queried, so the design should support fast lookups and full-text search capabilities.
The order data should be designed to handle high write throughput and ensure consistency in customer order status.
Part 2: Refactor Based on New Requirements

Now, adapt your database schema to meet the following new requirements:

Analytics Requirement: The company now needs to run large-scale analytical queries to understand product trends and sales data.
High Availability: The application must guarantee high availability and partition tolerance due to the increase in users.
Select a design strategy to refactor the NoSQL database schema, such as:

Sharding: Distribute data across multiple nodes to handle large volumes of requests and data.
Replication: Ensure data is replicated across multiple nodes to enhance availability and fault tolerance.
Denormalization: Adapt the schema to include pre-aggregated data for fast analytics queries.
Refactor your initial design based on the new requirements while considering the trade-offs between consistency, availability, and performance.


Instructions
Deliverables

Submit a GitHub link with:

Initial Schema Design: Submit the initial NoSQL database schema based on the original requirements.
Refactored Schema: Submit the refactored NoSQL database schema to meet the new requirements.
Short Reflection Report (200–300 words):
What challenges did you face during the schema refactor?
How did the new requirements affect your design decisions?
How did the refactor improve the system in terms of scalability, availability, and query performance?
