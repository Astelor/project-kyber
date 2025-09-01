# TEST

- file names starting with `output` are in reverse order
  - indexing from 255 to 0
  - because modelsim's `mem display` prints memory in this order
- **files explicitly marked as reverse are in reverse order**
  - I think the current `ntt-256.txt` file is in reverse order but I can't tell
- use `dectohex.py` for converting data file in decimal to hexadecimal format for `$readmemh` use
