# todo
- [ ] swap the constants to something more readable
  - "QINV" to -3327
  - "KYBER_Q" to 3329
  - > maybe later
- [ ] make an actual testing anvironment
  - is there a better way to write test benches other than stacking lines of things??
- > okay I am incredibly confused about the **timing issue** and **buffering issue**
  - > if there are any to be concerned about
- I think I need to use buffer for the clock to make pipelines work I think??
  - how else did they make an output on a negedge??
  - > there's no way a ASIC engineer is not paid heftly with all these ~~bullshit~~ to deal with

# uh
- make it write to a file so I can diff it
  - what format do I wanna use tho
  - `("%d %d\n", input, output)` I guess
- **why the heck am I worrying about writing the test bruh**
- `>:(`

# timing
- is there a better way to handle submodule timings?
  - **YES, use clocks you dummy**
  - > `#delays` are *not synthesizable*, do not write them in modules other than testbenches

# memory
- technically the **zetas** should be placed in a ROM, no copies lying around in the modules
  - [ ] how to make a ROM
    - [ ] how do I read from the same instance accross all modules?
      - is it a top level module handled thing, if so the `kyber.v` would handle this 
  - [ ] how to make a RAM
- [ ] using ``define` to mark file reading init (I am using absolute path because Quartus never finds the relative path)
  - > I think the IDE can read the file as long as it's logged in the project 
- I think the NTT module will not work without an actual RAM or cache or register strcuture that does not shit itself
  - or at the very least working
  - I might actually need to contruc the levels instead of trying to build a silver bullet
  - > this is the most difficult part of the scheme, trust :>
  - Quartus synthesized the `poly_ram` module into a giant blob of DFFs
    - don't know if it's going to cause a problem, but for now, it works

# NTT

- do I pipeline the data and make it propagate through the modules
  - the former would enable more pipelining and through-put
    - and potentially cause security issues >:(
  - the latter is slightly easier to design I guess?
