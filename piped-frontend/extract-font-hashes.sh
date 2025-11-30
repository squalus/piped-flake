#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl nix

fonts=($(grep -hPo "https://fonts\.gstatic\.com/s[^)]*" -r node_modules/ | sort | uniq))
echo '{'
for font in "${fonts[@]}"; do
    hash=$(nix-hash --to-sri --type sha256 $(nix-prefetch-url "$font" 2>/dev/null))
    if [ "$font" = "${fonts[-1]}" ]; then
        echo '  "'"$font"'"': '"'"$hash"'"'
    else
        echo '  "'"$font"'"': '"'"$hash"'",'
    fi
done
echo '}'
