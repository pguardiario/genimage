const express = require('express');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(express.json());

// --- CONFIG CHANGES FOR LCM ---
const SD_BINARY_PATH = '/app/stable-diffusion.cpp/build/bin/sd';

// MATCH THIS TO THE FILENAME YOU DOWNLOADED IN STEP 1:
const MODEL_PATH = '/app/models/lcm-model.gguf';
const OUTPUT_DIR = '/app/output';

if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR);
}

app.post('/generate', (req, res) => {
    const prompt = req.body.prompt || "a nice photo";
    // 2. LCM works best at 4-8 steps
    const steps = req.body.steps || 4;

    const timestamp = Date.now();
    const outputFile = path.join(OUTPUT_DIR, `img_${timestamp}.png`);

    console.log(`🎨 Starting generation for: "${prompt}" (Steps: ${steps})`);

    const args = [
        '-m', MODEL_PATH,
        '-p', prompt,
        '-o', outputFile,
        '--steps', steps,
        // 3. CRITICAL: LCM needs low guidance scale (1.0 - 2.0)
        '--cfg-scale', '1.5',
        '-W', '512',
        '-H', '512',
        // 4. Force use of all CPU threads
        '--threads', '4'
    ];

    const sdProcess = spawn(SD_BINARY_PATH, args);

    sdProcess.stderr.on('data', (data) => {
        // console.error(`[SD-CPP]: ${data}`);
    });

    sdProcess.on('close', (code) => {
        if (code !== 0) {
            console.error(`❌ Process exited with code ${code}`);
            return res.status(500).json({ error: "Generation failed" });
        }

        console.log("✅ Generation complete.");

        try {
            const imageBuffer = fs.readFileSync(outputFile);
            const base64Image = imageBuffer.toString('base64');
            fs.unlinkSync(outputFile);

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
    console.log('🚀 Node.js LCM-SD API listening on port 8000');
});