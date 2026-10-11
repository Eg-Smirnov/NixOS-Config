{ pkgs, ... }:

let
  intervalSeconds = 10;

  collector = pkgs.writeText "thermal-observer.py" ''
    import csv
    import datetime
    import os
    import pathlib
    import time


    INTERVAL = ${builtins.toString intervalSeconds}
    STATE_DIRECTORY = pathlib.Path("/var/lib/thermal-observer")
    COLUMNS = [
        "timestamp_utc",
        "cpu_util_pct",
        "load_1m",
        "freq_avg_mhz",
        "freq_max_mhz",
        "cpu_temp_c",
        "gpu_temp_c",
        "nvme_temp_c",
        "fan_max_rpm",
        "cpu_power_w",
        "disk_read_mib_s",
        "disk_write_mib_s",
        "top_processes",
    ]


    def read_text(path):
        try:
            return pathlib.Path(path).read_text().strip()
        except (OSError, ValueError):
            return None


    def read_number(path, scale=1.0):
        value = read_text(path)
        try:
            return float(value) / scale
        except (TypeError, ValueError):
            return None


    def cpu_sample():
        fields = read_text("/proc/stat").splitlines()[0].split()[1:]
        counters = [int(value) for value in fields]
        idle = counters[3] + (counters[4] if len(counters) > 4 else 0)
        return sum(counters), idle


    def process_sample():
        result = {}
        for stat_path in pathlib.Path("/proc").glob("[0-9]*/stat"):
            stat = read_text(stat_path)
            if not stat:
                continue
            try:
                name_end = stat.rindex(")")
                name = stat[stat.index("(") + 1:name_end]
                fields = stat[name_end + 2:].split()
                ticks = int(fields[11]) + int(fields[12])
                result[int(stat_path.parent.name)] = (name, ticks)
            except (ValueError, IndexError):
                continue
        return result


    def disk_sample():
        read_sectors = 0
        write_sectors = 0
        for stat_path in pathlib.Path("/sys/block").glob("*/stat"):
            device = stat_path.parent.name
            if device.startswith(("loop", "ram", "zram", "dm-")):
                continue
            fields = (read_text(stat_path) or "").split()
            if len(fields) >= 7:
                read_sectors += int(fields[2])
                write_sectors += int(fields[6])
        return read_sectors, write_sectors


    def energy_sample():
        result = {}
        for energy_path in pathlib.Path("/sys/class/powercap").glob("**/energy_uj"):
            energy = read_number(energy_path)
            if energy is None:
                continue
            maximum = read_number(energy_path.parent / "max_energy_range_uj")
            result[str(energy_path)] = (energy, maximum)
        return result


    def temperatures_and_fans():
        temperatures = {"k10temp": [], "amdgpu": [], "nvme": []}
        fans = []
        for hwmon in pathlib.Path("/sys/class/hwmon").glob("hwmon*"):
            name = read_text(hwmon / "name")
            if name in temperatures:
                for temp_path in hwmon.glob("temp*_input"):
                    value = read_number(temp_path, 1000.0)
                    if value is not None:
                        temperatures[name].append(value)
            for fan_path in hwmon.glob("fan*_input"):
                value = read_number(fan_path)
                if value is not None:
                    fans.append(value)
        maximum = lambda values: max(values) if values else None
        return (
            maximum(temperatures["k10temp"]),
            maximum(temperatures["amdgpu"]),
            maximum(temperatures["nvme"]),
            maximum(fans),
        )


    def frequencies():
        values = []
        for path in pathlib.Path("/sys/devices/system/cpu").glob(
            "cpu[0-9]*/cpufreq/scaling_cur_freq"
        ):
            value = read_number(path, 1000.0)
            if value is not None:
                values.append(value)
        if not values:
            return None, None
        return sum(values) / len(values), max(values)


    def power_watts(before, after, elapsed):
        watts = 0.0
        found = False
        for path, (new_energy, maximum) in after.items():
            if path not in before:
                continue
            old_energy = before[path][0]
            delta = new_energy - old_energy
            if delta < 0 and maximum:
                delta += maximum
            if delta >= 0:
                watts += delta / 1_000_000.0 / elapsed
                found = True
        return watts if found else None


    def rounded(value):
        return "" if value is None else round(value, 2)


    def write_row(row, now):
        path = STATE_DIRECTORY / ("metrics-" + now.strftime("%Y-%m-%d") + ".csv")
        new_file = not path.exists()
        with path.open("a", newline="") as output:
            writer = csv.DictWriter(output, fieldnames=COLUMNS)
            if new_file:
                writer.writeheader()
            writer.writerow(row)


    def main():
        STATE_DIRECTORY.mkdir(parents=True, exist_ok=True)
        cpu_before = cpu_sample()
        processes_before = process_sample()
        disk_before = disk_sample()
        energy_before = energy_sample()
        sampled_at = time.monotonic()

        while True:
            time.sleep(INTERVAL)
            now_monotonic = time.monotonic()
            elapsed = now_monotonic - sampled_at
            cpu_after = cpu_sample()
            processes_after = process_sample()
            disk_after = disk_sample()
            energy_after = energy_sample()

            total_delta = cpu_after[0] - cpu_before[0]
            idle_delta = cpu_after[1] - cpu_before[1]
            cpu_util = (
                100.0 * (total_delta - idle_delta) / total_delta
                if total_delta > 0
                else None
            )

            process_usage = []
            cpu_count = os.cpu_count() or 1
            for pid, (name, new_ticks) in processes_after.items():
                old = processes_before.get(pid)
                if old and total_delta > 0:
                    percent = 100.0 * cpu_count * (new_ticks - old[1]) / total_delta
                    if percent > 0:
                        process_usage.append((percent, name))
            process_usage.sort(reverse=True)
            top_processes = "|".join(
                f"{name}:{percent:.1f}" for percent, name in process_usage[:5]
            )

            cpu_temp, gpu_temp, nvme_temp, fan_rpm = temperatures_and_fans()
            freq_avg, freq_max = frequencies()
            sector_mib = 512.0 / 1024.0 / 1024.0
            now = datetime.datetime.now(datetime.timezone.utc)
            row = {
                "timestamp_utc": now.isoformat(timespec="seconds"),
                "cpu_util_pct": rounded(cpu_util),
                "load_1m": rounded(os.getloadavg()[0]),
                "freq_avg_mhz": rounded(freq_avg),
                "freq_max_mhz": rounded(freq_max),
                "cpu_temp_c": rounded(cpu_temp),
                "gpu_temp_c": rounded(gpu_temp),
                "nvme_temp_c": rounded(nvme_temp),
                "fan_max_rpm": rounded(fan_rpm),
                "cpu_power_w": rounded(power_watts(energy_before, energy_after, elapsed)),
                "disk_read_mib_s": rounded(
                    (disk_after[0] - disk_before[0]) * sector_mib / elapsed
                ),
                "disk_write_mib_s": rounded(
                    (disk_after[1] - disk_before[1]) * sector_mib / elapsed
                ),
                "top_processes": top_processes,
            }
            write_row(row, now)

            cpu_before = cpu_after
            processes_before = processes_after
            disk_before = disk_after
            energy_before = energy_after
            sampled_at = now_monotonic


    if __name__ == "__main__":
        main()
  '';
in
{
  systemd.services.thermal-observer = {
    description = "Collect thermal and workload diagnostics";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.python3}/bin/python3 ${collector}";
      Restart = "on-failure";
      RestartSec = "5s";

      User = "root";
      StateDirectory = "thermal-observer";
      StateDirectoryMode = "0750";
      UMask = "0027";

      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = [ "AF_UNIX" ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/thermal-observer 0750 root root 30d"
  ];
}
