import { Response } from "express";
import { AuthRequest } from "../../config/middleware/auth.middleware";
import { updateProfileSchema, userParamSchema } from "../../validations/profile.validation";
import { db } from "../../config/db";
import {
    usersTable, profilesTable, postsTable,
    likesTable, favoritesTable, followsTable,
} from "../../config/schema";
import { and, desc, eq, sql } from "drizzle-orm";

export class UsersController {
    // GET MY PROFILE
    getMyProfile = async (req: AuthRequest, res: Response) => {
        try {
            const userId = req.user!.id;
            return res.json(await this._buildProfile(userId, userId));
        } catch (error) {
            console.error("Get my profile error:", error);
            return res.status(500).json({ success: false, message: "Terjadi kesalahan pada server" });
        }
    };

    // GET USER PROFILE BY ID
    getUserProfile = async (req: AuthRequest, res: Response) => {
        try {
            const { id } = userParamSchema.parse(req.params);
            const currentUserId = req.user?.id ?? null;
            return res.json(await this._buildProfile(id, currentUserId));
        } catch (error) {
            console.error("Get user profile error:", error);
            return res.status(500).json({ success: false, message: "Terjadi kesalahan pada server" });
        }
    };

    // UPDATE MY PROFILE
    updateMyProfile = async (req: AuthRequest, res: Response) => {
        try {
            const userId = req.user!.id;
            const validated = updateProfileSchema.parse(req.body);

            const existing = await db.query.profilesTable.findFirst({
                where: eq(profilesTable.userId, userId),
            });

            if (existing) {
                await db.update(profilesTable).set({
                    ...(validated.username !== undefined && { username: validated.username }),
                    ...(validated.bio !== undefined && { bio: validated.bio }),
                }).where(eq(profilesTable.userId, userId));
            } else {
                await db.insert(profilesTable).values({
                    userId,
                    username: validated.username ?? "user",
                    bio: validated.bio,
                });
            }

            return res.json(await this._buildProfile(userId, userId));
        } catch (error) {
            console.error("Update profile error:", error);
            return res.status(500).json({ success: false, message: "Terjadi kesalahan pada server" });
        }
    };

    // GET MY LIKED POSTS
    getMyLikedPosts = async (req: AuthRequest, res: Response) => {
        try {
            const userId = req.user!.id;

            const posts = await db
                .select({
                    id: postsTable.id,
                    title: postsTable.title,
                    description: postsTable.description,
                    category: postsTable.category,
                    imageUrl: postsTable.imageUrl,
                    createdAt: postsTable.createdAt,
                    username: profilesTable.username,
                })
                .from(likesTable)
                .innerJoin(postsTable, and(eq(likesTable.postId, postsTable.id), eq(postsTable.status, "published")))
                .leftJoin(profilesTable, eq(postsTable.userId, profilesTable.userId))
                .where(eq(likesTable.userId, userId))
                .orderBy(desc(likesTable.createdAt));

            return res.status(200).json({ success: true, message: "Liked posts retrieved", data: { posts } });
        } catch (error) {
            console.error("Get liked posts error:", error);
            return res.status(500).json({ success: false, message: "Terjadi kesalahan pada server" });
        }
    };

    // GET MY FAVORITES
    getMyFavorites = async (req: AuthRequest, res: Response) => {
        try {
            const userId = req.user!.id;

            const posts = await db
                .select({
                    id: postsTable.id,
                    title: postsTable.title,
                    description: postsTable.description,
                    category: postsTable.category,
                    imageUrl: postsTable.imageUrl,
                    createdAt: postsTable.createdAt,
                    username: profilesTable.username,
                })
                .from(favoritesTable)
                .innerJoin(postsTable, and(eq(favoritesTable.postId, postsTable.id), eq(postsTable.status, "published")))
                .leftJoin(profilesTable, eq(postsTable.userId, profilesTable.userId))
                .where(eq(favoritesTable.userId, userId))
                .orderBy(desc(favoritesTable.createdAt));

            return res.status(200).json({ success: true, message: "Favorites retrieved", data: { posts } });
        } catch (error) {
            console.error("Get favorites error:", error);
            return res.status(500).json({ success: false, message: "Terjadi kesalahan pada server" });
        }
    };

