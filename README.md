# [rsp-rood-template](https://roodjong.github.io/rsp-rood-template)

Social media template website for RSP and ROOD.
Allows the user to modify text, images, and logos according to the visual identity of these organisations, and download the resulting image.

## Development

The templates are written in PureScript using the [sjablong](https://github.com/splintersuidman/sjablong) library.
The slanted and rotated text box, characteristic of the style of RSP and ROOD, is implemented in [`RspRood.Layer.TextBox`](https://github.com/roodjong/rsp-rood-template/blob/master/src/RspRood/Layer/TextBox.purs).

To build the project, a [justfile](https://github.com/roodjong/rsp-rood-template/blob/master/src/RspRood/Layer/TextBox.purs) is provided.
The command `just build` will build all the templates.
Alternatively, a single template can be built with `just build-template <template name>`.

The dependencies are conveniently organised in a [Nix flake](https://github.com/roodjong/rsp-rood-template/blob/master/flake.nix): with [Nix](https://nixos.org/download) installed, the command `nix develop` will start a shell with the necessary dependencies in the environment.
Alternatively, the dependencies can also be installed using your favourite package manager.

The Nix flake is also used to build the templates in CI, which then deploys the site to GitHub Pages.
