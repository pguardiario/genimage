from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import base64
from io import BytesIO
from src.backend.models.lcmdiffusion_setting import LCMDiffusionSetting
from src.backend.pipelines.lcm import LCM

app = FastAPI()

# --- Configuration ---
# LCM-Dreamshaper is the best balance of speed/quality for CPU
MODEL_ID = "SimianLuo/LCM_Dreamshaper_v7"
USE_OPENVINO = True # Critical for CPU speed
# Global pipeline variable
pipeline = None

class GenerateRequest(BaseModel):
    prompt: str
    steps: int = 4  # 4 steps is standard for LCM
    width: int = 512
    height: int = 512

@app.on_event("startup")
def load_model():
    global pipeline
    print("⏳ Loading FastSD CPU Model... (This may take time on first run)")

    lcm_setting = LCMDiffusionSetting(
        lcm_model_id=MODEL_ID,
        use_openvino=True,
        use_offline_model=False,
        use_tiny_auto_encoder=True, # SAVES RAM
    )

    pipeline = LCM(
        lcm_setting.lcm_model_id,
        lcm_setting.use_openvino,
        lcm_setting.use_local_model,
    )

    # Initialize/Warmup
    pipeline.init(
        lcm_setting.diffusion_task,
        lcm_setting.lcm_lora_id,
        lcm_setting.use_tiny_auto_encoder,
    )
    print("✅ Model Loaded and Ready.")

@app.post("/generate")
async def generate_image(req: GenerateRequest):
    if not pipeline:
        raise HTTPException(status_code=500, detail="Model not loaded")

    try:
        # Generate image
        # FastSD returns a list of PIL images
        images = pipeline.generate(
            req.prompt,
            req.prompt, # negative prompt (using same or empty)
            req.steps,
            1.0, # guidance scale
            req.width,
            req.height,
            1, # seed (random)
            1  # number of images
        )

        # Convert PIL image to Base64
        buffered = BytesIO()
        images[0].save(buffered, format="PNG")
        img_str = base64.b64encode(buffered.getvalue()).decode("utf-8")

        return {"status": "success", "image_base64": img_str}

    except Exception as e:
        print(f"Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
