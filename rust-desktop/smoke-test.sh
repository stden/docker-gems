#!/usr/bin/env bash
set -euo pipefail

cargo tarpaulin --version
sccache --version
rustc --version
cargo --version
pkg-config --modversion gtk+-3.0 x11 xcb xcb-render xcb-shape xcb-xfixes

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
cd "$work_dir"
cargo init --lib --name rust_desktop_smoke --vcs none .
cat >src/lib.rs <<'RS'
pub fn add(left: u64, right: u64) -> u64 {
    left + right
}

#[test]
fn adds_two_numbers() {
    assert_eq!(add(20, 22), 42);
}
RS
cargo fmt --check
cargo clippy --offline --all-targets -- -D warnings
cargo test --offline
cargo tarpaulin --engine llvm --offline --out Stdout --fail-under 100

cat >window.c <<'C'
#include <gtk/gtk.h>

static gboolean window_was_shown = FALSE;

static gboolean close_window(gpointer window) {
    window_was_shown = gtk_widget_get_mapped(GTK_WIDGET(window));
    gtk_main_quit();
    return G_SOURCE_REMOVE;
}

int main(int argc, char **argv) {
    if (!gtk_init_check(&argc, &argv)) return 1;
    GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_title(GTK_WINDOW(window), "Rust desktop smoke test");
    gtk_widget_show_all(window);
    g_timeout_add(100, close_window, window);
    gtk_main();
    gtk_widget_destroy(window);
    return window_was_shown ? 0 : 1;
}
C
# pkg-config returns separate compiler and linker arguments.
# shellcheck disable=SC2046
cc -Wall -Werror window.c -o window $(pkg-config --cflags --libs gtk+-3.0)
timeout 20 xvfb-run -a ./window
printf 'Rust desktop smoke test passed.\n'
