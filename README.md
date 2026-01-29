# Ballegram 📱📸

**Ballegram** is an ambitious project to create a hybrid social platform that merges the speed and privacy of a messenger (like Telegram) with the visual engagement of a social network (like Instagram). The entire backend is engineered using **Ballerina**, taking advantage of its cloud-native capabilities and concurrent network handling.

## 🚀 Vision

*   **Core:** A lightweight, real-time messenger.
*   **Social:** A public feed for sharing photos/stories.
*   **Goal:** High performance, type safety, and seamless network integration provided by Ballerina.

## 🛠 Tech Stack

*   **Language:** [Ballerina](https://ballerina.io/) (Swan Lake)
*   **Database:** PostgreSQL (Primary Relational Data)
*   **Caching & Pub/Sub:** Redis (Session management, WebSocket distribution)
*   **Object Storage:** S3 / MinIO (Images, Videos)
*   **Containerization:** Docker & Kubernetes

## 📂 Project Structure

We follow a **Modular Monolith** architecture. This allows us to keep domains separated while deploying a single binary (initially).

```text
ballegram/
├── Ballerina.toml          # Project configuration
├── Config.toml             # Environment variables
├── modules/                # Domain-specific logic
│   ├── auth/               # User registration, JWT issuance
│   ├── chat/               # Messaging logic, WebSocket handling
│   ├── social/             # Feed, Posts, Interactions
│   ├── media/              # S3 upload/download handling
│   └── common/             # Shared types, errors, DB client
├── service/                # Entry points (HTTP/GraphQL/WebSocket listeners)
│   ├── api_service.bal     # Main HTTP API
│   └── chat_service.bal    # WebSocket Listener
├── tests/                  # Integration tests
└── docker/                 # Infrastructure setup (Postgres, Redis)
```

## 💾 Database Schema (PostgreSQL)

The database is designed to support both high-throughput messaging and relational social data.

### Users & Auth
*   **`users`**
    *   `id` (UUID, PK)
    *   `username` (VARCHAR, Unique)
    *   `email` (VARCHAR, Unique)
    *   `password_hash` (VARCHAR)
    *   `avatar_url` (VARCHAR, Nullable)
    *   `bio` (TEXT, Nullable)
    *   `created_at` (TIMESTAMP)

*   **`follows`**
    *   `follower_id` (UUID, FK -> users.id)
    *   `following_id` (UUID, FK -> users.id)
    *   *PK: (follower_id, following_id)*

### Messaging (Telegram-like)
*   **`chats`**
    *   `id` (UUID, PK)
    *   `type` (ENUM: 'DIRECT', 'GROUP')
    *   `created_at` (TIMESTAMP)
    *   `updated_at` (TIMESTAMP) -- used for sorting chat list

*   **`chat_participants`**
    *   `chat_id` (UUID, FK -> chats.id)
    *   `user_id` (UUID, FK -> users.id)
    *   `role` (ENUM: 'ADMIN', 'MEMBER')
    *   *PK: (chat_id, user_id)*

*   **`messages`**
    *   `id` (BIGSERIAL or TSID, PK)
    *   `chat_id` (UUID, FK -> chats.id)
    *   `sender_id` (UUID, FK -> users.id)
    *   `content` (TEXT)
    *   `media_url` (VARCHAR, Nullable)
    *   `created_at` (TIMESTAMP)
    *   `is_read` (BOOLEAN)

### Social Feed (Instagram-like)
*   **`posts`**
    *   `id` (UUID, PK)
    *   `user_id` (UUID, FK -> users.id)
    *   `caption` (TEXT)
    *   `media_urls` (JSONB) -- Array of image URLs
    *   `created_at` (TIMESTAMP)

*   **`likes`**
    *   `post_id` (UUID, FK -> posts.id)
    *   `user_id` (UUID, FK -> users.id)
    *   *PK: (post_id, user_id)*

*   **`comments`**
    *   `id` (UUID, PK)
    *   `post_id` (UUID, FK -> posts.id)
    *   `user_id` (UUID, FK -> users.id)
    *   `content` (TEXT)
    *   `created_at` (TIMESTAMP)

## 🧪 Testing Strategy (No Client)

Since the frontend is not yet developed, we verify the backend using **contract-driven testing**:

1.  **Unit Tests:** Inside each Ballerina module.
2.  **Integration Tests:** Using Ballerina's test suite to spin up services and hit endpoints.
3.  **API Simulation:**
    *   **HTTP**: `curl` scripts or Postman/Bruno collections.
    *   **WebSockets**: Using `wscat` or a simple Ballerina WebSocket client script to simulate chat traffic.

## 🚀 Getting Started

1.  Start infrastructure: `docker-compose up -d`
2.  Run migration: `bal run modules/db_migration`
3.  Start server: `bal run`
