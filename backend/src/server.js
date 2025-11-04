import express from "express";
import cors from "cors";
import helmet from "helmet";
import compression from "compression";
import morgan from "morgan";

import { config } from "./config.js";
import routes from "./routes/index.js";

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(compression());
app.use(morgan("tiny"));

app.get("/", (req, res) => {
  res.json({
    name: "SchemePlus Backend",
    version: "0.1.0",
    documentation: "/docs"
  });
});

app.use("/api", routes);

app.use((req, res) => {
  res.status(404).json({ error: "Not found" });
});

/* eslint-disable-next-line no-unused-vars */
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: "Internal server error" });
});

const start = () => {
  const port = config.port;
  const server = app.listen(port, () => {
    console.log(`SchemePlus backend listening on port ${port}`);
  });

  server.on('error', (err) => {
    if (err && err.code === 'EADDRINUSE') {
      console.error(`Port ${port} is already in use. Please free the port or set PORT to a different value.`);
      console.error('Common fixes:');
      console.error(`  - Find and kill the process using the port: lsof -i :${port}  (or sudo ss -ltnp | grep :${port})`);
      console.error(`  - Start the server on another port: PORT=${port + 1} npm run dev`);
      process.exit(1);
    }
    // rethrow for other errors
    throw err;
  });
};

start();
