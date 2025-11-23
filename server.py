import os
import sys
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import base64
from io import BytesIO

# --- Debug: Verify we are in the right place ---
print(f"📂 Current Directory: {os.getcwd()}")
if "constants.py" in os.listdir():
    print("✅ Found constants.py in root!")
else:
    print("❌ constants.py NOT FOUND in root! Files present:")
    print(os.listdir())
# -----------------------------------------------

# Import the model
try:
    from src.backend.models.lcmdiffusion_setting import LCMDiffusionSetting
    from src.backend.pipelines.lcm import LCM
    print("✅ FastSD libraries imported successfully.")
except ImportError as e:
    print(f"❌ CRITICAL IMPORT ERROR: {e}")
    # Force crash so we see logs
    sys.exit(1)

app = FastAPI()

# --- Configuration ---
MODEL_ID = "SimianLuo/LCM_Dreamshaper_v7"
USE_OPENVINO = True

pipeline = None

class GenerateRequest(BaseModel):
    prompt: str
    steps: int = 4
    width: int = 512
    height: int = 512

@app.on_event("startup")
def load_model():
    global pipeline
    print("⏳ Loading FastSD CPU Model...")

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
    print("✅ Model Ready.")

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