# *angio_cluster*

This repository includes ai workflow for angiogenesis related disease clustering and network analysis

## *Installation and dependencies:*
N.B. The user must have Ruby, python and R installed.

1: Clone this repository*

        $ git clone git@github.com:ElenaRojano/angio_cluster.git --recurse-submodules

2: Install the workflow manager Autoflow and other required ruby gems throught:

        $ gem install autoflow
	$ gem install report_html

3: Install PETS tool following the instuctions from https://github.com/ElenaRojano/pets.git

4: Install NetAnalyzer tool following the instuctions from https://github.com/ElenaRojano/NetAnalyzer.git

5: Install ExpHunter suite following the instructions from https://github.com/seoanezonjic/ExpHunterSuite.git

6: Install CDlib python library following this tutorial: https://cdlib.readthedocs.io/en/latest/installing.html

7: Add the next folders to PATH variable.

## *Launch*

The workflow can be executed throught executions/launch.sh. This script has different options:

$ ./execution/launch.sh 1 # Download all required files
$ ./execution/launch.sh 1b # Prepare download files for workflow
$ ./execution/launch.sh 2 # Launch main clustering analysis
$ ./execution/launch.sh 2b # Check workflow throught flow_logger
$ ./execution/launch.sh 3 # Create matrices correlation graph
