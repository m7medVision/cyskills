# Go/Rust notes

Go: first find `runtime.main` / `main.main`, recover via pclntab.  
Rust: first collect `src/` path strings and `Option`/`Result` handling blocks.  
Both: prefer string-driven analysis, avoid getting lost in the runtime libraries.
