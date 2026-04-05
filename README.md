# manim-server

FastAPI render service for Manim with a queue-based job architecture.

## Setup

```bash
cd /home/M-Arham07/manim-server
source .venv/bin/activate
pip install -e .
```

## Run

```bash
cd /home/M-Arham07/manim-server
./start.sh
```

## Build Single-File Render Entrypoint

```bash
cd /home/M-Arham07/manim-server
python scripts/build_render_single_file.py
```

This generates `render_app.py`, which contains the FastAPI app and a `__main__`
runner so Render can start it directly with either:

```bash
python render_app.py
```

or:

```bash
uvicorn render_app:app --host 0.0.0.0 --port $PORT
```

## Architecture

- `POST /jobs` creates a render job and places it on a server-side queue.
- A single async worker pulls jobs from the queue and renders them one at a time.
- `GET /jobs/{job_id}` returns status and queue position.
- `GET /jobs/{job_id}/logs` returns accumulated Manim and ffmpeg logs.
- `GET /jobs/{job_id}/download` returns the final MP4 when ready.
- `DELETE /jobs/{job_id}` deletes the job record and temporary files.

Default render quality is `h`, which maps to Manim's 1080p high-quality preset.

## API

### Create job

```bash
cd /home/M-Arham07/manim-server
python -c 'import json, pathlib; print(json.dumps({"code": pathlib.Path("code.text").read_text(), "scene_name": "MainScene", "quality": "h"}))' > payload.json

curl -X POST http://127.0.0.1:8000/jobs \
  -H "Content-Type: application/json" \
  --data @payload.json
```

Example response:

```json
{
  "job_id": "8ab9e3d8-8b11-4d0f-9e0f-7cc6c68b0af5",
  "status": "queued",
  "quality": "h",
  "download_url": "/jobs/8ab9e3d8-8b11-4d0f-9e0f-7cc6c68b0af5/download",
  "status_url": "/jobs/8ab9e3d8-8b11-4d0f-9e0f-7cc6c68b0af5",
  "logs_url": "/jobs/8ab9e3d8-8b11-4d0f-9e0f-7cc6c68b0af5/logs"
}
```

### Poll status

```bash
curl http://127.0.0.1:8000/jobs/<job_id>
```

### Fetch logs

```bash
curl http://127.0.0.1:8000/jobs/<job_id>/logs
```

### Download video

```bash
curl -L http://127.0.0.1:8000/jobs/<job_id>/download --output output.mp4
```

### Cleanup

```bash
curl -X DELETE http://127.0.0.1:8000/jobs/<job_id>
```

## Client implementation

Client flow:

1. Read the generated Manim code into a JSON payload.
2. `POST /jobs`.
3. Store `job_id`.
4. Poll `GET /jobs/{job_id}` every 2 to 5 seconds.
5. If status is `failed`, fetch `GET /jobs/{job_id}/logs` and surface the logs.
6. If status is `done`, call `GET /jobs/{job_id}/download` and save the MP4.
7. After download, call `DELETE /jobs/{job_id}` to remove temp files.

Minimal browser client outline:

```js
async function renderManim(code) {
  const create = await fetch("http://127.0.0.1:8000/jobs", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      code,
      scene_name: "MainScene",
      quality: "h"
    })
  });

  const job = await create.json();
  const jobId = job.job_id;

  while (true) {
    const statusRes = await fetch(`http://127.0.0.1:8000/jobs/${jobId}`);
    const status = await statusRes.json();

    if (status.status === "done") {
      const videoRes = await fetch(`http://127.0.0.1:8000/jobs/${jobId}/download`);
      const blob = await videoRes.blob();
      const url = URL.createObjectURL(blob);
      return { jobId, url };
    }

    if (status.status === "failed") {
      const logsRes = await fetch(`http://127.0.0.1:8000/jobs/${jobId}/logs`);
      const logs = await logsRes.text();
      throw new Error(logs || status.error || "render failed");
    }

    await new Promise((resolve) => setTimeout(resolve, 3000));
  }
}
```

React notes:

- Create one mutation to submit code.
- Store `jobId` in component state.
- Poll with `setInterval`, React Query polling, or SWR refresh.
- Show queue position while status is `queued`.
- Show logs in a collapsible debug panel.
- Render the resulting blob URL in a `<video controls />`.
- Delete the job after successful download or after the user closes the result.

## Prompt

Use this prompt when asking an LLM to generate Manim code for this server:

```text
You are an expert Manim Community Edition code generator.

Return only Python code. Do not include markdown fences. Do not include explanations. Do not include notes. Do not include any text before or after the code.

Generate one complete, runnable Manim script on a unique and visually teachable math topic.

Hard requirements:
- Output a single valid Python file.
- Use Manim Community Edition syntax.
- Include all imports.
- Define exactly one main scene class named MainScene.
- The animation must run for at least 60 seconds at normal playback speed.
- The video must be designed for 1080p high-quality rendering.
- Use clear English subtitles and explanatory text inside the scene with Manim Text objects.
- The animation must genuinely teach the topic, not just display shapes.
- Use a monochromatic visual style as the base.
- Add accent colors only when necessary for emphasis.
- Keep the design elegant, restrained, and mathematically serious.
- Use Apple-style typography by setting the font on Text objects to "SF Pro Display" or "SF Pro Text".
- If those fonts are unavailable, prefer a close sans-serif fallback such as "Helvetica Neue".
- Do not use random font choices.
- Ensure text never overlaps important geometry, labels, formulas, arrows, or animated objects.
- Place text in safe screen regions using edges, corners, panels, spacing, and scene choreography.
- If geometry moves into a text area, move the text or move the geometry.
- Keep all subtitles readable and on screen long enough to read.
- Avoid giant paragraphs.
- Use meaningful animations: transformations, highlights, constructions, motion, comparisons, or parameter changes.
- Structure the scene with introduction, intuition, worked example, and conclusion.
- Keep the math accurate.
- Keep the code self-contained.
- Do not require external assets, images, audio, network calls, or custom files.
- Avoid LaTeX-dependent objects such as MathTex and Tex unless absolutely necessary.
- Prefer Text, DecimalNumber, geometric labels, and plain-English explanations.
- Do not use add_coordinates() if it may introduce TeX-based labels.
- The code must be robust and likely to render successfully in a typical Manim server environment.

Output constraints:
- Return code only.
- No markdown.
- No commentary.
- No placeholders.
- No pseudocode.
- The script must be directly renderable.
```
