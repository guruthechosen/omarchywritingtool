"""Exercise real jq/curl against loopback with synthetic text and credentials."""

from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import queue
import shutil
import subprocess
import tempfile
import threading
import unittest


REPO = Path(__file__).resolve().parents[1]
PROVIDERS = ("gemini", "ollama", "lmstudio")
TEXT = 'PRIVATE_SELECTION_SENTINEL: "quoted" \\ text\n한국어\n\n'
KEY = 'fixture-key-quote-"slash\\-only'


class ProviderPrivacyTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="tot-provider-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.commands = self.root / "bin"
        self.commands.mkdir()
        self.calls = self.root / "calls.jsonl"
        self.input = self.root / "selected text.txt"
        self.input.write_text(TEXT)
        self.input.chmod(0o600)
        self.requests = queue.Queue()
        self.release = threading.Event()
        self.response = {
            "candidates": [{"content": {"parts": [{"text": "Edited text"}]}}],
            "message": {"content": "Edited text"},
            "choices": [{"message": {"content": "Edited text"}}],
        }
        test = self

        class Handler(BaseHTTPRequestHandler):
            def do_POST(self):
                body = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
                test.requests.put((body, dict(self.headers)))
                test.release.wait(8)
                data = json.dumps(test.response).encode()
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(data)))
                self.end_headers()
                self.wfile.write(data)

            def log_message(self, *_args):
                pass

        self.server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        endpoint = f"http://127.0.0.1:{self.server.server_port}/request"
        self.env = {
            "HOME": str(self.root),
            "PATH": str(self.commands) + os.pathsep + os.defpath,
            "LANG": "C.UTF-8",
            "GEMINI_API_KEY": KEY,
            "OLLAMA_URL": endpoint,
            "LMSTUDIO_URL": endpoint,
            "OLLAMA_NUM_CTX": "6144",
            "OLLAMA_KEEP_ALIVE": "3m",
            "OLLAMA_NO_THINK": "true",
        }
        for command in ("jq", "curl"):
            binary = shutil.which(command)
            self.assertIsNotNone(binary, f"Tests require {command}")
            wrapper = self.commands / command
            wrapper.write_text(
                "#!/usr/bin/python3\nimport json, os, sys\n"
                f"with open({str(self.calls)!r}, 'a') as log:\n"
                f"    log.write(json.dumps({{'command': {command!r}, 'pid': os.getpid(), 'argv': sys.argv[1:]}}) + '\\n')\n"
                "args = sys.argv[1:]\n"
                # Route the fixed Gemini URL to loopback without changing production code.
                f"args = [{endpoint!r} if arg.startswith('https://generativelanguage.googleapis.com/') else arg for arg in args]\n"
                f"os.execv({binary!r}, [{binary!r}, *args])\n"
            )
            wrapper.chmod(0o755)

    def tearDown(self):
        self.release.set()
        self.server.shutdown()
        self.server.server_close()
        self.thread.join(timeout=5)

    def recorded_calls(self):
        return [json.loads(line) for line in self.calls.read_text().splitlines()]

    def request(self, provider, action="Correct", success=True):
        self.release.clear()
        proc = subprocess.Popen(
            ["bash", str(REPO / "lib" / f"{provider}.sh"), action, str(self.input)],
            env=self.env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
        )
        try:
            body, headers = self.requests.get(timeout=5)
            # curl is waiting for the HTTP response, so inspect its real Linux
            # process arguments as well as every captured jq/curl invocation.
            curl = [c for c in self.recorded_calls() if c["command"] == "curl"][-1]
            cmdline = Path(f"/proc/{curl['pid']}/cmdline").read_bytes().decode()
            self.assertNotIn(KEY, cmdline)
            self.assertNotIn("PRIVATE_SELECTION_SENTINEL", cmdline)
        finally:
            self.release.set()
            try:
                stdout, stderr = proc.communicate(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.communicate()
                raise
        for call in self.recorded_calls():
            argv = "\0".join(call["argv"])
            self.assertNotIn(KEY, argv)
            self.assertNotIn("PRIVATE_SELECTION_SENTINEL", argv)
        if success:
            self.assertEqual(proc.returncode, 0, stderr)
            self.assertEqual(stdout.strip(), "Edited text")
        else:
            self.assertNotEqual(proc.returncode, 0)
        if provider == "gemini":
            self.assertEqual(headers["x-goog-api-key"], KEY)
            selected = body["contents"][0]["parts"][0]["text"]
        else:
            self.assertNotIn("x-goog-api-key", headers)
            selected = body["messages"][1]["content"]
        self.assertEqual(selected, self.input.read_text())
        self.assertEqual(headers["Content-Type"], "application/json")
        return body, stderr

    def test_all_actions_and_providers_keep_secrets_out_of_argv(self):
        for provider in PROVIDERS:
            for action in ("Translate", "Proofread", "Correct"):
                with self.subTest(provider=provider, action=action):
                    body, _ = self.request(provider, action)
                    if provider == "ollama":
                        self.assertEqual(body["options"]["num_ctx"], 6144)
                        self.assertEqual(body["keep_alive"], "3m")
                        self.assertIs(body["think"], False)

    def test_large_selections_do_not_hit_process_argument_limits(self):
        self.input.write_text(TEXT * 5000)
        for provider in PROVIDERS:
            with self.subTest(provider=provider):
                self.request(provider)

    def test_provider_errors_still_propagate(self):
        self.response = {"error": {"message": "Fixture provider error"}}
        for provider in PROVIDERS:
            with self.subTest(provider=provider):
                _, stderr = self.request(provider, success=False)
                self.assertIn("Fixture provider error", stderr)

    def test_unreadable_input_does_not_send_a_request(self):
        self.input.unlink()
        for provider in PROVIDERS:
            with self.subTest(provider=provider):
                result = subprocess.run(
                    ["bash", str(REPO / "lib" / f"{provider}.sh"), "Correct", str(self.input)],
                    env=self.env, capture_output=True, text=True, timeout=5,
                )
                self.assertNotEqual(result.returncode, 0)
        self.assertTrue(self.requests.empty())
        self.assertFalse(any(c["command"] == "curl" for c in self.recorded_calls()))

    def test_gemini_rejects_header_injection(self):
        for separator in ("\r", "\n"):
            with self.subTest(separator=repr(separator)):
                self.env["GEMINI_API_KEY"] = KEY + separator + "Injected: header"
                result = subprocess.run(
                    ["bash", str(REPO / "lib/gemini.sh"), "Correct", str(self.input)],
                    env=self.env, capture_output=True, text=True, timeout=5,
                )
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("must not contain line breaks", result.stderr)
        self.assertTrue(self.requests.empty())


if __name__ == "__main__":
    unittest.main()
