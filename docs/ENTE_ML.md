# Ente ML memories

Earlier versions used Ente's `cgroup` person entities: named face clusters,
manual assignments and hidden-person preferences powered people memories.
They did not use CLIP scene search. The new integration also reads compatible
Ente visual-search results to create photo themes and collage previews.

## Available themes

Happy hour, Work mode, Cozy cafés, Reasons to celebrate, Quiet moments, Golden
hour, Outdoor adventures, Food & friends, City nights, By the water, Playful days,
Live music, Sports & games, Creative spaces, Festive lights and At home together.

These are approximate visual themes. "Work mode" means an office, meeting or
workspace appears in the image; it does not identify someone's occupation.
"Happy hour" describes a social scene. The app does not infer a person's actual
emotions, mental health, personality or whether they consumed alcohol.

## Getting results

1. Enable machine learning / visual search in an official Ente Photos client.
2. Let that client finish indexing and syncing its encrypted ML data.
3. Open Entegram and refresh. Scene matches arrive progressively in the background.
4. Select **Moods & settings** to see collages, coverage and availability information.

Entegram reuses the existing index. It does not upload photos to an AI service,
run a server-side model, enable indexing on your server, or upload new embeddings.
Photos without compatible results continue to receive calendar, people, trip and
other metadata memories. A missing/unsupported ML endpoint cannot stop normal
archive sync. Legacy `/embeddings` CLIP formats are not treated as compatible.

## Protocol and model compatibility

- `POST /files/data/status-diff` reads updated file-data status; the cursor is
  committed only after the persistent queue is written.
- `POST /files/data/fetch` reads `mldata` for known, queued files in batches of 32.
  Fetch responses are capped at 32 MiB. Files without ML status are not repeatedly
  probed. Server-pending and failed entries retain explicit retry state.
- The key-owning worker unwraps the file key using a surviving album key, decrypts
  XChaCha20 secretstream data, and gunzips JSON with a 4 MiB expanded-size limit.
- Only `clip.version == 1` with a finite, nonzero 512-dimensional vector is
  accepted. Unknown versions are skipped instead of comparing different spaces.
- This format uses Ente's MobileCLIP S2 vector space. Query vectors are generated
  with `mobileclip_s2_text_opset18_quant.onnx`, SHA-256
  `d92f33dfcff83077fc2e0d3414250710efbb51795dfd89767bdbefb5fdc47322`.
  The 67 MB text model is a build-time tool; the app bundles only public prompt
  vectors (about 284 KiB), with no runtime model download.

Both image and query vectors are normalized. A theme takes the maximum cosine
similarity over three scene descriptions. A match must clear its absolute
threshold (0.20–0.24), beat a neutral everyday-photo prompt by at least 0.03, and
remain within 0.035 of the strongest theme. At most two themes qualify per photo.
Thresholds are heuristics, not calibrated emotion probabilities. Public café,
office, mountain, beach and banquet reference photos check useful positive
matches and conservative rejection, rather than asserting that every photo
has a mood.

## Curation, storage and UI

A collage needs four eligible photos in a theme/year. Hidden-person photos,
known duplicate hashes, screenshots and other existing exclusions still apply.
Thirty-second spacing and a four-photo daily cap keep bursts from filling a
collage. The strongest semantic match is preferred for the cover. Scene cards
share the existing limits: at most 24 slides, 80 total memories, limited reuse,
and distinct covers. There are at most 12 scene memories per rebuild.

`FileMl` stores queue state and 17 compact query scores, not raw CLIP vectors or
face embeddings. A status update arriving before its photo is persisted for
later archive recovery. Successful scores survive metadata replay and restart;
removing the last album link or signing out removes them. Account-scoped status
cursors are separate from the metadata cursors. A new prompt revision queues
reclassification. Opening the scene filter shows how much of the local library
has compatible results and explains unavailable or failed ML sync.

Collage previews load only four thumbnails. Every tile opens the correct
original in the existing gallery; the play button opens the normal story viewer.

## Reproducing and testing

Download the public model and `bpe_simple_vocab_16e6.txt` from
<https://models.ente.com/> into a local model directory. Install Python
`numpy`, `onnxruntime`, `regex` and `ftfy`, then run:

```sh
python3 tool/generate_semantic_prompts.py --model-dir /path/to/models
flutter analyze
flutter test
python3 tool/verify_selfhost.py --ml-sample
```

The generator verifies the model and vocabulary SHA-256 hashes and uses the
pinned MIT-licensed OpenAI CLIP tokenizer (license in `tool/licenses/CLIP-MIT.txt`).
It does not read personal photos. Ordinary tests use public reference scores,
synthetic scenes, real encrypted payloads and native Isar. The opt-in live check
reads a limited account metadata/ML sample, discards raw framework output and
removes temporary private data. Device codec support and frame rates still need
physical-device testing.
