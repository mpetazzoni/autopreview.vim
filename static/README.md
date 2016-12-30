# Encoding the static resources for Go

```
$ ./encode.py <name> < <source> > <dest.go>
```

This will provide a Go file expose a single public function `<name>`
(title-ized to be public) that returns an `io.Reader` over the bytes of
the resource. Internally, the resource data is stored as Base64-encoded
zlib-compressed data.

After encoding, you need to rebuild the server code.

```
$ ./encode index < index.html > ../server/src/server/static.go
$ cd ../server
$ gb build
```
