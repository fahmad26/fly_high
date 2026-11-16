"""Extract script Source strings from a Roblox binary place (.rbxl). Pure Python (LZ4 block + zstd check).
Usage: python3 rbxl_sources.py place.rbxl outdir Name1 Name2 ...  -> writes <outdir>/<ClassName>.<Name>.luau
Instances whose ancestors start with "_QA" are ignored implicitly because only names are matched; duplicates are reported.
"""
import struct, sys, os


def lz4_block(src, size):
    dst = bytearray()
    i = 0
    n = len(src)
    while i < n:
        token = src[i]; i += 1
        lit = token >> 4
        if lit == 15:
            while True:
                b = src[i]; i += 1; lit += b
                if b != 255: break
        dst += src[i:i + lit]; i += lit
        if i >= n: break
        off = src[i] | (src[i + 1] << 8); i += 2
        ml = token & 15
        if ml == 15:
            while True:
                b = src[i]; i += 1; ml += b
                if b != 255: break
        ml += 4
        start = len(dst) - off
        for k in range(ml):
            dst.append(dst[start + k])
    assert len(dst) == size, (len(dst), size)
    return bytes(dst)


def chunks(data):
    assert data[:8] == b"<roblox!"
    pos = 32
    while pos < len(data):
        name = data[pos:pos + 4]
        clen, ulen, _ = struct.unpack("<III", data[pos + 4:pos + 16])
        pos += 16
        if clen == 0:
            body = data[pos:pos + ulen]; pos += ulen
        else:
            raw = data[pos:pos + clen]; pos += clen
            if raw[:4] == b"\x28\xb5\x2f\xfd":
                import subprocess
                body = subprocess.run(["zstd", "-d", "-c", "-q"], input=raw, capture_output=True, check=True).stdout
                assert len(body) == ulen
            else:
                body = lz4_block(raw, ulen)
        yield name, body
        if name == b"END\0":
            break


def read_strings(body, off, count):
    out = []
    for _ in range(count):
        ln = struct.unpack("<I", body[off:off + 4])[0]; off += 4
        out.append(body[off:off + ln]); off += ln
    return out


def deinterleave_ints(b, count):
    # referents: interleaved big-endian, zigzag, accumulated
    vals = []
    for i in range(count):
        v = (b[i] << 24) | (b[count + i] << 16) | (b[2 * count + i] << 8) | b[3 * count + i]
        v = (v >> 1) ^ -(v & 1)
        vals.append(v)
    acc = 0; res = []
    for v in vals:
        acc += v; res.append(acc)
    return res


def main():
    path, outdir, *wanted = sys.argv[1:]
    data = open(path, "rb").read()
    classes = {}
    props = {}
    parents = {}
    for name, body in chunks(data):
        if name == b"INST":
            cid, nlen = struct.unpack("<II", body[:8])
            cname = body[8:8 + nlen].decode()
            off = 8 + nlen + 1
            count = struct.unpack("<I", body[off:off + 4])[0]; off += 4
            refs = deinterleave_ints(body[off:off + 4 * count], count)
            classes[cid] = (cname, refs)
        elif name == b"PROP":
            cid, nlen = struct.unpack("<II", body[:8])
            pname = body[8:8 + nlen].decode()
            ptype = body[8 + nlen]
            off = 9 + nlen
            if pname in ("Name", "Source") and ptype == 1 and cid in classes:
                vals = read_strings(body, off, len(classes[cid][1]))
                for ref, v in zip(classes[cid][1], vals):
                    props.setdefault(ref, {})[pname] = v
        elif name == b"PRNT":
            count = struct.unpack("<I", body[1:5])[0]
            kids = deinterleave_ints(body[5:5 + 4 * count], count)
            pars = deinterleave_ints(body[5 + 4 * count:5 + 8 * count], count)
            parents.update(zip(kids, pars))
    cls_of = {}
    for cid, (cname, refs) in classes.items():
        for r in refs: cls_of[r] = cname

    def full(ref):
        parts = []
        while ref is not None and ref in props:
            parts.append(props[ref].get("Name", b"?").decode())
            ref = parents.get(ref)
            if ref == -1: break
        return ".".join(reversed(parts))

    os.makedirs(outdir, exist_ok=True)
    for want in wanted:
        hits = [r for r, p in props.items() if "Source" in p and full(r) == want]
        print(want, "matches", len(hits))
        for r in hits:
            src = props[r]["Source"]
            fn = os.path.join(outdir, want.replace("/", "_") + ".luau")
            open(fn, "wb").write(src)
            print("  wrote", fn, len(src))


if __name__ == "__main__":
    main()
