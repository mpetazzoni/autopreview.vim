# autopreview.vim

Autopreview (`autopreview.vim`) is a Vim plugin that automatically
renders and serves a Markdown buffer as a live-updating HTML view in
your browser. It uses a small server, written in Go, which serves a
static HTML page with some Javascript and WebSocket magic to receive
live updates of the buffer contents from the server. Whenever you modify
your Vim buffer, Autopreview pushes the new contents to the server which
then sends it down to the web page.

## Installation

The Autopreview server component is written in Go and is built with
[`gb`](https://getgb.io). If you don't have `gb`, you can install it
with:

```
$ go get github.com/constabulary/gb/...
```

Then, to install the plugin and build the server (assuming you use
Pathogen):

```
$ git clone https://github.com/mpetazzoni/autopreview.vim ~/.vim/bundle/
$ cd ~/.vim/bundle/autopreview.vim/server/
$ gb build
```

## Usage

To enable the live preview, simply call `:Autopreview` in your buffer.
For best results, make sure you do that in a Markdown buffer :-) You
should see a message in Vim's message window with the URL to open in
your browser:

```
Started Autopreview at http://localhost:5555/
```

If you want to enable Autopreview automatically when you open a Markdown
file, add the following line to your Vimrc:

```viml
au BufNewFile,BufEnter *.md call autopreview#autopreview()
```

## Configuration

### `g:autopreview_slow_refresh`

When set to `1`, Autopreview will be less aggressive in sending buffer
updates to the Autopreview server. This might be useful if you're
experiencing performance issues in Vim with Autopreview enabled.

When operating in slow refresh mode, Autopreview will only update the
live preview when you enter the buffer, save the file or after a few
seconds of inactivity (in `INSERT` mode).

### `g:autopreview_server_url`

Set this variable to override the Autopreview server URL. Note that the
server started automatically by the plugin listens on `localhost:5555`,
which is also the default value for this configuration parameter.

### `g:autopreview_server_path`

Overrides the path to the server's executable. Defaults to `<plugin
path>/../server/server`.
