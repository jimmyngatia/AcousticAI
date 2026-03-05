import io
import os
import uuid
import shutil
import base64

import torch
import torch.nn as nn
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from PIL import Image
from torchvision import transforms, models

from pydub import AudioSegment
import soundfile as sf
import torchaudio
import matplotlib
matplotlib.use('Agg')  # Non-interactive backend
import matplotlib.pyplot as plt

# =====================================================
# CONFIG
# =====================================================
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "model", "best_model.pth")

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# CRITICAL: This order MUST match train_dataset.classes from training
# ImageFolder sorts alphabetically by folder name
CLASSES = [
    "Bronchiectasis",
    "Bronchiolitis",
    "COPD",
    "Healthy",
    "Pneumonia",
    "URTI"
]

# =====================================================
# AUDIO PROCESSOR (Matching notebook version EXACTLY)
# =====================================================

SPECTOGRAM_DPI = 90
DEFAULT_SAMPLE_RATE = 16000
DEFAULT_HOP_LENGTH = 512
FIXED_WIDTH = 128  # Fixed number of time frames
FIXED_HEIGHT = 64  # Fixed number of mel bins
FIXED_DURATION = 5.0  # seconds

class AudioProcessor:
    def __init__(self, filepath_, hop_length=DEFAULT_HOP_LENGTH,
                 target_sample_rate=DEFAULT_SAMPLE_RATE,
                 fixed_length_seconds=FIXED_DURATION):

        self.hop_length = hop_length
        self.target_sample_rate = target_sample_rate
        self.fixed_length_seconds = fixed_length_seconds
        self.fixed_length_samples = int(target_sample_rate * fixed_length_seconds)

        # Load audio with soundfile
        aud, original_sr = sf.read(filepath_)
        self.waveform = torch.tensor(aud, dtype=torch.float32)

        # Convert stereo to mono
        if self.waveform.ndim > 1:
            self.waveform = self.waveform.mean(dim=1)

        # Resample if needed
        if original_sr != target_sample_rate:
            resampler = torchaudio.transforms.Resample(
                orig_freq=original_sr,
                new_freq=target_sample_rate
            )
            self.waveform = resampler(self.waveform)

        # Pad or truncate to fixed length
        self.waveform = self._fix_length(self.waveform)

        # Add channel dimension
        self.waveform = self.waveform.unsqueeze(0)

    def _fix_length(self, waveform):
        """Pad or truncate waveform to fixed length"""
        current_length = waveform.shape[0]

        if current_length < self.fixed_length_samples:
            # Pad with zeros
            padding = self.fixed_length_samples - current_length
            waveform = torch.nn.functional.pad(waveform, (0, padding))
        elif current_length > self.fixed_length_samples:
            # Truncate
            waveform = waveform[:self.fixed_length_samples]

        return waveform

    def get_mel_spectrogram(self, n_mels=FIXED_HEIGHT):
        """Generate mel spectrogram with fixed dimensions"""
        mel_spectrogram = torchaudio.transforms.MelSpectrogram(
            sample_rate=self.target_sample_rate,
            n_fft=1024,
            hop_length=self.hop_length,
            n_mels=n_mels
        )
        to_db = torchaudio.transforms.AmplitudeToDB()

        mel_spec = to_db(mel_spectrogram(self.waveform))

        # mel_spec shape: [1, n_mels, time_frames]
        # Resize to fixed width if needed
        if mel_spec.shape[2] != FIXED_WIDTH:
            mel_spec = torch.nn.functional.interpolate(
                mel_spec.unsqueeze(0),  # Add batch dimension
                size=(n_mels, FIXED_WIDTH),
                mode='bilinear',
                align_corners=False
            ).squeeze(0)  # Remove batch dimension

        return mel_spec

    def get_pil_image(self):
        """Generate PIL image EXACTLY matching training pre-generated images"""
        mel_spec = self.get_mel_spectrogram()
        
        # Create temporary file path
        temp_path = os.path.join("/tmp", f"temp_spec_{uuid.uuid4()}.png")
        
        # Use EXACT same method as save_spectrogram_as_image (your training method)
        fig, ax = plt.subplots(figsize=(4, 4), dpi=SPECTOGRAM_DPI)
        ax.imshow(mel_spec[0].numpy(), origin="lower", aspect="auto", cmap='viridis')
        ax.axis('off')
        plt.tight_layout(pad=0)
        plt.savefig(temp_path, bbox_inches='tight', pad_inches=0)
        plt.close()
        
        # Load the saved file (exactly like ImageFolder does during training)
        img = Image.open(temp_path)
        img_rgb = img.convert('RGB')  # Convert to RGB (removes alpha channel)
        img.close()
        
        # Clean up temp file
        if os.path.exists(temp_path):
            os.remove(temp_path)
        
        return img_rgb

