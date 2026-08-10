#!/usr/bin/env python3
import argparse
import os
import subprocess
import sys

import gi
gi.require_version("Gtk", "4.0")
from gi.repository import Gtk, Gdk, Gio  # noqa: E402

APP_ID = "com.translateonthego.review"


def read_file(path: str) -> str:
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def wl_copy(text: str) -> None:
    p = subprocess.Popen(["wl-copy"], stdin=subprocess.PIPE)
    p.communicate(input=text.encode("utf-8"))


def notify(body: str, urgency: str = "normal", timeout_ms: int = 2500) -> None:
    subprocess.Popen(
        [
            "notify-send",
            "-u", urgency,
            "-t", str(timeout_ms),
            "TranslateOnTheGo",
            body,
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


class ReviewWindow(Gtk.ApplicationWindow):
    def __init__(self, app, action, original, result):
        super().__init__(application=app, title=f"TranslateOnTheGo — {action}")
        self.set_default_size(720, 520)

        main = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        main.set_margin_top(10)
        main.set_margin_bottom(10)
        main.set_margin_start(12)
        main.set_margin_end(12)
        self.set_child(main)

        main.append(self._label("Original", dim=True))
        main.append(self._scrolled(self._textview(original, editable=False), 120))

        main.append(self._label(f"{action} Result (editable)", dim=True))
        self.result_buf = Gtk.TextBuffer()
        self.result_buf.set_text(result)
        result_view = Gtk.TextView(buffer=self.result_buf)
        result_view.set_wrap_mode(Gtk.WrapMode.WORD_CHAR)
        result_view.set_monospace(False)
        main.append(self._scrolled(result_view, 260))

        hint = Gtk.Label(
            label="Result will be copied to clipboard. Paste with Ctrl+V (or Ctrl+Shift+V in terminals).",
            xalign=0,
            wrap=True,
        )
        hint.add_css_class("dim-label")
        main.append(hint)

        btns = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        btns.set_halign(Gtk.Align.END)

        close_btn = Gtk.Button(label="Cancel")
        close_btn.connect("clicked", lambda *_: self.close())
        btns.append(close_btn)

        copy_btn = Gtk.Button(label="Copy to Clipboard")
        copy_btn.add_css_class("suggested-action")
        copy_btn.connect("clicked", self.on_copy)
        btns.append(copy_btn)

        main.append(btns)

        key = Gtk.EventControllerKey()
        key.connect("key-pressed", self.on_key)
        self.add_controller(key)

    @staticmethod
    def _label(text, dim=False):
        lbl = Gtk.Label(label=text, xalign=0)
        if dim:
            lbl.add_css_class("dim-label")
        return lbl

    @staticmethod
    def _textview(text, editable=True):
        buf = Gtk.TextBuffer()
        buf.set_text(text)
        tv = Gtk.TextView(buffer=buf)
        tv.set_editable(editable)
        tv.set_cursor_visible(editable)
        tv.set_wrap_mode(Gtk.WrapMode.WORD_CHAR)
        return tv

    @staticmethod
    def _scrolled(child, min_h):
        sw = Gtk.ScrolledWindow()
        sw.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        sw.set_min_content_height(min_h)
        sw.set_vexpand(True)
        sw.set_child(child)
        return sw

    def _current_result(self) -> str:
        start, end = self.result_buf.get_bounds()
        return self.result_buf.get_text(start, end, True)

    def on_copy(self, *_):
        wl_copy(self._current_result())
        notify("Copied — press Ctrl+V to paste")
        self.close()

    def on_key(self, _c, keyval, _kc, state):
        ctrl = bool(state & Gdk.ModifierType.CONTROL_MASK)
        if keyval == Gdk.KEY_Escape:
            self.close()
            return True
        if keyval in (Gdk.KEY_Return, Gdk.KEY_KP_Enter) and ctrl:
            self.on_copy()
            return True
        return False


class App(Gtk.Application):
    def __init__(self, args):
        super().__init__(application_id=APP_ID, flags=Gio.ApplicationFlags.NON_UNIQUE)
        self.args = args

    def do_activate(self):
        original = read_file(self.args.original_file)
        result = read_file(self.args.result_file)
        win = ReviewWindow(self, self.args.action, original, result)
        win.present()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--action", required=True)
    ap.add_argument("--original-file", required=True)
    ap.add_argument("--result-file", required=True)
    args = ap.parse_args()

    try:
        app = App(args)
        rc = app.run([])
    finally:
        for p in (args.original_file, args.result_file):
            try:
                os.unlink(p)
            except OSError:
                pass
    sys.exit(rc)


if __name__ == "__main__":
    main()
