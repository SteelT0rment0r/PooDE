#!/usr/bin/env python3
import asyncio
import json
import sys
from pathlib import Path
from urllib.parse import urlsplit
import websockets

async def main():
    action = sys.argv[1] if len(sys.argv) > 1 else "next"
    if action not in ("prev", "next"):
        print("Expected prev or next.")
        return

    lines = (Path.home() / ".config/BraveSoftware/Brave-Browser/DevToolsActivePort").read_text().splitlines()
    async with websockets.connect(f"ws://127.0.0.1:{lines[0]}{lines[1]}") as ws:
        ident = 0

        async def request(method, params=None, session=None):
            nonlocal ident
            ident += 1
            msg = {"id": ident, "method": method, "params": params or {}}
            if session:
                msg["sessionId"] = session
            await ws.send(json.dumps(msg))
            while True:
                reply = json.loads(await ws.recv())
                if reply.get("id") == ident:
                    if "error" in reply:
                        raise RuntimeError(reply["error"].get("message", "CDP request failed"))
                    return reply.get("result", {})

        targets = (await request("Target.getTargets"))["targetInfos"]
        pages = [t for t in targets if t["type"] == "page" and (urlsplit(t.get("url", "")).hostname or "").endswith("youtube.com")]
        if not pages:
            print("No YouTube tab found.")
            return

        attached = await request("Target.attachToTarget", {"targetId": pages[0]["targetId"], "flatten": True})
        sid = attached["sessionId"]
        selector = ".ytp-prev-button" if action == "prev" else ".ytp-next-button"

        async def evaluate(expression):
            result = await request("Runtime.evaluate", {"expression": expression, "returnByValue": True}, sid)
            return result.get("result", {}).get("value")

        selector_js = json.dumps(selector)
        disabled = await evaluate(f"(()=>{{const b=document.querySelector({selector_js});return b ? b.getAttribute(aria-disabled) : null}})()")

        if disabled is not None and disabled != "true":
            await evaluate(f"(()=>{{const b=document.querySelector({selector_js});if(b)b.click();return !!b}})()")
            print("YouTube " + ("Previous" if action == "prev" else "Next") + " clicked.")
            return

        if action == "next":
            print("YouTube Next is unavailable for this video.")
            return

        history = await request("Page.getNavigationHistory", session=sid)
        entries = history.get("entries", [])
        index = history.get("currentIndex", 0)
        if index < 1:
            print("No previous browser-history entry.")
            return

        previous_url = entries[index - 1].get("url", "")
        parsed = urlsplit(previous_url)
        if (parsed.hostname or "").endswith("youtube.com") and parsed.path == "/watch":
            await request("Page.navigate", {"url": previous_url}, sid)
            print("Returned to the previous YouTube video in browser history.")
        else:
            print("Previous is disabled, and the previous history entry is not a YouTube watch page.")

asyncio.run(main())
