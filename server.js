const express = require('express');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(express.json());

// Paths
const SD_BINARY_PATH = '/app/stable-diffusion.cpp/build/bin/sd';
const MODEL_PATH = '/app/models/sd-v1-5-q5.gguf';
const OUTPUT_DIR = '/app/output';

// Ensure output dir exists
if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR);
}

app.post('/generate', (req, res) => {
    const prompt = req.body.prompt || "a nice photo";
    // 4 steps is too low for standard SD, we need ~10-20 for this model.
    // However, it's C++, so it's fast.
    const steps = req.body.steps || 15;

    // Generate a unique filename to allow concurrent requests
    const timestamp = Date.now();
    const outputFile = path.join(OUTPUT_DIR, `img_${timestamp}.png`);

    console.log(`🎨 Starting generation for: "${prompt}"`);

    // Arguments for stable-diffusion.cpp
    // -m: Model path
    // -p: Prompt
    // -o: Output file
    // --steps: Steps
    // --threads: Uses CPU threads (default is often ideal, but we can force it)
    const args = [
        '-m', MODEL_PATH,
        '-p', prompt,
        '-o', outputFile,
        '--steps', steps,
        '--cfg-scale', '7.0',
        '-W', '512',
        '-H', '512'
    ];

    const sdProcess = spawn(SD_BINARY_PATH, args);

    // Log output from the C++ binary (optional, good for debug)
    sdProcess.stdout.on('data', (data) => {
        // console.log(`[SD-CPP]: ${data}`); // Uncomment to see progress bars
    });

    sdProcess.stderr.on('data', (data) => {
        // console.error(`[SD-CPP Error]: ${data}`);
    });

    sdProcess.on('close', (code) => {
        if (code !== 0) {
            console.error(`❌ Process exited with code ${code}`);
            return res.status(500).json({ error: "Generation failed" });
        }

        console.log("✅ Generation complete. Reading file...");

        try {
            // Read the file directly into a buffer
            const imageBuffer = fs.readFileSync(outputFile);
            const base64Image = imageBuffer.toString('base64');

            // Cleanup: Delete the file to save space
            fs.unlinkSync(outputFile);

            // Respond
            res.json({
                status: "success",
                image_base64: base64Image
            });
        } catch (err) {
            console.error("❌ File read error:", err);
            res.status(500).json({ error: "Could not read generated image" });
        }
    });
});

app.listen(8000, '0.0.0.0', () => {
    console.log('🚀 Node.js SD API listening on port 8000');
});