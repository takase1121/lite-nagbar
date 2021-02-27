# lite-nagbar
nagbar for lite. Inspired by i3-nagbar.

This is a work in progress.

### Installation
- for lite users, just download and place `init.lua` into your `plugins` directory as `nagbar.lua`
- for `lite-xl` users, download `init.xl.lua` instead

### Limitations
- This plugin cannot replace system.show_confirm_dialog(). This is because the function is inherently synchronous (It pauses the entire lua runtime). Nagbar **cannot** pause the runtime because it needs to continue rendering and accepting input.
- for the lite-xl version to work "properly", debug functions are used to perform some magic. The code can get convoluted or not work at all. If you have ideas on how to fix that, please open a PR.