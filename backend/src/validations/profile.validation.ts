import { z } from "zod";

export const updateProfileSchema = z.object({
    username: z.string().min(3, "Username minimal 3 karakter").max(100).optional(),
    bio: z.string().max(500).optional(),
});

export const userParamSchema = z.object({
    id: z.coerce.number().int().positive(),
});
