import { Response } from "express";
import { AuthRequest } from "../../config/middleware/auth.middleware";
import {
    createCommentSchema,
    commentParamsSchema,
    postIdParamsSchema,
} from "../../validations/comment.validation";
import { db } from "../../config/db";
import { commentsTable, profilesTable } from "../../config/schema";
import { desc, eq } from "drizzle-orm";

export class CommentsController {
    // CREATE COMMENT — userId from JWT
    createComment = async (req: AuthRequest, res: Response) => {
        try {
            const userId = req.user!.id;
            const { postId } = postIdParamsSchema.parse(req.params);
            const { comment } = createCommentSchema.parse(req.body);

            const [inserted] = await db
                .insert(commentsTable)
                .values({ postId, userId, comment })
                .$returningId();

            const newComment = await db
                .select({
                    id: commentsTable.id,
                    postId: commentsTable.postId,
                    userId: commentsTable.userId,
                    comment: commentsTable.comment,
                    createdAt: commentsTable.createdAt,
                    username: profilesTable.username,
                })
                .from(commentsTable)
                .leftJoin(profilesTable, eq(commentsTable.userId, profilesTable.userId))
                .where(eq(commentsTable.id, inserted.id));

            return res.status(201).json({
                success: true,
                message: "Comment created successfully",
                data: { comment: newComment[0] },
            });
        } catch (error) {
            console.error("Create comment error:", error);
            return res.status(500).json({
                success: false,
                message: "Terjadi kesalahan pada server",
                error: error instanceof Error ? error.message : error,
            });
        }
    };

    // GET COMMENTS BY POST ID
    getCommentsByPostId = async (req: AuthRequest, res: Response) => {
        try {
            const { postId } = postIdParamsSchema.parse(req.params);

            const comments = await db
                .select({
                    id: commentsTable.id,
                    postId: commentsTable.postId,
                    userId: commentsTable.userId,
                    comment: commentsTable.comment,
                    createdAt: commentsTable.createdAt,
                    username: profilesTable.username,
                })
                .from(commentsTable)
                .leftJoin(profilesTable, eq(commentsTable.userId, profilesTable.userId))
                .where(eq(commentsTable.postId, postId))
                .orderBy(desc(commentsTable.createdAt));

            return res.status(200).json({
                success: true,
                message: "Comments retrieved successfully",
                data: { comments },
            });
        } catch (error) {
            console.error("Get comments error:", error);
            return res.status(500).json({
                success: false,
                message: "Terjadi kesalahan pada server",
                error: error instanceof Error ? error.message : error,
            });
        }
    };

    // DELETE COMMENT — only owner
    deleteComment = async (req: AuthRequest, res: Response) => {
        try {
            const { id } = commentParamsSchema.parse(req.params);
            const currentUserId = req.user!.id;

            const existing = await db.query.commentsTable.findFirst({
                where: eq(commentsTable.id, id),
            });

            if (!existing) {
                return res.status(404).json({ success: false, message: "Comment not found" });
            }
            if (existing.userId !== currentUserId) {
                return res.status(403).json({ success: false, message: "Forbidden: bukan pemilik komentar" });
            }

            await db.delete(commentsTable).where(eq(commentsTable.id, id));

            return res.status(200).json({ success: true, message: "Comment deleted successfully" });
        } catch (error) {
            console.error("Delete comment error:", error);
            return res.status(500).json({
                success: false,
                message: "Terjadi kesalahan pada server",
                error: error instanceof Error ? error.message : error,
            });
        }
    };
}

export default new CommentsController();
