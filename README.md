# chia-madmax-plot_loop
Bash script for running the MadMax chia_plot tool with selecting available destination drive.
Make sure you have access to the file: `chmod 755 plot_loop.sh`

Set all the variables under `# Variables` section. The following are the variables that require setting:
```
threads=4
buckets=256
buckets3=${buckets}
tempdir=/media/plots-02/temp/
tempdir2=/media/plots/temp/
pool=
farm=
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
```
More dest folders can get added. Add dest3=<path>,etc, then add it to the array `final_dest`.

One arg is available to pass into the script. The arg is for how many times you want to run the script.
Example: `./plot_loop.sh 3` will run the script three times consecutively.` The default is 2 consecutive runs.

