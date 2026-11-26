"""Check website failures without a network or a database."""

import importlib.util
import io
import math
from pathlib import Path
import runpy
import sys
from contextlib import redirect_stdout
from types import ModuleType, SimpleNamespace
import unittest
from unittest.mock import Mock, patch


APP_PATH = Path(__file__).resolve().parents[1] / "my-python-app" / "my-test.py"


class WebsiteCheckTests(unittest.TestCase):
    def setUp(self):
        requests = ModuleType("requests")
        requests.get = Mock(return_value=SimpleNamespace(status_code=200))
        requests.exceptions = SimpleNamespace(RequestException=OSError)
        mysql = ModuleType("mysql")
        connector = ModuleType("mysql.connector")
        connector.connect = Mock()
        connector.connect.return_value.cursor.return_value.fetchall.return_value = []
        mysql.connector = connector
        self.clients = {"requests": requests, "mysql": mysql, "mysql.connector": connector}
        with patch.dict(sys.modules, self.clients):
            spec = importlib.util.spec_from_file_location("course_app", APP_PATH)
            self.app = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(self.app)

    def test_connection_failure_propagates(self):
        self.app.requests.get.side_effect = OSError("Simulated DNS failure")
        with redirect_stdout(io.StringIO()), self.assertRaises(OSError):
            self.app.check_website("https://example.com")

    def test_timeout_propagates(self):
        self.app.requests.get.side_effect = TimeoutError("Simulated timeout")
        with redirect_stdout(io.StringIO()), self.assertRaises(TimeoutError):
            self.app.check_website("https://example.com")

    def test_request_has_a_finite_timeout(self):
        with redirect_stdout(io.StringIO()):
            self.app.check_website("https://example.com")
        timeout = self.app.requests.get.call_args.kwargs.get("timeout")
        self.assertIsInstance(timeout, (int, float))
        self.assertGreater(timeout, 0)
        self.assertTrue(math.isfinite(timeout))

    def test_main_stops_before_database_after_request_failure(self):
        self.app.requests.get.side_effect = OSError("Simulated DNS failure")
        with patch.dict(sys.modules, self.clients), redirect_stdout(io.StringIO()):
            with self.assertRaises(OSError):
                runpy.run_path(str(APP_PATH), run_name="__main__")
        self.app.db.connect.assert_not_called()

    def test_http_error_fails_the_check(self):
        self.app.requests.get.return_value.status_code = 503
        with redirect_stdout(io.StringIO()), self.assertRaises(AssertionError):
            self.app.check_website("https://example.com")


if __name__ == "__main__":
    unittest.main()
