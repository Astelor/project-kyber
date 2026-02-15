# Data verification with Jupyter notebook

Running Jupyter notebook in **VScode**, you can setup your own thing if it works for you. :P

# Preliminary

- A **Jupyter notebook** environment
- `pip install ipynb` for cross notebook function import
- `pip install matplotlib`: for plots in `compress.ipynb`

# How to use

1. Find `save_mem.do` in `quartus/simulation/modelsim/`.
2. Find `checking.ipynb` in `jupyter`.
3. Run the simulation until it reaches the memory result that you want to verify.
4. Issue `do save_mem.do` in **ModelSim**.
5. Run the cell designed to check the desired memory result in `checking.ipynb`.

# Structure

- **Kyber in Python**: translated from the C implementation for the ease of data check
- **Does what it says on the tin**: yep
```
📦jupyter
 ┣ 📜checking.ipynb 
 ┣ 📜pke_keygen.ipynb
 ┣ 📜test.ipynb
 ┣ 📜encode.ipynb
 ┣ 📜compress.ipynb
 ┣ 📜decompress.ipynb
 ┣ 📜cbd2.ipynb
 ┣ 📜matrix_hash.ipynb
 ┣ 📜ntt_invntt.ipynb
 ┣ 📜polyvec.ipynb
 ┣ 📜zetas.py
 ┗ 📜README.md
```