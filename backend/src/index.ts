import dotenv from "dotenv";
dotenv.config();

import express from "express";
import cors from "cors";
import authRoute from "./routes/auth/auth.route";
import postsRoute from "./routes/posts/posts.route";
import usersRouter from "./routes/users/user.route";
import commentsRouter from "./routes/comments/comments.route";

const app = express();
const PORT = 3000;

app.use(cors({
    origin: (origin, callback) => {
        // Allow requests with no origin (mobile apps, curl, etc.)
        if (!origin) return callback(null, true);
        // Allow localhost, 127.0.0.1, and any local network IP (192.168.x.x, 10.x.x.x, 172.x.x.x)
        if (
            origin.startsWith("http://localhost") ||
            origin.startsWith("http://127.0.0.1") ||
            origin.startsWith("http://192.168.") ||
            origin.startsWith("http://10.") ||
            origin.startsWith("http://172.")
        ) {
            return callback(null, true);
        }
        return callback(new Error("Not allowed by CORS"));
    },
    credentials: true,
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
}));

// Handle OPTIONS preflight for all routes
app.options(/(.*)/, cors());
app.use(express.json());

app.use("/api/v1/posts", postsRoute);
app.use("/api/v1/auth", authRoute);
app.use("/api/v1/users", usersRouter);
app.use("/api/v1/comments", commentsRouter);

app.get("/", (_req, res) => {
    res.send("Hello World");
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`⚡️[server]: Server is running at http://localhost:${PORT}`);
    console.log(`⚡️[server]: Also accessible at http://192.168.18.6:${PORT}`);
});


