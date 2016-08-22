# vim-split-search
Easily run grep/ack/ag in a new vim window

## Usage

    :Ack foo|bar     ->   ack 'foo|bar'
    :Ag -w someword  ->   ag -w someword
    :Grep don't      ->   grep -rin "don't" *

