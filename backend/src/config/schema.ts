import { mysqlTable, mysqlEnum, int, varchar, text, timestamp, uniqueIndex } from "drizzle-orm/mysql-core";

export const USER_ROLES = ["user", "admin"] as const;
export const POST_CATEGORIES = [
    "OC",
    "Furry",
    "Fanart",
    "Anime & Manga",
    "Digital Art",
    "Traditional Art",
    "Illustration",
] as const;

export const POST_STATUS = ["delete", "published"] as const;

// ─── USERS ────────────────────────────────────────────────────
// email sebagai identifier login, tidak ada username di sini
export const usersTable = mysqlTable("users", {
    id: int("id").autoincrement().primaryKey(),
    email: varchar("email", { length: 100 }).notNull().unique(),
    password: varchar("password", { length: 255 }).notNull(),
    role: mysqlEnum("role", USER_ROLES).notNull().default("user"),
    createdAt: timestamp("created_at").defaultNow(),
    updatedAt: timestamp("updated_at").defaultNow().onUpdateNow(),
});

// ─── PROFILES ─────────────────────────────────────────────────
// username = nama tampilan yang bisa diubah user
export const profilesTable = mysqlTable("profiles", {
    id: int("id").autoincrement().primaryKey(),
    userId: int("user_id").notNull().unique().references(() => usersTable.id, { onDelete: "cascade" }),
    username: varchar("username", { length: 100 }).notNull(),
    bio: text("bio"),
    profilePicture: text("profile_picture"),
    createdAt: timestamp("created_at").defaultNow(),
    updatedAt: timestamp("updated_at").defaultNow().onUpdateNow(),
});

// ─── POSTS ────────────────────────────────────────────────────
export const postsTable = mysqlTable("posts", {
    id: int("id").autoincrement().primaryKey(),
    userId: int("user_id").notNull().references(() => usersTable.id, { onDelete: "cascade" }),
    title: varchar("title", { length: 255 }).notNull(),
    description: text("description").notNull(),
    category: mysqlEnum("category", POST_CATEGORIES),
    imageUrl: text("image_url"),
    imagePublicId: varchar("image_public_id", { length: 255 }),
    status: mysqlEnum("status", POST_STATUS).notNull().default("published"),
    createdAt: timestamp("created_at").defaultNow(),
    updatedAt: timestamp("updated_at").defaultNow().onUpdateNow(),
});

// ─── COMMENTS ─────────────────────────────────────────────────
export const commentsTable = mysqlTable("comments", {
    id: int("id").autoincrement().primaryKey(),
    postId: int("post_id").notNull().references(() => postsTable.id, { onDelete: "cascade" }),
    userId: int("user_id").notNull().references(() => usersTable.id, { onDelete: "cascade" }),
    comment: text("comment").notNull(),
    createdAt: timestamp("created_at").defaultNow(),
    updatedAt: timestamp("updated_at").defaultNow().onUpdateNow(),
});

// ─── LIKES ────────────────────────────────────────────────────
export const likesTable = mysqlTable("likes", {
    id: int("id").autoincrement().primaryKey(),
    userId: int("user_id").notNull().references(() => usersTable.id, { onDelete: "cascade" }),
    postId: int("post_id").notNull().references(() => postsTable.id, { onDelete: "cascade" }),
    createdAt: timestamp("created_at").defaultNow(),
}, (table) => ({
    uniqueLike: uniqueIndex("unique_like").on(table.userId, table.postId),
}));

// ─── FAVORITES ────────────────────────────────────────────────
export const favoritesTable = mysqlTable("favorites", {
    id: int("id").autoincrement().primaryKey(),
    userId: int("user_id").notNull().references(() => usersTable.id, { onDelete: "cascade" }),
    postId: int("post_id").notNull().references(() => postsTable.id, { onDelete: "cascade" }),
    createdAt: timestamp("created_at").defaultNow(),
}, (table) => ({
    uniqueFavorite: uniqueIndex("unique_favorite").on(table.userId, table.postId),
}));

// ─── FOLLOWS ──────────────────────────────────────────────────
export const followsTable = mysqlTable("follows", {
    id: int("id").autoincrement().primaryKey(),
    followerId: int("follower_id").notNull().references(() => usersTable.id, { onDelete: "cascade" }),
    followingId: int("following_id").notNull().references(() => usersTable.id, { onDelete: "cascade" }),
    createdAt: timestamp("created_at").defaultNow(),
}, (table) => ({
    uniqueFollow: uniqueIndex("unique_follow").on(table.followerId, table.followingId),
}));
