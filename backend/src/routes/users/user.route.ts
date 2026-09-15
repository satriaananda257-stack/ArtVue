import { Router } from "express";
import usersController from "../../controllers/users/user.controller";
import { authenticate } from "../../config/middleware/auth.middleware";
import { uploadSingleImage } from "../../config/middleware/upload.middleware";

const router = Router();

// GET my profile
router.get("/me", authenticate, usersController.getMyProfile);

// UPDATE my profile
router.patch("/me", authenticate, uploadSingleImage, usersController.updateMyProfile);

// GET my liked posts
router.get("/me/liked", authenticate, usersController.getMyLikedPosts);

// GET my favorites
router.get("/me/favorites", authenticate, usersController.getMyFavorites);

// GET my posts
router.get("/me/posts", authenticate, usersController.getMyPosts);

// GET user profile by id
router.get("/:id/profile", usersController.getUserProfile);

// FOLLOW / UNFOLLOW
router.post("/:id/follow", authenticate, usersController.followUser);
router.delete("/:id/follow", authenticate, usersController.unfollowUser);

export default router;
