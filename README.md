# lite-nagbar
nagbar for lite. Inspired by i3-nagbar.

This is a work in progress.

### Limitations
- This plugin cannot replace system.show_confirm_dialog(). This is because the function is inherently synchronous (It pauses the entire lua runtime). Nagbar **cannot** pause the runtime because it needs to continue rendering and accepting input.