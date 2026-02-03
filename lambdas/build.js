import esbuild from "esbuild";
import fs from "fs/promises";
import fsSync from "fs";
import path from "path";
import archiver from "archiver";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const srcDir = path.join(__dirname, "src");
const outBase = path.join(__dirname, "dist");
const artifactsDir = path.join(__dirname, "artifacts");
await fs.mkdir(outBase, { recursive: true });
await fs.mkdir(artifactsDir, { recursive: true });

const dirents = await fs.readdir(srcDir, { withFileTypes: true });
const entries = dirents.filter((d) => d.isDirectory()).map((d) => d.name);

const buildLambda = async (name, entry, outfile) => {
    await esbuild.build({
        entryPoints: [entry],
        bundle: true,
        platform: "node",
        target: ["node20"],
        outfile,
        external: ["aws-sdk"],
        sourcemap: false,
        minify: false,
    });
};

// Use a fixed timestamp so the archive is deterministic across builds and we can compare the hash to detect code changes
const FIXED_ZIP_DATE = new Date(0);

const createZip = async (outfile, zipPath) => {
    const output = fsSync.createWriteStream(zipPath);
    const archive = archiver("zip", { zlib: { level: 9 } });

    archive.pipe(output);
    archive.file(outfile, { name: "index.js", date: FIXED_ZIP_DATE });

    try {
        archive.finalize();
    } catch (err) {
        reject(err);
    }
};

const run = async () => {
    for (const name of entries) {
        const folder = path.join(srcDir, name);

        // find entry file (index.ts, <lambda_folder_name>.ts)
        const candidates = [path.join(folder, "index.ts"), path.join(folder, `${name}.ts`)];
        const entry = candidates.find((p) => fsSync.existsSync(p));
        if (!entry) {
            console.warn(`Skipping ${name}, no entry file found in ${folder}`);
            continue;
        }

        const outDir = path.join(outBase, name);
        await fs.mkdir(outDir, { recursive: true });

        const outfile = path.join(outDir, "index.js");

        await buildLambda(name, entry, outfile);

        const zipPath = path.join(artifactsDir, `${name}.zip`);
        console.log("Creating zip:", zipPath);
        await createZip(outfile, zipPath).catch((err) => {
            console.error(`Error creating zip for ${name}:`, err);
            process.exit(1);
        });

        console.log(`Lambda ${name} built successfully.`);
    }
};

await run().catch((err) => {
    console.error("Build failed:", err);
    process.exit(1);
});
