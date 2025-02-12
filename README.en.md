<p align="center">
<img src="https://raw.githubusercontent.com/y-tetsu/reversi/images/reversi_v0_0_15.png" width="500px">
</p>

# reversi
[ [English](https://github.com/y-tetsu/reversi/blob/master/README.en.md) | [日本語](https://github.com/y-tetsu/reversi/blob/master/README.md)]<br>
<br>
This is a reversi library for Python.<br>
You can feel free to enjoy programming Reversi (Othello) AI.<br>
[![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)
[![Build Status](https://travis-ci.org/y-tetsu/reversi.svg?branch=master)](https://travis-ci.org/y-tetsu/reversi)
[![codecov](https://codecov.io/gh/y-tetsu/reversi/branch/master/graph/badge.svg)](https://codecov.io/gh/y-tetsu/reversi)
<br>

## Download
For Windows OS, you can download the Reversi Application(using tkinter) from the following.<br>
- [reversi.zip](https://github.com/y-tetsu/reversi/releases/download/0.0.18/reversi.zip)

## Requirement
- Windows10 64bit<br>
- Display size 1366x768
- Processor 1.6GHz
- Memory 4.00GB
- [Python 3.7.6](https://www.python.org/downloads/release/python-376/)<br>
    - cython 0.29.15<br>
    - pyinstaller 3.6<br>
- [Microsoft Visual C++ 2019](https://visualstudio.microsoft.com/downloads/?utm_medium=microsoft&utm_source=docs.microsoft.com&utm_campaign=button+cta&utm_content=download+vs2019+rc)(When developing)<br>

## How to Install
1. install [Python 3.7.6](https://www.python.org/downloads/release/python-376/) or higher<br>
2. install **reversi**(run the following)
```
$ py -3.7 -m pip install git+https://github.com/y-tetsu/reversi
```

## How to Uninstall
uninstall **reversi**(run the following)
```
$ py -3.7 -m pip uninstall reversi
```

## Examples
Run the following in any folder to copy the examples.
```
$ install_reversi_examples
```

The examples to be copied are below.

- [01_tkinter_app.py](https://github.com/y-tetsu/reversi/blob/master/reversi/examples/01_tkinter_app.py) - GUI Reversi Application(using tkinter)
- [02_console_app.py](https://github.com/y-tetsu/reversi/blob/master/reversi/examples/02_console_app.py) - Console Reversi Application
- [03_create_exe.bat](https://github.com/y-tetsu/reversi/blob/master/reversi/examples/03_create_exe.bat) - A example for creating portable GUI Reversi Application file
- [04_reversi_simulator.py](https://github.com/y-tetsu/reversi/blob/master/reversi/examples/04_reversi_simulator.py) - A battle simulator that displays the results of playing Reversi AI against each other
- [05_easy_strategy.py](https://github.com/y-tetsu/reversi/blob/master/reversi/examples/05_easy_strategy.py) - A example of Reversi easy AI strategy
- [06_table_strategy.py](https://github.com/y-tetsu/reversi/blob/master/reversi/examples/06_table_strategy.py) - A example of Reversi table AI strategy
- [07_minmax_strategy.py](https://github.com/y-tetsu/reversi/blob/master/reversi/examples/07_minmax_strategy.py) - A example of Reversi minmax  strategy
- [08_alphabeta_strategy.py](https://github.com/y-tetsu/reversi/blob/master/reversi/examples/08_alphabeta_strategy.py) - A example of Reversi alpha beta AI strategy
- [09_genetic_algorithm.py](https://github.com/y-tetsu/reversi/blob/master/reversi/examples/09_genetic_algorithm.py) - A example for discovering the parameters of a reversi strategy using a genetic algorithm
- [10_x_elucidator.py](https://github.com/y-tetsu/reversi/blob/master/reversi/examples/10_x_elucidator.py) - Analysis tool for deformation boards


You can run examples below.
```
$ cd reversi_examples
$ py -3.7 01_tkinter_app.py
$ py -3.7 02_console_app.py
$ 03_create_exe.bat
$ py -3.7 04_reversi_simulator.py
$ py -3.7 05_easy_strategy.py
$ py -3.7 06_table_strategy.py
$ py -3.7 07_minmax_strategy.py
$ py -3.7 08_alphabeta_strategy.py
$ py -3.7 09_genetic_algorithm.py
$ py -3.7 10_x_elucidator.py
```

### Demo
#### 01_tkinter_app.py
[<img src="https://raw.githubusercontent.com/y-tetsu/reversi/images/tkinter_app_demo_v0_0_15.gif" width="650px">](https://github.com/y-tetsu/reversi/blob/master/reversi/examples/01_tkinter_app.py)
#### 02_console_app.py
[<img src="https://raw.githubusercontent.com/y-tetsu/reversi/images/console_app_demo4.gif" width="650px">](https://github.com/y-tetsu/reversi/blob/master/reversi/examples/02_console_app.py)
#### 04_reversi_simulator.py
[<img src="https://raw.githubusercontent.com/y-tetsu/reversi/images/simulator_demo.gif" width="650px">](https://github.com/y-tetsu/reversi/blob/master/reversi/examples/04_reversi_simulator.py)

