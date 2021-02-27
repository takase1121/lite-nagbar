# lite-nagbar
nagbar for lite. Inspired by i3-nagbar.

This is a work in progress.

### Installation
- for lite users, just download and place `init.lua` into your `plugins` directory as `nagbar.lua`
- for `lite-xl` users, download `init.xl.lua` instead

### Limitations
- debug functions are used to do a lot of magic.
- lite-xl version does not replace `system.show_confirm_dialog()` _yet._
- for the lite-xl version to work "properly", debug functions are used to perform some magic. The code can get convoluted or not work at all. If you have ideas on how to fix that, please open a PR.