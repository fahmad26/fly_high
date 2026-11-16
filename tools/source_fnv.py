"""Length + FNV-1a 32 of a Luau source after CRLF->LF and trimEnd per line (matches the Studio parity check)."""
import sys
def fnv(b):
    s=b.decode('utf-8').replace('\r\n','\n')
    s='\n'.join(l.rstrip() for l in s.split('\n')).rstrip('\n')
    h=2166136261
    for c in s.encode('utf-8'):
        h^=c; h=(h*16777619)%2**32
    return len(s.encode('utf-8')),'%08x'%h
for p in sys.argv[1:]:
    print(p.split('/')[-1], *fnv(open(p,'rb').read()))
