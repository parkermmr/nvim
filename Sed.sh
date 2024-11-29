sed -E '/^example=/ {
    :a
    $!{
        N
        /\)$/!ba
    }
    s/^example=(.*\))$/examples=[\1])/
}' your_file.txt
