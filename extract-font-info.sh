for f in "$@"; do
    family=$(fc-scan --format="%{family}\n" "$f" | head -1)
    base=$(printf '%s' "$family" | tr '[:upper:]' '[:lower:]')
    case "${f##*.}" in
        ttf)   format=truetype; mimetype=font/ttf ;;
        otf)   format=opentype; mimetype=font/otf ;;
        woff)  format=woff;     mimetype=font/woff ;;
        woff2) format=woff2;    mimetype=font/woff2 ;;
    esac
    cat <<EOF
- path: $f
  family: ${family}-local
  alternativename: ${base}-local
  format: $format
  mimetype: $mimetype
EOF
done