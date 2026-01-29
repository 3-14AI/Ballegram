# Implementation Plan 📝

This file tracks the progress of the **Ballegram** project. Tasks are broken down into small, PR-sized increments.

## 🟢 Infrastructure & DevOps (Completed)
- [x] **Project Setup**
    - [x] Initialize Ballerina project structure.
    - [x] Create module structure (`common`, `auth`, `chat`, `media`, `social`).
- [x] **CI/CD**
    - [x] Create `Dockerfile` for multi-stage build.
    - [x] Set up GitHub Actions for testing and Docker verification.

## 🟡 Phase 1: Database & Foundation (Next Up)
- [ ] **Database Schema**
    - [ ] Create `docker/init.sql`.
    - [ ] Define tables: `users`, `chats`, `messages`, `posts`.
    - [ ] Add `docker-compose.yml` for local development (Postgres + Redis).
- [ ] **Common Module**
    - [ ] Implement DB client wrapper in `common` (currently exists but verify completeness).
    - [ ] Implement error types.

## 🟠 Phase 2: Authentication Module
- [ ] **User Management**
    - [ ] Define `User` record/entity.
    - [ ] Implement `register` function (password hashing).
- [ ] **Security**
    - [ ] Implement `login` function (JWT generation).
    - [ ] Implement JWT validation middleware.
- [ ] **API**
    - [ ] Connect `auth` service endpoints to implementation.

## 🔵 Phase 3: Chat Module
- [ ] **Chat Core**
    - [ ] Define `Chat` and `Message` records.
    - [ ] Implement `createChat` DB logic.
    - [ ] Implement `saveMessage` DB logic.
    - [ ] Implement `getChatHistory`.
- [ ] **Real-time**
    - [ ] Implement WebSocket listener.
    - [ ] Implement connection management (User -> Connection map).
    - [ ] Implement message broadcasting.

## 🟣 Phase 4: Social Module
- [ ] **Media**
    - [ ] Implement file upload handling (S3/Local).
- [ ] **Posts**
    - [ ] Define `Post` record.
    - [ ] Implement `createPost`.
- [ ] **Feed**
    - [ ] Implement `getFeed` (query logic).

## ⚪ Phase 5: Interaction & Polish
- [ ] **Interactions**
    - [ ] Implement Likes.
    - [ ] Implement Comments.
    - [ ] Implement Follow system.
- [ ] **Search**
    - [ ] Implement User search.
