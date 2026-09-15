import { Response } from "express";
import { AuthRequest } from "../../config/middleware/auth.middleware";
import {
    createPostsSchema,
    postIdSchema,
    updatePostParamsSchema,
    updatePostSchema,
} from "../../validations/post.validation";
import { db } from "../../config/db";
import { postsTable, likesTable, favoritesTable, commentsTable, usersTable, profilesTable } from "../../config/schema";
import { and, desc, eq, sql } from "drizzle-orm";
import { uploadToCloudinary, deleteFromCloudinary } from "../../services/cloudinary.services";

export class PostsController {
    // CREATE POST — userId from JWT
    createPost = async (req: AuthRequest, res: Response) => {
        try {
            const userId = req.user!.id;
            const validatedData = createPostsSchema.parse(req.body);
            const { title, description, category } = validatedData;

            let imageUrl: string | undefined;
            let imagePublicId: string | undefined;

            if (req.file) {
                const uploadResult = await uploadToCloudinary(req.file.buffer);
                imageUrl = uploadResult.secure_url;
                imagePublicId = uploadResult.public_id;
            }

            const [insertedPost] = await db
                .insert(postsTable)
                .values({ userId, title, description, category, imageUrl, imagePublicId })
                .$returningId();

            const newPost = await db.query.postsTable.findFirst({
                where: eq(postsTable.id, insertedPost.id),
            });

            return res.status(201).json({
                success: true,
                message: "Post created successfully",
                data: { post: newPost },
            });
        } catch (error) {
            console.error("Create post error:", error);
            return res.status(500).json({
                success: false,
                message: "Terjadi kesalahan pada server",
                error: error instanceof Error ? error.message : error,
            });
        }
    };

    // GET ALL POSTS
    getPosts = async (req: AuthRequest, res: Response) => {
        try {
            const currentUserId = req.user?.id ?? null;

            const posts = await db
                .select({
                    id: postsTable.id,
                    userId: postsTable.userId,
                    title: postsTable.title,
                    description: postsTable.description,
                    category: postsTable.category,
                    imageUrl: postsTable.imageUrl,
                    status: postsTable.status,
                    createdAt: postsTable.createdAt,
                    updatedAt: postsTable.updatedAt,
                    username: profilesTable.username,
                    email: usersTable.email,
                    likeCount: sql<number>`COUNT(DISTINCT ${likesTable.id})`,
                    commentCount: sql<number>`COUNT(DISTINCT ${commentsTable.id})`,
                })
                .from(postsTable)
                .leftJoin(usersTable, eq(postsTable.userId, usersTable.id))
                .leftJoin(profilesTable, eq(postsTable.userId, profilesTable.userId))
                .leftJoin(likesTable, eq(postsTable.id, likesTable.postId))
                .leftJoin(commentsTable, eq(postsTable.id, commentsTable.postId))
                .where(eq(postsTable.status, "published"))
                .groupBy(postsTable.id, profilesTable.username, usersTable.email)
                .orderBy(desc(postsTable.createdAt));

            let enriched = posts as any[];
            if (currentUserId) {
                const [userLikes, userFavorites] = await Promise.all([
                    db.select({ postId: likesTable.postId }).from(likesTable).where(eq(likesTable.userId, currentUserId)),
                    db.select({ postId: favoritesTable.postId }).from(favoritesTable).where(eq(favoritesTable.userId, currentUserId)),
                ]);
                const likedSet = new Set(userLikes.map(l => l.postId));
                const favSet = new Set(userFavorites.map(f => f.postId));
                enriched = posts.map(p => ({ ...p, isLiked: likedSet.has(p.id), isFavorite: favSet.has(p.id) }));
            } else {
                enriched = posts.map(p => ({ ...p, isLiked: false, isFavorite: false }));
            }

            return res.status(200).json({ success: true, message: "Get Posts Successfully", data: { posts: enriched } });
        } catch (error) {
            console.error("Get posts error:", error);
            return res.status(500).json({ success: false, message: "Terjadi kesalahan pada server", error: error instanceof Error ? error.message : error });
        }
    };

    // GET POST BY ID
    getPostById = async (req: AuthRequest, res: Response) => {
        try {
            const { id } = postIdSchema.parse(req.params);
            const currentUserId = req.user?.id ?? null;

            const [post] = await db
                .select({
                    id: postsTable.id,
                    userId: postsTable.userId,
                    title: postsTable.title,
                    description: postsTable.description,
                    category: postsTable.category,
                    imageUrl: postsTable.imageUrl,
                    status: postsTable.status,
                    createdAt: postsTable.createdAt,
                    updatedAt: postsTable.updatedAt,
                    username: profilesTable.username,
                    likeCount: sql<number>`COUNT(DISTINCT ${likesTable.id})`,
                    commentCount: sql<number>`COUNT(DISTINCT ${commentsTable.id})`,
                })
                .from(postsTable)
                .leftJoin(profilesTable, eq(postsTable.userId, profilesTable.userId))
                .leftJoin(likesTable, eq(postsTable.id, likesTable.postId))
                .leftJoin(commentsTable, eq(postsTable.id, commentsTable.postId))
                .where(and(eq(postsTable.id, id), eq(postsTable.status, "published")))
                .groupBy(postsTable.id, profilesTable.username);

            if (!post) return res.status(404).json({ success: false, message: "Post Not Found" });

            let isLiked = false;
            let isFavorite = false;
            if (currentUserId) {
                const [like, fav] = await Promise.all([
                    db.select().from(likesTable).where(and(eq(likesTable.userId, currentUserId), eq(likesTable.postId, id))),
                    db.select().from(favoritesTable).where(and(eq(favoritesTable.userId, currentUserId), eq(favoritesTable.postId, id))),
                ]);
                isLiked = like.length > 0;
                isFavorite = fav.length > 0;
            }

            return res.status(200).json({ success: true, message: "Post retrieved successfully", data: { post: { ...post, isLiked, isFavorite } } });
        } catch (error) {
            console.error("Get post by id error:", error);
            return res.status(500).json({ success: false, message: "Terjadi kesalahan pada server", error: error instanceof Error ? error.message : error });
        }
    };

