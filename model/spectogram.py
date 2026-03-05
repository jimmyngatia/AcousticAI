import torch
import numpy as np
import torchaudio
import matplotlib.pyplot as plt
from PIL import Image
import soundfile as sf
import os

SPECTOGRAM_DPI = 90
DEFAULT_SAMPLE_RATE = 16000
DEFAULT_HOP_LENGTH = 512
FIXED_WIDTH = 128  # Fixed number of time frames
FIXED_HEIGHT = 64  # Fixed number of mel bins

class AudioProcessor:
    def __init__(self, filepath_, hop_length=DEFAULT_HOP_LENGTH, 
                 target_sample_rate=DEFAULT_SAMPLE_RATE,
                 fixed_length_seconds=5.0):  # Fixed duration
        
        self.hop_length = hop_length
        self.target_sample_rate = target_sample_rate
        self.fixed_length_seconds = fixed_length_seconds
        self.fixed_length_samples = int(target_sample_rate * fixed_length_seconds)
        
        # Load audio
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
        mel_spectogram = torchaudio.transforms.MelSpectrogram(
            sample_rate=self.target_sample_rate,
            n_fft=1024,
            hop_length=self.hop_length,
            n_mels=n_mels
        )
        to_db = torchaudio.transforms.AmplitudeToDB()
        
        mel_spec = to_db(mel_spectogram(self.waveform))
        
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
    
    def save_spectrogram_as_image(self, output_path, figsize=(4, 4), dpi=SPECTOGRAM_DPI):
        """Save mel spectrogram as image file (for CNN input)"""
        mel_spec = self.get_mel_spectrogram()
        
        # Create figure without axes for clean image
        fig, ax = plt.subplots(figsize=figsize, dpi=dpi)
        ax.imshow(mel_spec[0].numpy(), origin="lower", aspect="auto", cmap='viridis')
        ax.axis('off')
        plt.tight_layout(pad=0)
        plt.savefig(output_path, bbox_inches='tight', pad_inches=0)
        plt.close()
    
    def plot_spectrogram(self):
        """Display mel spectrogram with labels"""
        mel_spec = self.get_mel_spectrogram()
        
        plt.figure(figsize=(10, 4))
        plt.imshow(mel_spec[0].numpy(), origin="lower", aspect="auto", cmap='viridis')
        plt.colorbar(format="%+2.0f dB")
        plt.title(f"Mel Spectrogram (Shape: {mel_spec.shape})")
        plt.xlabel("Time")
        plt.ylabel("Mel Frequency")
        plt.tight_layout()
        plt.show()