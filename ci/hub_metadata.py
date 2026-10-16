"""Publish an image README and search categories to Docker Hub."""

import argparse
import json
import os
import re
import sys
import time
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

API_URL = "https://hub.docker.com"
ROOT = Path(__file__).resolve().parents[1]


def rejection_reason(error, token):
    try:
        body = json.loads(error.read(4096))
    except (ValueError, OSError):
        return ""
    if not isinstance(body, dict):
        return ""
    message = body.get("message") or body.get("detail")
    if not isinstance(message, str):
        return ""
    for secret in (token, os.environ.get("DOCKER_HUB_TOKEN")):
        if secret:
            message = message.replace(secret, "[redacted]")
    return " ".join(message.split())[:300]


def request(method, path, payload=None, token=None):
    headers = {"Accept": "application/json", "Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    data = None if payload is None else json.dumps(payload).encode()
    api_request = Request(API_URL + path, data=data, headers=headers, method=method)
    for attempt in range(3):
        delay = attempt + 1
        try:
            with urlopen(api_request, timeout=30) as response:
                body = response.read()
            return json.loads(body) if body else {}
        except HTTPError as error:
            message = f"Docker Hub {method} {path}: HTTP {error.code}."
            if path != "/v2/auth/token":
                reason = rejection_reason(error, token)
                if reason:
                    message += f" {reason}"
            if error.code in (401, 403):
                message += " Check DOCKER_HUB_TOKEN and repository access."
            if error.code not in (429, 500, 502, 503, 504) or attempt == 2:
                raise RuntimeError(message) from None
            retry_after = error.headers.get("Retry-After", "")
            if retry_after.isdigit():
                delay = min(60, max(delay, int(retry_after)))
        except (URLError, TimeoutError):
            if attempt == 2:
                raise RuntimeError(
                    f"Docker Hub {method} {path}: connection failed."
                ) from None
        time.sleep(delay)


def load_metadata(root, image, categories):
    text = (root / image / "README.md").read_text(encoding="utf-8")
    paragraphs = text.split("\n\n")
    if len(paragraphs) < 2 or paragraphs[0] != f"# stden/{image}":
        raise ValueError(
            f"{image}: start README.md with the image title and a short description."
        )
    description = paragraphs[1].strip()
    if not description or "\n" in description or len(description.encode()) > 100:
        raise ValueError(
            f"{image}: the description must be one line of 1 to 100 bytes."
        )
    if len(text.encode()) > 25000:
        raise ValueError(
            f"{image}: the overview exceeds the Docker Hub limit of 25000 bytes."
        )
    selected = categories[image]
    if not isinstance(selected, list) or not 1 <= len(selected) <= 3:
        raise ValueError(f"{image}: select one to three Docker Hub categories.")
    if any(
        not isinstance(slug, str) or not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", slug)
        for slug in selected
    ) or len(set(selected)) != len(selected):
        raise ValueError(f"{image}: category slugs must be valid and unique.")
    return {
        "description": description,
        "full_description": text,
        "categories": [{"slug": slug} for slug in selected],
    }


def publish(username, image, payload, token):
    path = f"/v2/namespaces/{username}/repositories/{image}"
    overview = {field: payload[field] for field in ("description", "full_description")}
    request("PATCH", path, overview, token)
    # Categories use a separate endpoint and a top-level array of full category objects.
    request("PATCH", f"{path}/categories", payload["categories"], token)
    saved = request("GET", path, token=token)
    for field in ("description", "full_description"):
        if saved.get(field) != payload[field]:
            raise RuntimeError(f"{image}: Docker Hub did not save {field}.")
    expected = {category["slug"] for category in payload["categories"]}
    actual = {category["slug"] for category in saved.get("categories", [])}
    if actual != expected:
        raise RuntimeError(f"{image}: Docker Hub did not save the search categories.")
    print(f"\033[1;32mOVERVIEW SAVED: {username}/{image}\033[0m")
    print(f"Categories: {', '.join(sorted(actual))}")
    print(f"Overview: {API_URL}/r/{username}/{image}")
    print(f"Tags: {API_URL}/r/{username}/{image}/tags")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("image", nargs="?")
    parser.add_argument(
        "--check",
        action="store_true",
        help="check all local metadata, but do not publish it",
    )
    args = parser.parse_args()
    categories = json.loads(
        (ROOT / "ci/hub-categories.json").read_text(encoding="utf-8")
    )
    images = {path.parent.name for path in ROOT.glob("*/Dockerfile")}
    if set(categories) != images:
        raise ValueError(
            "hub-categories.json must contain exactly one entry for each image."
        )
    metadata = {
        image: load_metadata(ROOT, image, categories) for image in sorted(images)
    }
    if args.check:
        print(f"Checked overviews and categories for {len(metadata)} images.")
        return
    if args.image not in metadata:
        parser.error("select an image directory or use --check")
    username = os.environ.get("DOCKER_HUB_USERNAME", "stden")
    secret = os.environ.get("DOCKER_HUB_TOKEN")
    if username != "stden" or not secret:
        raise ValueError(
            "Set DOCKER_HUB_USERNAME=stden and the DOCKER_HUB_TOKEN secret."
        )
    available = {
        category["slug"]: category for category in request("GET", "/v2/categories/")
    }
    if not set(categories[args.image]) <= available.keys():
        raise ValueError(
            f"{args.image}: Docker Hub does not support a selected category."
        )
    metadata[args.image]["categories"] = [
        available[slug] for slug in categories[args.image]
    ]
    print(f"\033[1;36mOVERVIEW: {username}/{args.image}\033[0m", flush=True)
    login = request(
        "POST", "/v2/auth/token", {"identifier": username, "secret": secret}
    )
    token = login.get("access_token")
    if not token:
        raise RuntimeError("Docker Hub did not return an access token.")
    if os.environ.get("GITHUB_ACTIONS") == "true":
        print(f"::add-mask::{token}")
    repository = request(
        "GET", f"/v2/namespaces/{username}/repositories/{args.image}", token=token
    )
    access = repository.get("permissions", {})
    print(
        "Repository access: "
        + ", ".join(
            f"{name}={access.get(name)}" for name in ("read", "write", "admin")
        ),
        flush=True,
    )
    publish(username, args.image, metadata[args.image], token)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, RuntimeError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        sys.exit(1)
