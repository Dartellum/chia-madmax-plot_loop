# chia-madmax-plot_loop
Bash script for running the MadMax chia_plot tool with selecting available destination drive.
Added optional Discord notification. Requires jq installed, `sudo apt install jq`.
Make sure you have access to the file: `chmod 755 plot_loop.sh`
Removed `-d ${dest}` from `chia-plotter` variables. Switched to using `mv` in a cron job, see `move_plot.sh`. The function will still check the dest space, log, and exit if none found.

**Set all the variables under `# Variables` section.** The following are the variables that require setting:
```
threads=4
buckets=256
buckets3=${buckets}
tempdir=/media/plots-02/temp/
tempdir2=/media/plots/temp/
pool=
farm=
pool_contract_puzzle_hash=
tmptoggle=false
log=/home/chia/chialogs
dest1=/media/plots-02
dest2=/media/plots-03
declare -a final_dest=(
                       "${dest1}"
                       "${dest2}"
                      )
max=95%
farm_folder=farm/ # disk_space check only works with mount points.
Discord=false
url=(Your web hook here)
```
More dest folders can get added. Add dest3=/mount/point,etc, then add it to the array `final_dest`. As noted, the disk space check with `df` only returns usage with mount points and not  directly to folders. That is why the `farm_folder` variable exists.

One arg is available to pass into the script. The arg is for how many times you want to run the script.
Example: `./plot_loop.sh 3` will run the script three times consecutively. The default is 2 consecutive runs.

~~Example of move_plot.sh running on 10 minute interval.~~
`*/10 * * * * /home/chia/move_plot.sh >> /home/chia/chialogs/move/move.log 2>&1`

*** TODO: Way to mimick the `-G` swap each run.