# Implementation Plan 📝

This file tracks the progress of the **Ballegram** project. Tasks are sorted by priority.

## 🟢 Phase 0: Initialization & Infrastructure

- [ ] **Project Setup**
    - [ ] Initialize Ballerina project: `bal new ballegram`
    - [ ] Create directory structure (`modules/`, `service/`, `docker/`).
- [ ] **Database Setup**
    - [ ] Create `docker-compose.yml` with PostgreSQL and Redis.
    - [ ] Create `docker/init.sql` with the initial schema (Users, Chats, Messages, Posts).
    - [ ] Verify DB connection from Ballerina using `ballerinax/postgresql`.

## 🟡 Phase 1: Foundation (Auth & Users)

- [ ] **Module: Common**
    - [ ] Define shared error types (`NotFoundError`, `UnauthorizedError`).
    - [ ] Create DB client wrapper.
- [ ] **Module: Auth**
    - [ ] Implement `Register` (create user, hash password).
    - [ ] Implement `Login` (verify password, issue JWT).
    - [ ] Implement JWT validation middleware/interceptor.
- [ ] **Module: User**
    - [ ] `GET /users/me` (get own profile).
    - [ ] `PUT /users/me` (update bio/avatar).
    - [ ] `GET /users/{id}` (get other profile).

## 🟠 Phase 2: Core Messaging (The "Telegram" Part)

- [ ] **Module: Chat (Data Layer)**
    - [ ] `createChat(user_id_1, user_id_2)` -> UUID.
    - [ ] `saveMessage(chat_id, sender_id, content)` -> MessageID.
    - [ ] `getChatHistory(chat_id, limit, offset)`.
- [ ] **Service: WebSocket Chat**
    - [ ] Initialize `websocket:Listener`.
    - [ ] Manage active connections map (User ID -> WebSocket Caller).
    - [ ] Implement `onMessage`: save to DB -> lookup recipient -> send payload.
    - [ ] Handle offline recipients (queueing or simple "missed" logic).

## 🔵 Phase 3: Social Feed (The "Instagram" Part)

- [ ] **Module: Media**
    - [ ] Setup S3 client (`ballerinax/aws.s3`) or local file simulation.
    - [ ] `POST /media/upload` -> returns URL.
- [ ] **Module: Social (Posts)**
    - [ ] `createPost(user_id, caption, photo_urls)`.
    - [ ] `getFeed(user_id)`:
        - *Logic:* Query posts from users followed by `user_id`.
        - *Sort:* Reverse chronological order.

## 🟣 Phase 4: Interactions

- [ ] **Likes & Comments**
    - [ ] `POST /posts/{id}/like`.
    - [ ] `POST /posts/{id}/comment`.
    - [ ] Add `like_count` and `comment_count` to Post DTOs.
- [ ] **Follow System**
    - [ ] `POST /users/{id}/follow`.
    - [ ] `DELETE /users/{id}/follow`.
    - [ ] Update Feed logic to respect follows.

## ⚪ Phase 5: Advanced Features

- [ ] **Group Chats**
    - [ ] Update WebSocket logic to fan-out messages to multiple recipients.
    - [ ] Add `createGroup`, `addMember`, `removeMember` endpoints.
- [ ] **Search**
    - [ ] Simple SQL `ILIKE` search for usernames.
- [ ] **Push Notifications**
    - [ ] Integration with Firebase (FCM).

---

## 🧪 Testing Strategy (No Client)

Since we do not have a frontend, verification is critical.

### 1. Unit Testing
Run `bal test` to execute tests within modules.
- **Auth:** Mock DB, test password hashing vectors.
- **Social:** Test feed algorithm logic (sorting, filtering).

### 2. Integration Testing
Create a `tests/integration_test.bal` that performs a full flow:
1.  **Register** User A and User B.
2.  **Login** to get JWTs.
3.  **User A posts** an image.
4.  **User B follows** User A.
5.  **User B checks feed** -> Expects User A's post.
6.  **User A messages** User B (requires WS client simulation).

### 3. Manual API Verification
Create a `requests.http` or `curl_commands.sh` file in the root.
```bash
# Example: Register
curl -X POST http://localhost:9090/auth/register -d '{"username": "alice", "password": "123"}'
```
