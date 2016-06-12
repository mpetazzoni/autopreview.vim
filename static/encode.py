#!/usr/bin/env python

import argparse
import base64
import zlib


_template = """package main

import (
\t"bytes"
\t"compress/zlib"
\t"encoding/base64"
\t"io"
)

var _{name} = []byte(`
{encoded}
`)

func {name}() (io.Reader, error) {{
\tb64 := base64.NewDecoder(base64.StdEncoding, bytes.NewReader(_{name}))
\treturn zlib.NewReader(b64)
}}
"""  # noqa

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-s', '--src', type=argparse.FileType('rb'),
                        default='-', help='source file to encode')
    parser.add_argument('-d', '--dst', type=argparse.FileType('w+'),
                        default='-', help='target Go file')
    parser.add_argument('name')
    options = parser.parse_args()

    encoded = base64.encodestring(zlib.compress(options.src.read())).strip()
    options.dst.write(_template.format(name=options.name.title(),
                                       encoded=encoded))
