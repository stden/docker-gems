"""Check metadata validation, publication, and safe API failures without network access."""

import io
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from urllib.error import HTTPError

import hub_metadata as hub


class HubMetadataTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "demo").mkdir()
        (self.root / "demo" / "Dockerfile").touch()
        self.readme = self.root / "demo" / "README.md"
        self.readme.write_text(
            "# stden/demo\n\nBuild sample documents.\n\n## Use\n\nSample text.\n"
        )
        self.categories = {"demo": ["developer-tools"]}

    def test_description_and_overview_come_from_readme(self):
        payload = hub.load_metadata(self.root, "demo", self.categories)
        self.assertEqual(payload["description"], "Build sample documents.")
        self.assertEqual(payload["full_description"], self.readme.read_text())
        self.assertEqual(payload["categories"], [{"slug": "developer-tools"}])

    def test_invalid_documents_fail_before_publication(self):
        for content in (
            "",
            "# Wrong title\n\nText.\n",
            "# stden/demo\n\n" + "a" * 101,
            "# stden/demo\n\nShort.\n\n" + "a" * 25000,
        ):
            with self.subTest(content=content[:30]):
                self.readme.write_text(content)
                with self.assertRaises(ValueError):
                    hub.load_metadata(self.root, "demo", self.categories)

    def test_invalid_categories_fail_before_publication(self):
        for categories in (
            [],
            ["developer-tools"] * 2,
            ["a", "b", "c", "d"],
            ["Bad slug"],
        ):
            with self.subTest(categories=categories):
                with self.assertRaises(ValueError):
                    hub.load_metadata(self.root, "demo", {"demo": categories})

    def test_request_encodes_json_and_authorization(self):
        with patch.object(
            hub, "urlopen", return_value=io.BytesIO(b'{"ok": true}')
        ) as opened:
            self.assertEqual(
                hub.request("PATCH", "/example", {"text": "A\nB"}, "test-token"),
                {"ok": True},
            )
        request = opened.call_args.args[0]
        self.assertEqual(request.get_header("Authorization"), "Bearer test-token")
        self.assertEqual(json.loads(request.data), {"text": "A\nB"})
        self.assertEqual(opened.call_args.kwargs["timeout"], 30)

    def test_permission_error_does_not_expose_response_body(self):
        failure = HTTPError(
            hub.API_URL + "/example",
            403,
            "Forbidden",
            {},
            io.BytesIO(b"secret-response-content"),
        )
        with (
            patch.object(hub, "urlopen", side_effect=failure),
            patch.object(hub.time, "sleep") as sleep,
        ):
            with self.assertRaisesRegex(RuntimeError, "HTTP 403") as caught:
                hub.request("PATCH", "/example", {}, "test-token")
        self.assertNotIn("secret-response-content", str(caught.exception))
        sleep.assert_not_called()

    def test_rate_limit_has_bounded_retries(self):
        failure = HTTPError(
            hub.API_URL + "/example", 429, "Too Many Requests", {}, None
        )
        with (
            patch.object(hub, "urlopen", side_effect=failure) as opened,
            patch.object(hub.time, "sleep"),
        ):
            with self.assertRaisesRegex(RuntimeError, "HTTP 429"):
                hub.request("GET", "/example")
        self.assertEqual(opened.call_count, 3)

    def test_api_reason_redacts_credentials(self):
        body = json.dumps(
            {"message": "Denied bearer-value and pat-value.\nCheck access."}
        ).encode()
        failure = HTTPError(
            hub.API_URL + "/example", 403, "Forbidden", {}, io.BytesIO(body)
        )
        with (
            patch.object(hub, "urlopen", side_effect=failure),
            patch.dict(hub.os.environ, {"DOCKER_HUB_TOKEN": "pat-value"}),
        ):
            with self.assertRaises(RuntimeError) as caught:
                hub.request("PATCH", "/example", {}, "bearer-value")
        message = str(caught.exception)
        self.assertIn("Denied [redacted] and [redacted]. Check access.", message)
        self.assertNotIn("bearer-value", message)
        self.assertNotIn("pat-value", message)

    def test_authentication_error_body_is_never_logged(self):
        failure = HTTPError(
            hub.API_URL + "/v2/auth/token",
            403,
            "Forbidden",
            {},
            io.BytesIO(b'{"message": "secret-login-content"}'),
        )
        with patch.object(hub, "urlopen", side_effect=failure):
            with self.assertRaises(RuntimeError) as caught:
                hub.request(
                    "POST", "/v2/auth/token", {"secret": "secret-login-content"}
                )
        self.assertNotIn("secret-login-content", str(caught.exception))

    def test_publication_checks_saved_categories_and_full_text(self):
        payload = hub.load_metadata(self.root, "demo", self.categories)
        payload["categories"][0]["name"] = "Developer tools"
        saved = dict(
            payload, categories=[{"slug": "developer-tools", "name": "Developer tools"}]
        )
        with patch.object(hub, "request", side_effect=[{}, {}, saved]) as request:
            hub.publish("stden", "demo", payload, "test-token")
        self.assertEqual(
            request.call_args_list[0].args,
            (
                "PATCH",
                "/v2/namespaces/stden/repositories/demo",
                {
                    "description": payload["description"],
                    "full_description": payload["full_description"],
                },
                "test-token",
            ),
        )
        self.assertEqual(
            request.call_args_list[1].args,
            (
                "PATCH",
                "/v2/namespaces/stden/repositories/demo/categories",
                [{"slug": "developer-tools", "name": "Developer tools"}],
                "test-token",
            ),
        )
        self.assertEqual(request.call_args_list[2].args[0], "GET")

    def test_rate_limit_uses_server_retry_delay(self):
        failure = HTTPError(
            hub.API_URL + "/example",
            429,
            "Too Many Requests",
            {"Retry-After": "30"},
            None,
        )
        with (
            patch.object(hub, "urlopen", side_effect=[failure, io.BytesIO(b"{}")]),
            patch.object(hub.time, "sleep") as sleep,
        ):
            hub.request("GET", "/example")
        sleep.assert_called_once_with(30)

    def test_ignored_update_fails_verification(self):
        payload = hub.load_metadata(self.root, "demo", self.categories)
        for field, value in (
            ("description", "Old"),
            ("full_description", "Old"),
            ("categories", []),
        ):
            with self.subTest(field=field):
                saved = dict(payload, **{field: value})
                with patch.object(hub, "request", side_effect=[{}, {}, saved]):
                    with self.assertRaisesRegex(RuntimeError, "did not save"):
                        hub.publish("stden", "demo", payload, "test-token")


if __name__ == "__main__":
    unittest.main()
