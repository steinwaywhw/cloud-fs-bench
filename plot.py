import argparse
import csv
import os
import re

import pandas as pd
import seaborn as sns


def logs():
    files = filter(lambda file: file.endswith(".log"), os.listdir("."))

    # group 1 = name, group 2 = log, group 3 = job index
    pattern = re.compile(r"(.*)_(lat|clat|slat|iops|bw)\.(\d+)\.log")
    dfs = []
    for file in files:
        match = pattern.match(file)
        with open(file) as csvfile:
            df = (
                pd.DataFrame(
                    list(csv.reader(csvfile)),
                    columns=["time", "value", "readwrite", "blocksize", "offset"],
                )
                .astype("int64")
                .drop(columns=["readwrite", "blocksize", "offset"])
            )
            job, rw, blocksize, direct, ioengine, iodepth = match.group(1).split(".")
            df["job"] = job
            df["rw"] = rw
            df["meta"] = ".".join([blocksize, direct, ioengine, iodepth])
            df["log"] = match.group(2)
            df = df.sort_values(by="time")
            df["value"] = df["value"].ewm(span=30).mean()
            dfs.append(df)

    return pd.concat(dfs).sort_values(by="time")


def plot(df):
    latency = sns.relplot(
        kind="line",
        data=df[df["log"].map(lambda v: v.endswith("lat"))],
        x="time",
        y="value",
        hue="job",
        style="rw",
        row="job",
        col="log",
    )
    bandwidth = sns.relplot(
        kind="line",
        data=df[df["log"] == "bw"],
        x="time",
        y="value",
        hue="job",
        style="rw",
        row="job",
    )
    iops = sns.relplot(
        kind="line",
        data=df[df["log"] == "iops"],
        x="time",
        y="value",
        hue="job",
        style="rw",
        row="job",
    )
    return latency, bandwidth, iops


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("prefix", help="output prefix")
    args = parser.parse_args()
    lat, bw, iops = plot(logs())
    lat.savefig(args.prefix + ".lat.png")
    bw.savefig(args.prefix + ".bw.png")
    iops.savefig(args.prefix + ".iops.png")
