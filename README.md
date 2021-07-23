# chia-madmax-plot_loop
Bash script for running the MadMax chia_plot tool with selecting available destination drive.
Added optional Discord notification. Requires jq installed, `sudo apt install jq`.
Make sure you have access to the file: `chmod 755 plot_loop.sh`
Removed `-d ${dest}` from `chia-plotter` variables. Switched to using `rsync` in a cron job, see `move_plot.sh`. The function will still check the destination space, log, and exit if not enough space is found.

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
rmulti2=1
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

**move_plot variables that need set**
SOURCE_DIR=/media/tempdir
DESTINATION_DIR=/media/chia/farm
Discord=true
url="https://discord.com/api/webhooks/yourhook"
###### Section for settings to removing existing sole plots based on time stamp
remove_solo_plots=false
###### Set this to the number of days in the past to collect the list of plots.
###### Example, last solo plot was 16 days ago and now pool plots are generated. The +15 will
###### grab the files dated 15 days from the run time of this move. This list is now set and will
###### not collect again unless the file delete-old-plots.log is renamed or deleted.
days_to_collect_list=+15

**Example of move_plot.sh running on 10 minute interval.**
`*/10 * * * * /home/chia/move_plot.sh >> /home/chia/chialogs/move/move.log 2>&1`

*** TODO: Way to mimick the `-G` swap each run.