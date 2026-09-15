import { Router } from "express";
import postsController from "../../controllers/posts/posts.controller";
import { authenticate } from "../../config/middleware/auth.middleware";
import { uploadSingleImage } from "../../config/middleware/upload.middleware";

const router = Router();

// GET all posts (public, optional auth for is_liked/is_favorite)
router.get("/", authenticate, postsController.getPosts);

// GET post by id
router.get("/:id", authenticate, postsController.getPostById);

// CREATE post
router.post("/", authenticate, uploadSingleImage, postsController.createPost);

// UPDATE post (owner only)
router.patch("/:id", authenticate, uploadSingleImage, postsController.updatePost);

// DELETE post (owner only)
router.delete("/:id", authenticate, postsController.deletePost);

// LIKE / UNLIKE
router.post("/:id/like", authenticate, postsController.likePost);
router.delete("/:id/like", authenticate, postsController.unlikePost);

// FAVORITE / UNFAVORITE
router.post("/:id/favorite", authenticate, postsController.favoritePost);
router.delete("/:id/favorite", authenticate, postsController.unfavoritePost);

export default router;
