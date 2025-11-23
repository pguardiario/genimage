import sys
import os

# --- FIX: Force /app to be in the Python path so 'constants.py' is found ---
sys.path.insert(0, os.getcwd())
sys.path.insert(0, "/app")
# ---------------------------------------------------------------------------

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import base64
from io import BytesIO

try:
    from src.backend.models.lcmdiffusion_setting import LCMDiffusionSetting
    from src.backend.pipelines.lcm import LCM
except ImportError as e:
    print(f"❌ IMPORT ERROR: {e}")
    print(f"Current Working Directory: {os.getcwd()}")
    print("Listing files in current directory:")
    print(os.listdir(os.getcwd()))
    raise e

app = FastAPI()

# --- Configuration ---
MODEL_ID = "SimianLuo/LCM_Dreamshaper_v7"
USE_OPENVINO = True # Typo fixed here

# Global pipeline variable
pipeline = None

class GenerateRequest(BaseModel):
    prompt: str
    steps: int = 4
    width: int = 512
    height: int = 512

@app.on_event("startup")
def load_model():
    global pipeline
    print("⏳ Loading FastSD CPU Model... (This may take time on first run)")

    lcm_setting = LCMDiffusionSetting(
        lcm_model_id=MODEL_ID,
        use_openvino=USE_OPENVINO,
        use_offline_model=False,
        use_tiny_auto_encoder=True,
    )

    pipeline = LCM(
        lcm_setting.lcm_model_id,
        lcm_setting.use_openvino,
        lcm_setting.use_local_model,
    )

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
        images = pipeline.generate(
            req.prompt,
            req.prompt,
            req.steps,
            1.0,
            req.width,
            req.height,
            1,
            1
        )

        buffered = BytesIO()
        images[0].save(buffered, format="PNG")
        img_str = base64.b64encode(buffered.getvalue()).decode("utf-8")

        return {"status": "success", "image_base64": img_str}

    except Exception as e:
        print(f"Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))