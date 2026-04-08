import { app } from "./app";
import { env } from "./config/env";

app.listen(env.port, () => {
  console.log(`backend running at http://0.0.0.0:${env.port}`);
});
