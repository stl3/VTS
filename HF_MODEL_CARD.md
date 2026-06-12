---
license: mit
library_name: pytorch
tags:
  - audio-generation
  - sound-effects
  - voice-conditioned
  - text-conditioned
  - pytorch
---

# VTS

VTS generates sound effects from:

- a short voice or audio sketch
- a text prompt

This model repository hosts the pretrained checkpoint for the VTS inference
codebase.

## Files

- `dynamic_v3_0415.ckpt`: main VTS checkpoint

The companion inference repository downloads additional frozen components at
runtime, including `google/flan-t5-base` and vocoder files used by the local
`vts/vocos_custom` implementation.

## Download

```bash
pip install -U "huggingface_hub"
hf download <your-user-or-org>/<your-model-repo> dynamic_v3_0415.ckpt --local-dir ./checkpoints
```

## Usage

Use this checkpoint with the companion `vts_inference` repository.

```bash
python -u infer.py \
  --input-audio ./examples/voice.wav \
  --text "scifi cannon charging and shooting" \
  --temperature 0.7 \
  --model-path ./checkpoints/dynamic_v3_0415.ckpt \
  --output-dir ./outputs \
  --device cuda
```

## Temperature Behavior

For normal inference, use `--temperature 0.7`. This keeps the original dynamic
conditioning from the input audio and runs the standard `generate` path.

- `< 0.6`: weak dynamic conditioning + `generate`
- `0.6 <= temperature < 0.8`: full dynamic conditioning + `generate`
- `>= 0.8`: input-audio latent mixing + `variation`

The input audio is not treated as a speaker embedding. It is converted into
frame-level dynamic features and, for high-temperature variation, also encoded
into the vocoder latent space.

## Intended Use

This checkpoint is intended for research and creative sound-effect generation
from vocal sketches or short audio sketches plus text prompts.

## Limitations

- The model is optimized for short sound-effect style clips.
- Output quality depends on checkpoint quality, input audio, prompt text, and
  sampling settings.
- This is not packaged as a Hugging Face Inference API pipeline.

## License

MIT.