    // UPDATE POST — only owner
    updatePost = async (req: AuthRequest, res: Response) => {
        try {
            const { id } = updatePostParamsSchema.parse(req.params);
            const validatedData = updatePostSchema.parse(req.body);
            const currentUserId = req.user!.id;

            const [existingPost] = await db.select().from(postsTable).where(eq(postsTable.id, id));
            if (!existingPost) return res.status(404).json({ success: false, message: "Post not found" });
            if (existingPost.userId !== currentUserId) return res.status(403).json({ success: false, message: "Forbidden: bukan pemilik post" });

            let imageUrl = existingPost.imageUrl;
            let imagePublicId = existingPost.imagePublicId;

            if (req.file) {
                const uploadResult = await uploadToCloudinary(req.file.buffer);
                imageUrl = uploadResult.secure_url;
                imagePublicId = uploadResult.public_id;
                if (existingPost.imagePublicId) await deleteFromCloudinary(existingPost.imagePublicId);
            }

            await db.update(postsTable).set({
                ...(validatedData.title && { title: validatedData.title }),
                ...(validatedData.description && { description: validatedData.description }),
                ...(validatedData.category !== undefined && { category: validatedData.category }),
                ...(req.file && { imageUrl, imagePublicId }),
            }).where(eq(postsTable.id, id));

            const [updatedPost] = await db.select().from(postsTable).where(eq(postsTable.id, id));
            return res.status(200).json({ success: true, message: "Post updated successfully", data: { post: updatedPost } });
        } catch (error) {
            console.error("Update post error:", error);
            return res.status(500).json({ success: false, message: "Terjadi kesalahan pada server", error: error instanceof Error ? error.message : error });
        }
    };

    // DELETE POST — only owner
    deletePost = async (req: AuthRequest, res: Response) => {
        try {
            const { id } = postIdSchema.parse(req.params);
            const currentUserId = req.user!.id;

            const existingPost = await db.query.postsTable.findFirst({ where: eq(postsTable.id, id) });
            if (!existingPost) return res.status(404).json({ success: false, message: "Post not found" });
            if (existingPost.userId !== currentUserId) return res.status(403).json({ success: false, message: "Forbidden: bukan pemilik post" });

            await db.update(postsTable).set({ status: "delete" }).where(eq(postsTable.id, id));
            return res.status(200).json({ success: true, message: "Post deleted successfully" });
        } catch (error) {
            console.error("Delete post error:", error);
            return res.status(500).json({ success: false, message: "Terjadi kesalahan pada server" });
        }
    };

    // LIKE POST
    likePost = async (req: AuthRequest, res: Response) => {
        try {
            const { id: postId } = postIdSchema.parse(req.params);
            const userId = req.user!.id;
            const existing = await db.select().from(likesTable).where(and(eq(likesTable.userId, userId), eq(likesTable.postId, postId)));
            if (existing.length > 0) return res.status(409).json({ success: false, message: "Sudah di-like" });
            await db.insert(likesTable).values({ userId, postId });
            return res.status(201).json({ success: true, message: "Post liked successfully" });
        } catch (error) {
            return res.status(500).json({ success: false, message: "Terjadi kesalahan pada server" });
        }
    };

    // UNLIKE POST
    unlikePost = async (req: AuthRequest, res: Response) => {
        try {
            const { id: postId } = postIdSchema.parse(req.params);
            const userId = req.user!.id;
            await db.delete(likesTable).where(and(eq(likesTable.userId, userId), eq(likesTable.postId, postId)));
            return res.status(200).json({ success: true, message: "Like removed successfully" });
        } catch (error) {
            return res.status(500).json({ success: false, message: "Terjadi kesalahan pada server" });
        }
    };

    // FAVORITE POST
    favoritePost = async (req: AuthRequest, res: Response) => {
        try {
            const { id: postId } = postIdSchema.parse(req.params);
            const userId = req.user!.id;
            const existing = await db.select().from(favoritesTable).where(and(eq(favoritesTable.userId, userId), eq(favoritesTable.postId, postId)));
            if (existing.length > 0) return res.status(409).json({ success: false, message: "Sudah di-favorite" });
            await db.insert(favoritesTable).values({ userId, postId });
            return res.status(201).json({ success: true, message: "Post added to favorites" });
        } catch (error) {
            return res.status(500).json({ success: false, message: "Terjadi kesalahan pada server" });
        }
    };

    // UNFAVORITE POST
    unfavoritePost = async (req: AuthRequest, res: Response) => {
        try {
            const { id: postId } = postIdSchema.parse(req.params);
            const userId = req.user!.id;
            await db.delete(favoritesTable).where(and(eq(favoritesTable.userId, userId), eq(favoritesTable.postId, postId)));
            return res.status(200).json({ success: true, message: "Removed from favorites" });
        } catch (error) {
            return res.status(500).json({ success: false, message: "Terjadi kesalahan pada server" });
        }
    };
}

export default new PostsController();
