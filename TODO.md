# Implementation Plan 📝

This file tracks the progress of the **Ballegram** project. Tasks are broken down into small, PR-sized increments.

## 🟢 Infrastructure & DevOps (Completed)
- [x] **Project Setup**
    - [x] Initialize Ballerina project structure.
    - [x] Create module structure (`common`, `auth`, `chat`, `media`, `social`).
- [x] **CI/CD**
    - [x] Create `Dockerfile` for multi-stage build.
    - [x] Set up GitHub Actions for testing and Docker verification.

## 🟢 Phase 1: Database & Foundation (Completed)
- [x] **Database Schema**
    - [x] Create `docker/init.sql`.
    - [x] Define tables: `users`, `chats`, `messages`, `posts`.
    - [x] Add `docker-compose.yml` for local development (Postgres + Redis).
- [x] **Common Module**
    - [x] Implement DB client wrapper in `common` (currently exists but verify completeness).
    - [x] Implement error types.

## 🟢 Phase 2: Authentication Module (Completed)
- [x] **User Management**
    - [x] Define `User` record/entity.
    - [x] Implement `register` function (password hashing).
- [x] **Security**
    - [x] Implement `login` function (JWT generation).
    - [x] Implement JWT validation middleware.
- [x] **API**
    - [x] Connect `auth` service endpoints to implementation.

## 🟡 Phase 3: Chat Module (In Progress)
- [x] **Chat Core**
    - [x] Define `Chat` and `Message` records.
    - [x] Implement `createChat` DB logic.
    - [x] Implement `saveMessage` DB logic.
    - [x] Implement `getChatHistory`.
- [x] **Real-time**
    - [x] Implement WebSocket listener.
    - [x] Implement connection management (User -> Connection map).
    - [x] Implement message broadcasting.

## 🟣 Phase 4: Social Module (In Progress)
- [x] **Media**
    - [x] Implement file upload handling (S3/Local).
- [x] **Posts**
    - [x] Define `Post` record.
    - [x] Implement `createPost`.
- [x] **Feed**
    - [x] Implement `getFeed` (query logic).

## ⚪ Phase 5: Interaction & Polish
- [ ] **Interactions**
    - [ ] Implement Likes.
    - [ ] Implement Comments.
    - [ ] Implement Follow system.
- [ ] **Search**
    - [ ] Implement User search.
