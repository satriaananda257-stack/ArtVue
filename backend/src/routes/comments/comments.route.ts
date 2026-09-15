import { Router } from "express";
import commentsController from "../../controllers/comments/comments.controller";
import { authenticate } from "../../config/middleware/auth.middleware";

const router = Router();

// GET comments by postId
router.get("/posts/:postId", commentsController.getCommentsByPostId);

// CREATE comment on a post
router.post("/posts/:postId", authenticate, commentsController.createComment);

// DELETE comment (owner only)
router.delete("/:id", authenticate, commentsController.deleteComment);

export default router;
