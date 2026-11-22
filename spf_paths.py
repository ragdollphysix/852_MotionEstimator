#!/usr/bin/env python3
"""spf_paths.py : port-to-cell-pin resistance of the supply nets in a StarRC DSPF file.

Usage:  python3 spf_paths.py results/top_supply.spf [outdir]

For each net (VDD, VSS) it
  1. reads the port, the cell pins (*|I lines, with x/y) and every resistor,
  2. runs Dijkstra from the port over the resistor graph,
  3. writes <outdir>/<net>_pin_resistance.csv and a heat-map PNG,
  4. prints a summary and the worst pins.
"""
import csv
import heapq
import os
import sys
from collections import defaultdict


def parse_spf(path):
    adj = defaultdict(list)      # node -> [(neighbour, ohms)]
    ports = {}                   # net -> (port_node, x, y)
    pins = defaultdict(list)     # net -> [(pin_node, instance, x, y)]
    cap_total = {}               # net -> total cap string from *|NET
    counts = defaultdict(lambda: {"R": 0, "C": 0})
    net = None

    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            if line.startswith("*|NET"):
                parts = line.split()
                net = parts[1]
                cap_total[net] = parts[2] if len(parts) > 2 else "?"

            elif line.startswith("*|P") and net:
                t = line[line.index("(") + 1:line.rindex(")")].split()
                # (name type cap x y)
                ports[net] = (t[0], float(t[3]), float(t[4]))

            elif line.startswith("*|I") and net:
                t = line[line.index("(") + 1:line.rindex(")")].split()
                # (pin_node instance pin type cap x y)
                pins[net].append((t[0], t[1], float(t[5]), float(t[6])))

            elif line[0] == "R" and net:
                t = line.split()
                try:
                    ohms = float(t[3])
                except (IndexError, ValueError):
                    continue
                adj[t[1]].append((t[2], ohms))
                adj[t[2]].append((t[1], ohms))
                counts[net]["R"] += 1

            elif line[0] == "C" and net:
                counts[net]["C"] += 1

    return adj, ports, pins, cap_total, counts


def dijkstra(adj, source):
    dist = {source: 0.0}
    heap = [(0.0, source)]
    while heap:
        d, u = heapq.heappop(heap)
        if d > dist.get(u, float("inf")):
            continue
        for v, w in adj.get(u, ()):
            nd = d + w
            if nd < dist.get(v, float("inf")):
                dist[v] = nd
                heapq.heappush(heap, (nd, v))
    return dist


def plot(net, rows, port, outpath):
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except ImportError:
        print("  (matplotlib not installed, skipping plot: pip install --user matplotlib)")
        return
    xs = [r[2] for r in rows]
    ys = [r[3] for r in rows]
    cs = [r[4] for r in rows]
    fig, ax = plt.subplots(figsize=(7, 6))
    sc = ax.scatter(xs, ys, c=cs, s=8, cmap="viridis")
    fig.colorbar(sc, label="resistance from port (ohm)")
    ax.scatter([port[1]], [port[2]], c="red", marker="*", s=150, label="port")
    ax.set_title(f"{net}: port-to-pin resistance")
    ax.set_xlabel("x")
    ax.set_ylabel("y")
    ax.set_aspect("equal")
    ax.legend()
    fig.savefig(outpath, dpi=150, bbox_inches="tight")
    plt.close(fig)
    print(f"  plot -> {outpath}")


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    spf = sys.argv[1]
    outdir = sys.argv[2] if len(sys.argv) > 2 else "."
    os.makedirs(outdir, exist_ok=True)

    adj, ports, pins, cap_total, counts = parse_spf(spf)

    for net in pins:
        print(f"\n=== {net} ===")
        print(f"  resistors: {counts[net]['R']}   caps: {counts[net]['C']}   "
              f"total cap (header): {cap_total.get(net)}   cell pins: {len(pins[net])}")
        if net not in ports:
            print("  no *|P port line found, skipping")
            continue
        port = ports[net]
        dist = dijkstra(adj, port[0])

        rows, missing = [], 0
        for node, inst, x, y in pins[net]:
            if node in dist:
                rows.append((node, inst, x, y, dist[node]))
            else:
                missing += 1
        if missing:
            print(f"  WARNING: {missing} pins not reachable from the port "
                  f"(their node names are not in any R line)")
        if not rows:
            continue

        csv_path = os.path.join(outdir, f"{net}_pin_resistance.csv")
        with open(csv_path, "w", newline="") as f:
            w = csv.writer(f)
            w.writerow(["pin_node", "instance", "x", "y", "ohms_from_port"])
            w.writerows(sorted(rows, key=lambda r: -r[4]))
        print(f"  csv  -> {csv_path}")

        vals = [r[4] for r in rows]
        print(f"  ohms from port: min {min(vals):.3f}  "
              f"mean {sum(vals)/len(vals):.3f}  max {max(vals):.3f}")
        print("  worst 10 pins:")
        for r in sorted(rows, key=lambda r: -r[4])[:10]:
            print(f"    {r[0]:<22} {r[4]:8.3f} ohm   at ({r[2]:.1f}, {r[3]:.1f})")

        plot(net, rows, port, os.path.join(outdir, f"{net}_resistance_map.png"))


if __name__ == "__main__":
    main()