# =====================================================
# LOAD MODEL
# =====================================================
num_classes = len(CLASSES)
model = models.resnet18(weights=None)
model.fc = nn.Linear(model.fc.in_features, num_classes)

try:
    model.load_state_dict(torch.load(MODEL_PATH, map_location=device))
    model.to(device)
    model.eval()
    print("✅ Model loaded successfully!")
    print(f"📊 Classes: {CLASSES}")
    print(f"🖥️  Device: {device}")
except Exception as e:
    print(f"❌ Model load error: {e}")

# =====================================================
# FASTAPI APP
# =====================================================
app = FastAPI(title="AuraBreath: Acoustic AI Triage")

# =====================================================
# AUDIO → PREDICTION
# =====================================================
def get_prediction_from_audio(file_path):
    processor = AudioProcessor(file_path)
    img = processor.get_pil_image()

    # EXACT same transforms as training (val_transform)
    preprocess = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize(
            mean=[0.485, 0.456, 0.406],
            std=[0.229, 0.224, 0.225]
        )
    ])

    input_tensor = preprocess(img).unsqueeze(0).to(device)

    with torch.no_grad():
        outputs = model(input_tensor)
        probabilities = torch.softmax(outputs, dim=1)
        
        # Get top 3 predictions
        top3_probs, top3_indices = torch.topk(probabilities, 3, dim=1)

    # Top prediction
    predicted_class = CLASSES[top3_indices[0][0].item()]
    confidence_score = round(top3_probs[0][0].item() * 100, 2)

    # Top 3 predictions
    top3_predictions = [
        {
            "class": CLASSES[top3_indices[0][i].item()],
            "confidence": round(float(top3_probs[0][i].item() * 100), 2)
        }
        for i in range(3)
    ]

    # Spectrogram as base64
    buf = io.BytesIO()
    img.save(buf, format='PNG')
    buf.seek(0)
    img_base64 = base64.b64encode(buf.getvalue()).decode('utf-8')

    return predicted_class, confidence_score, top3_predictions, img_base64

# =====================================================
# API ENDPOINT
# =====================================================
@app.post("/predict")
async def predict_respiratory_health(file: UploadFile = File(...)):
    if not file.filename.lower().endswith(('.mp3', '.wav', '.ogg', '.m4a')):
        raise HTTPException(status_code=400, detail="Unsupported audio format")

    # Temporary folder
    temp_folder = os.path.join(BASE_DIR, "uploads", str(uuid.uuid4()))
    os.makedirs(temp_folder, exist_ok=True)
    temp_path = os.path.join(temp_folder, file.filename)

    try:
        # Save uploaded file
        with open(temp_path, "wb") as f:
            f.write(await file.read())

        # Convert non-WAV to WAV using pydub
        if not file.filename.lower().endswith('.wav'):
            wav_path = os.path.join(temp_folder, "converted.wav")
            audio = AudioSegment.from_file(temp_path)
            audio = audio.set_frame_rate(DEFAULT_SAMPLE_RATE).set_channels(1)
            audio.export(wav_path, format="wav")
            temp_path = wav_path

        predicted_class, confidence, top3_predictions, spectrogram_base64 = get_prediction_from_audio(temp_path)

        print(f"🎯 Prediction: {predicted_class} ({confidence}%)")
        print(f"📊 Top 3 predictions: {top3_predictions}")

        return {
            "filename": file.filename,
            "prediction": predicted_class,
            "confidence_percent": confidence,
            "top3_predictions": top3_predictions,
            "spectrogram_base64": spectrogram_base64
        }

    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return JSONResponse(status_code=500, content={"error": str(e)})

    finally:
        if os.path.exists(temp_folder):
            shutil.rmtree(temp_folder)

# =====================================================
# RUN
# =====================================================
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)