import os
import re
from collections import defaultdict
import subprocess

def get_slack(report_file):
    if os.path.exists(report_file):
        with open(report_file, "r", encoding = "utf-8-sig") as file:
            for line in file:
                m = re.search(r"slack \((MET|VIOLATED)\)\s+(-?\d+\.\d+)", line)
                if m:
                    return float(m.group(2))
    else: 
        print("Path does not exist")

def get_area(report_file):
    if os.path.exists(report_file):
        with open(report_file, "r", encoding="utf-8-sig") as file:
            for line in file:
                if "total cell area" in line.lower():
                    print(line)
    else: 
        print("Path not found")

def get_power(report_file):
    if os.path.exists(report_file):
        with open(report_file, "r", encoding="utf-8-sig") as file:
            for line in file:
                if "total dynamic power" in line.lower() or "scenario:" in line.lower():
                    print(line)
    else: 
        print("Path not found")

def parse_log(log_file):
    warnings = defaultdict(list)
    errors = defaultdict(list)
    if os.path.exists(log_file):
        with open(log_file, "r", encoding="utf-8-sig") as file:
            for line in file:
                if "Warning:" in line[0:len("Warning:")]:
                    m = re.search(r"\(([A-Z]+-\d+)\)\s*$", line)
                    if m:
                        code = m.group(1)
                        warnings[code].append(line)
                if "Error:" in line[0:len("Error:")]:
                    m = re.search(r"\(([A-Z]+-\d+)\)\s*$", line)
                    if m:
                        code = m.group(1)
                        errors[code].append(line)
        print("Warnings: ")
        for code, line in warnings.items():
            print(f"{code}: {len(line)}")
        print("Errors: ")
        for code, line in errors.items():
            print(f"{code}: {len(line)}")
    else: 
        print("Path does not exist")

def run_stage(stage):
    result = subprocess.run(["make", "clean_" + stage])
    if result.returncode != 0:
        print(f"Clean failed (exit {result.returncode})")
        return
    result = subprocess.run(["make", "run_" + stage])
    parse_log("logs/" + stage + ".log")
    if result.returncode != 0:
        print(f"Run failed (exit {result.returncode})")
        return
    print(get_slack("reports/" + stage + "_report_timing_setup.rpt"))
    print(get_slack("reports/" + stage + "_report_timing_hold.rpt"))
    get_area("reports/" + stage + "_report_area.rpt")
    get_power("reports/" + stage + "_report_power.rpt")

run_stage("initial_syn")
run_stage("compile_flow")
"""
run_stage("manual_floorplan")
run_stage("placement")
run_stage("cts")
run_stage("route")
run_stage("signoff")
run_stage("pt")
"""