    // GET MY POSTS
    getMyPosts = async (req: AuthRequest, res: Response) => {
        try {
            const userId = req.user!.id;

            const posts = await db
                .select({
                    id: postsTable.id,
                    title: postsTable.title,
                    description: postsTable.description,
                    category: postsTable.category,
                    imageUrl: postsTable.imageUrl,
                    createdAt: postsTable.createdAt,
                    username: profilesTable.username,
                })
                .from(postsTable)
                .leftJoin(profilesTable, eq(postsTable.userId, profilesTable.userId))
                .where(and(eq(postsTable.userId, userId), eq(postsTable.status, "published")))
                .orderBy(desc(postsTable.createdAt));

            return res.status(200).json({ success: true, message: "My posts retrieved", data: { posts } });
        } catch (error) {
            console.error("Get my posts error:", error);
            return res.status(500).json({ success: false, message: "Terjadi kesalahan pada server" });
        }
    };

    // FOLLOW USER
    followUser = async (req: AuthRequest, res: Response) => {
        try {
            const { id: followingId } = userParamSchema.parse(req.params);
            const followerId = req.user!.id;

            if (followerId === followingId) {
                return res.status(400).json({ success: false, message: "Tidak bisa follow diri sendiri" });
            }

            const existing = await db.select().from(followsTable)
                .where(and(eq(followsTable.followerId, followerId), eq(followsTable.followingId, followingId)));

            if (existing.length > 0) {
                return res.status(409).json({ success: false, message: "Sudah follow user ini" });
            }

            await db.insert(followsTable).values({ followerId, followingId });

            return res.status(201).json({ success: true, message: "User followed successfully" });
        } catch (error) {
            console.error("Follow user error:", error);
            return res.status(500).json({ success: false, message: "Terjadi kesalahan pada server" });
        }
    };

    // UNFOLLOW USER
    unfollowUser = async (req: AuthRequest, res: Response) => {
        try {
            const { id: followingId } = userParamSchema.parse(req.params);
            const followerId = req.user!.id;

            await db.delete(followsTable)
                .where(and(eq(followsTable.followerId, followerId), eq(followsTable.followingId, followingId)));

            return res.status(200).json({ success: true, message: "User unfollowed successfully" });
        } catch (error) {
            console.error("Unfollow user error:", error);
            return res.status(500).json({ success: false, message: "Terjadi kesalahan pada server" });
        }
    };

    // PRIVATE: build profile
    private _buildProfile = async (userId: number, currentUserId: number | null) => {
        const [user] = await db
            .select({
                id: usersTable.id,
                email: usersTable.email,
                role: usersTable.role,
                createdAt: usersTable.createdAt,
                username: profilesTable.username,
                bio: profilesTable.bio,
                profilePicture: profilesTable.profilePicture,
            })
            .from(usersTable)
            .leftJoin(profilesTable, eq(usersTable.id, profilesTable.userId))
            .where(eq(usersTable.id, userId));

        if (!user) return { success: false, message: "User not found" };

        const [[{ postsCount }], [{ followersCount }], [{ followingCount }]] = await Promise.all([
            db.select({ postsCount: sql<number>`COUNT(*)` }).from(postsTable)
                .where(and(eq(postsTable.userId, userId), eq(postsTable.status, "published"))),
            db.select({ followersCount: sql<number>`COUNT(*)` }).from(followsTable)
                .where(eq(followsTable.followingId, userId)),
            db.select({ followingCount: sql<number>`COUNT(*)` }).from(followsTable)
                .where(eq(followsTable.followerId, userId)),
        ]);

        let isFollowing = false;
        if (currentUserId && currentUserId !== userId) {
            const f = await db.select().from(followsTable)
                .where(and(eq(followsTable.followerId, currentUserId), eq(followsTable.followingId, userId)));
            isFollowing = f.length > 0;
        }

        return {
            success: true,
            message: "Profile retrieved successfully",
            data: {
                profile: {
                    ...user,
                    postsCount,
                    followersCount,
                    followingCount,
                    isFollowing,
                },
            },
        };
    };
}

export default new UsersController();
