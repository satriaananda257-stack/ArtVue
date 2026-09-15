# Artvue

Artvue is a mobile-first art community platform built for creators — vtubers, illustrators, and digital artists. It provides a space to share artwork, follow other creators, comment and interact with posts, and discover art across categories.

---

## Tech Stack

### Frontend
| Technology | Version |
|---|---|
| Flutter | SDK ^3.12.2 |
| Dart | ^3.12.2 |
| google_fonts | ^6.2.1 |
| flutter_svg | ^2.0.10 |
| image_picker | ^1.1.2 |
| http | ^1.2.2 |
| shared_preferences | ^2.3.2 |
| hugeicons | ^0.0.7 |

### Backend
| Technology | Version |
|---|---|
| Node.js | — |
| TypeScript | ^6.0.3 |
| Express | ^5.2.1 |
| Drizzle ORM | ^0.45.2 |
| MySQL2 | ^3.24.3 |
| Zod | ^4.5.4 |
| JWT | ^9.0.3 |
| Bcryptjs | ^3.0.3 |
| Cloudinary | ^2.11.0 |
| Multer | ^2.3.0 |

---

## Features

- **Authentication** — Register, login, logout with JWT
- **Post Feed** — Browse posts with search and category filter
- **Post Detail** — View full post with like, save, comment, and follow
- **Create Post** — Upload artwork with title, description, category, and image
- **Edit Post** — Edit post description (owner only)
- **Delete Post** — Delete post with confirmation (owner only)
- **Social** — Follow/unfollow users, like/unlike posts, save/unsave posts
- **Comments** — Add and delete comments on posts
- **Profile** — View and edit username, bio; see posts, saved, and liked tabs

---

## Project Structure

```
Artvue/
├── backend/
│   ├── src/
│   │   ├── config/
│   │   │   ├── db.ts               # Drizzle DB connection
│   │   │   ├── schema.ts           # Database schema (tables)
│   │   │   ├── cloudinary.ts       # Cloudinary config
│   │   │   └── middleware/
│   │   │       ├── auth.middleware.ts
│   │   │       └── upload.middleware.ts
│   │   ├── controllers/
│   │   │   ├── auth/auth.controller.ts
│   │   │   ├── posts/posts.controller.ts
│   │   │   ├── comments/comments.controller.ts
│   │   │   └── users/user.controller.ts
│   │   ├── routes/
│   │   │   ├── auth/auth.route.ts
│   │   │   ├── posts/posts.route.ts
│   │   │   ├── comments/comments.route.ts
│   │   │   └── users/user.route.ts
│   │   ├── validations/
│   │   │   ├── auth.validation.ts
│   │   │   ├── post.validation.ts
│   │   │   ├── comment.validation.ts
│   │   │   └── profile.validation.ts
│   │   ├── services/
│   │   │   └── cloudinary.services.ts
│   │   └── index.ts                # Entry point
│   ├── drizzle.config.ts
│   ├── package.json
│   └── .env
│
└── frontend/
    ├── lib/
    │   ├── main.dart
    │   ├── pages/
    │   │   ├── splashPage.dart
    │   │   ├── loginPage.dart
    │   │   ├── registerPage.dart
    │   │   ├── homePage.dart
    │   │   ├── detailPage.dart
    │   │   ├── accountPage.dart
    │   │   ├── createPostPage.dart
    │   │   ├── editPostPage.dart
    │   │   ├── notifPage.dart
    │   │   ├── messagePage.dart
    │   │   └── commisPage.dart
    │   └── services/
    │       ├── api_config.dart
    │       ├── auth_service.dart
    │       ├── post_service.dart
    │       ├── profile_service.dart
    │       └── storage_service.dart
    ├── assets/
    │   ├── images/
    │   └── icons/
    └── pubspec.yaml
```

---

## Database Schema

| Table | Description |
|---|---|
| `users` | Auth credentials (email, password, role) |
| `profiles` | Display info (username, bio, profilePicture) |
| `posts` | Artwork posts with image, category, status |
| `comments` | Comments on posts |
| `likes` | User likes on posts |
| `favorites` | User saved/bookmarked posts |
| `follows` | Follow relationships between users |

---

## API Endpoints

### Auth — `/api/v1/auth`
| Method | Endpoint | Description |
|---|---|---|
| POST | `/register` | Register new user |
| POST | `/login` | Login and get JWT token |

### Posts — `/api/v1/posts`
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/` | ✅ | Get all published posts |
| GET | `/:id` | ✅ | Get post by ID |
| POST | `/` | ✅ | Create new post |
| PATCH | `/:id` | ✅ | Update post description |
| DELETE | `/:id` | ✅ | Delete post (owner only) |
| POST | `/:id/like` | ✅ | Like a post |
| DELETE | `/:id/like` | ✅ | Unlike a post |
| POST | `/:id/favorite` | ✅ | Save a post |
| DELETE | `/:id/favorite` | ✅ | Unsave a post |

### Comments — `/api/v1/comments`
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/posts/:postId` | — | Get comments by post |
| POST | `/posts/:postId` | ✅ | Add comment |
| DELETE | `/:id` | ✅ | Delete comment (owner only) |

### Users — `/api/v1/users`
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| GET | `/me` | ✅ | Get my profile |
| PATCH | `/me` | ✅ | Update my profile |
| GET | `/me/posts` | ✅ | Get my posts |
| GET | `/me/liked` | ✅ | Get liked posts |
| GET | `/me/favorites` | ✅ | Get saved posts |
| GET | `/:id/profile` | — | Get user profile by ID |
| POST | `/:id/follow` | ✅ | Follow a user |
| DELETE | `/:id/follow` | ✅ | Unfollow a user |

---

## Setup & Running

### Prerequisites
- Node.js >= 18
- MySQL database
- Flutter SDK >= 3.12.2
- Cloudinary account

### Backend

```bash
cd backend
npm install
```

Create `.env` file:
```env
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=your_db_user
DB_PASSWORD=your_db_password
DB_NAME=your_db_name

JWT_SECRET=your_jwt_secret

CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

Push schema to database:
```bash
npx drizzle-kit push
```

Start development server:
```bash
npm run dev
```

Backend runs on `http://localhost:3000`

---

### Frontend

```bash
cd frontend
flutter pub get
```

Update `lib/services/api_config.dart` based on your environment:
```dart
// Android Emulator
static String get baseUrl => 'http://10.0.2.2:3000/api/v1';

// Physical Device (same WiFi)
static String get baseUrl => 'http://YOUR_PC_IP:3000/api/v1';

// Chrome/Web
static String get baseUrl => 'http://localhost:3000/api/v1';
```

Run the app:
```bash
flutter run
```

---

## Environment Notes

- Images are uploaded to **Cloudinary** — configure credentials in `.env`
- JWT tokens expire in **7 days**
- Post status uses soft delete (`status: "delete"`) instead of hard delete
- Profile picture upload is handled via Cloudinary (multipart form)
