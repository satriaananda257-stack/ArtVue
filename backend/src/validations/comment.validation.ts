import { z } from "zod";

export const createCommentSchema = z.object({
    comment: z.string().min(1, "Comment tidak boleh kosong"),
});

export const commentParamsSchema = z.object({
    id: z.coerce.number().int().positive(),
});

export const postIdParamsSchema = z.object({
    postId: z.coerce.number().int().positive(),
});

export const updateCommentSchema = z.object({
    comment: z.string().min(1, "Comment tidak boleh kosong"),
});
