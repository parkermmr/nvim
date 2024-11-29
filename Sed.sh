sed -E ':a; /example=.*\)$/!{N; ba}; s/example=(.*)\)/examples=[\1])/' your_file.txt
