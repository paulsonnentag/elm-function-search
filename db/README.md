## Schema

```
(:Repo)-[:HAS_FILE]->(:File)
(:File)-[:REFERENCES_SYMBOL]->(:Symbol)
(:File)-[:DEFINES_SYMBOL]->(:Symbol)  
```

