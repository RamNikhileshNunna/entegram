#!/usr/bin/env python3
"""Generate public prompt vectors; never reads personal photos.

Requires numpy, onnxruntime, regex and ftfy. The tokenizer is OpenAI CLIP's
MIT-licensed SimpleTokenizer (see tool/licenses/CLIP-MIT.txt). Supply Ente's
public model assets in --model-dir; both downloads are pinned by SHA-256.
"""
import argparse
import gzip
import hashlib
import json
from pathlib import Path
import numpy as np
import onnxruntime as ort
from clip_tokenizer import SimpleTokenizer

MODEL = 'mobileclip_s2_text_opset18_quant.onnx'
MODEL_SHA = 'd92f33dfcff83077fc2e0d3414250710efbb51795dfd89767bdbefb5fdc47322'
VOCAB = 'bpe_simple_vocab_16e6.txt'
VOCAB_SHA = '67603cfda2e032ad77b5f8808af37789d590db664b26df8705d2bf8b3c553fc8'
THEMES = [
    ('happy-hour', ['Friends socializing with drinks at a bar or cafe', 'A social gathering with friends chatting around drinks', 'People enjoying an evening together at a pub']),
    ('work-mode', ['People in an office meeting around a conference table', 'A professional presentation in a conference room', 'An office workspace with laptops desks and coworkers']),
    ('cozy-cafes', ['A cozy cafe with warm lighting and coffee cups', 'People having coffee inside a comfortable coffee shop', 'A quiet cafe table with coffee and pastries']),
    ('celebrations', ['A birthday celebration with cake candles and decorations', 'A joyful party with people celebrating together', 'A celebration with balloons decorations and a group of friends']),
    ('quiet-moments', ['A peaceful quiet reading corner with a book', 'A serene tranquil landscape with still water', 'A calm quiet scene with soft natural light']),
    ('golden-hour', ['A portrait taken in warm golden hour sunlight', 'A landscape glowing in golden sunset light', 'Warm evening sunlight just before sunset']),
    ('outdoor-adventures', ['People hiking on a scenic mountain trail', 'An outdoor adventure in a forest or mountains', 'People camping and exploring nature']),
    ('food-friends', ['Friends sharing a meal around a dining table', 'People eating delicious food together at a restaurant', 'A picnic meal shared with friends outdoors']),
    ('city-nights', ['A city street illuminated by neon lights at night', 'A city skyline with glowing lights after dark', 'People walking through a lively city at night']),
    ('by-the-water', ['A relaxing day at the beach beside the sea', 'A lakeside scene with people beside the water', 'A scenic coast or river with water and shore']),
    ('playful-days', ['Children playing and having fun in a playground', 'A candid playful moment with family or friends', 'People laughing while playing a fun game together']),
    ('live-music', ['A live music concert with a band on stage', 'A singer performing on stage under concert lights', 'A crowd watching musicians perform live']),
    ('sports-games', ['People playing sports on a field or court', 'A team sports game with players in action', 'People exercising at a gym or playing a sport']),
    ('creative-spaces', ['An art studio with paintings brushes and creative work', 'People making art or crafts at a workshop', 'An artistic workspace with creative tools and materials']),
    ('festive-lights', ['A festive night with colorful lights and decorations', 'Fireworks lighting up the night sky during a festival', 'A celebration with sparkling lights and festive decorations']),
    ('home-together', ['Family spending time together in a living room at home', 'Friends relaxing together on a sofa at home', 'A cozy family gathering inside a home']),
]
NEUTRAL = 'A photo of an ordinary everyday scene'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--model-dir', type=Path, required=True)
    parser.add_argument('--output', type=Path, default=Path('assets/ml/semantic_prompts.json'))
    args = parser.parse_args()
    for name, sha in [(MODEL, MODEL_SHA), (VOCAB, VOCAB_SHA)]:
        if hashlib.sha256((args.model_dir / name).read_bytes()).hexdigest() != sha:
            raise ValueError('Model asset SHA-256 mismatch: ' + name)
    compressed_vocab = args.model_dir / (VOCAB + '.gz')
    compressed_vocab.write_bytes(gzip.compress((args.model_dir / VOCAB).read_bytes(), mtime=0))
    tokenizer = SimpleTokenizer(str(compressed_vocab))
    assert tokenizer.encode('hello world') == [3306, 1002]
    options = ort.SessionOptions()
    options.intra_op_num_threads = 1
    session = ort.InferenceSession(str(args.model_dir / MODEL), sess_options=options, providers=['CPUExecutionProvider'])
    model_input = session.get_inputs()[0]
    dtype = np.int32 if model_input.type == 'tensor(int32)' else np.int64

    def embed(text):
        tokens = [49406] + tokenizer.encode(text)[:75] + [49407]
        tokens += [0] * (77 - len(tokens))
        vector = session.run(None, {model_input.name: np.array([tokens], dtype=dtype)})[0].reshape(-1)
        if len(vector) != 512 or not np.isfinite(vector).all():
            raise ValueError('Invalid model output')
        return vector / np.linalg.norm(vector)

    themes = []
    for name, prompts in THEMES:
        vectors = [embed('A photo of ' + p[0].lower() + p[1:]) for p in prompts]
        themes.append({'id': name, 'prompts': prompts,
                       'vectors': [[round(float(v), 8) for v in vector] for vector in vectors]})
    document = {
        'revision': 1, 'space': 'ente-mobileclip-s2-v1', 'scoring': 'max-of-3',
        'model': {'file': MODEL, 'sha256': MODEL_SHA, 'url': 'https://models.ente.com/' + MODEL},
        'vocabulary': {'file': VOCAB, 'sha256': VOCAB_SHA},
        'tokenizerSource': 'https://github.com/openai/CLIP/blob/a1d071733d7111c9c014f024669f959182114e33/clip/simple_tokenizer.py',
        'themes': themes,
        'neutral': {'prompt': NEUTRAL, 'vector': [round(float(v), 8) for v in embed(NEUTRAL)]},
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(document, ensure_ascii=False, separators=(',', ':')) + '\n')
    print('Generated', len(themes), 'themes with 512-dimensional vectors in', args.output)


if __name__ == '__main__':
    main()
