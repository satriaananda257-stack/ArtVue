import { z } from "zod";

export const POST_CATEGORIES = [
    "OC",
    "Furry",
    "Fanart",
    "Anime & Manga",
    "Digital Art",
    "Traditional Art",
    "Illustration",
] as const;

export const createPostsSchema = z.object({
    title: z.string().min(3, "Title minimal 3 karakter").max(255, "Title maksimal 255 karakter"),
    description: z.string().min(1, "Description tidak boleh kosong"),
    category: z.enum(POST_CATEGORIES).optional(),
});

export const postIdSchema = z.object({
    id: z.coerce.number().int().positive(),
});

export const userIdSchema = z.object({
    userId: z.coerce.number().int().positive(),
});

export const userPostParamsSchema = z.object({
    userId: z.coerce.number().int().positive(),
    postId: z.coerce.number().int().positive(),
});

export const updatePostParamsSchema = z.object({
    id: z.coerce.number().int().positive(),
});

export const updatePostSchema = z.object({
    title: z.string().min(3, "Title minimal 3 karakter").max(255).optional(),
    description: z.string().min(1).optional(),
    category: z.enum(POST_CATEGORIES).optional(),
});
